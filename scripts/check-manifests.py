# /// script
# requires-python = ">=3.9"
# dependencies = ["jsonschema>=4.18,<5", "pyyaml>=6,<7"]
#
# [tool.uv]
# exclude-newer = "2026-10-01T00:00:00Z"
# ///
"""Check every marketplace plugin's Agent Plugins 1.0 conformance.

Every plugin listed in .claude-plugin/marketplace.json must have a root
plugin.json unless it is in CLAUDE_ONLY. For each plugin that has one, verify
that:
  1. it validates against the schema its own "$schema" names (fetched from
     agent-plugins.org, so the manifest is the only place the version lives),
  2. it matches .claude-plugin/plugin.json on the shared fields,
  3. .claude-plugin/plugin.json declares no components (hooks, agents, ...),
     since Agent Plugins mode reads only fixed locations,
  4. no Claude-layout component lacks the copy that Copilot/VS Code read once
     the root manifest switches them to Agent Plugins mode, and no file in
     those copies uses ${CLAUDE_PLUGIN_ROOT}, which that mode does not expand,
  5. every skills/*/SKILL.md meets the Agent Skills name, description, and
     compatibility limits. Claude's extra frontmatter fields are allowed.

Separately, for every plugin (CLAUDE_ONLY included), each same-marketplace
entry in .claude-plugin/plugin.json "dependencies" must name a plugin listed in
marketplace.json; Claude's validator accepts a misspelled one.

Needs network access. Run from anywhere: uv run scripts/check-manifests.py
"""

import json
import re
import sys
import urllib.request
from functools import cache
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator

REPO = Path(__file__).resolve().parent.parent
SCHEMA_PREFIX = "https://agent-plugins.org/schemas/"
SHARED_FIELDS = ("name", "version", "description", "author", "license")

# Plugins that are Claude Code-only by nature and carry no root plugin.json.
CLAUDE_ONLY = {"cc"}

# Claude manifest fields that declare components; Agent Plugins mode ignores them.
CLAUDE_COMPONENT_FIELDS = ("skills", "agents", "commands", "hooks", "mcpServers")

# Claude-layout path -> where Agent Plugins mode reads the same component.
SPEC_MODE_LOCATIONS = {
    "hooks/hooks.json": "com.github.copilot/hooks/hooks.json",
    "agents": "com.github.copilot/agents",
    "commands": "com.github.copilot/commands",
    ".mcp.json": "mcp.json",
}

# Agent Skills (agentskills.io) frontmatter limits.
SKILL_NAME = re.compile(r"^(?!.*--)[a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?$")
MAX_DESCRIPTION = 1024
MAX_COMPATIBILITY = 500


@cache
def validator_for(schema_url: str) -> Draft202012Validator:
    with urllib.request.urlopen(schema_url, timeout=15) as response:
        return Draft202012Validator(json.load(response))


def check_schema(spec: dict) -> list[str]:
    schema_url = spec.get("$schema")
    if not (isinstance(schema_url, str) and schema_url.startswith(SCHEMA_PREFIX)):
        return [f'plugin.json "$schema" must be an {SCHEMA_PREFIX} URL, got {json.dumps(schema_url)}']
    try:
        validator = validator_for(schema_url)
    except Exception as error:  # network failure, 404, bad JSON
        return [f"could not fetch {schema_url}: {error}"]
    return [
        f"plugin.json {'/'.join(str(p) for p in error.path) or '(root)'}: {error.message}"
        for error in sorted(validator.iter_errors(spec), key=lambda e: list(e.path))
    ]


def check_claude_manifest(spec: dict, claude: dict) -> list[str]:
    problems = []
    for field in SHARED_FIELDS:
        if spec.get(field) != claude.get(field):
            problems.append(
                f"{field} differs: plugin.json {json.dumps(spec.get(field))}, "
                f".claude-plugin/plugin.json {json.dumps(claude.get(field))}"
            )
    for field in CLAUDE_COMPONENT_FIELDS:
        if field in claude:
            problems.append(
                f'.claude-plugin/plugin.json declares "{field}"; Agent Plugins mode ignores it. '
                f"Use the default location instead"
            )
    return problems


def check_spec_mode_layout(root: Path) -> list[str]:
    problems = []
    for claude_layout, spec_layout in SPEC_MODE_LOCATIONS.items():
        if (root / claude_layout).exists() and not (root / spec_layout).exists():
            problems.append(
                f"{claude_layout} exists but Copilot/VS Code in Agent Plugins mode "
                f"read {spec_layout} instead"
            )
    spec_files = [root / "mcp.json", *(root / "com.github.copilot").rglob("*")]
    for path in spec_files:
        if path.is_file() and "${CLAUDE_PLUGIN_ROOT}" in path.read_text(errors="replace"):
            problems.append(
                f"{path.relative_to(root)} uses ${{CLAUDE_PLUGIN_ROOT}}, which Agent Plugins "
                f"mode does not expand; use ${{PLUGIN_ROOT}}"
            )
    return problems


def check_skills(root: Path) -> list[str]:
    problems = []
    for skill_md in sorted((root / "skills").glob("*/SKILL.md")):
        where = skill_md.relative_to(root)
        parts = skill_md.read_text().split("---", 2)
        try:
            frontmatter = yaml.safe_load(parts[1]) if len(parts) == 3 and not parts[0].strip() else None
        except yaml.YAMLError as error:
            problems.append(f"{where}: frontmatter is not valid YAML: {' '.join(str(error).split())}")
            continue
        if not isinstance(frontmatter, dict):
            problems.append(f"{where}: missing YAML frontmatter")
            continue
        name = frontmatter.get("name")
        if not (isinstance(name, str) and SKILL_NAME.match(name)):
            problems.append(f"{where}: name {json.dumps(name)} is not a valid Agent Skills name")
        elif name != skill_md.parent.name:
            problems.append(f"{where}: name {json.dumps(name)} does not match its directory")
        description = frontmatter.get("description")
        if not (isinstance(description, str) and 0 < len(description.strip()) <= MAX_DESCRIPTION):
            length = len(description) if isinstance(description, str) else "no"
            problems.append(f"{where}: description must be 1-{MAX_DESCRIPTION} characters, has {length}")
        compatibility = frontmatter.get("compatibility")
        if compatibility is not None and not (
            isinstance(compatibility, str) and len(compatibility) <= MAX_COMPATIBILITY
        ):
            length = len(compatibility) if isinstance(compatibility, str) else "a non-string"
            problems.append(f"{where}: compatibility must be at most {MAX_COMPATIBILITY} characters, has {length}")
    return problems


def check_dependencies(root: Path, listed: set[str], marketplace: str) -> list[str]:
    claude_path = root / ".claude-plugin/plugin.json"
    if not claude_path.exists():
        return []
    problems = []
    for dependency in json.loads(claude_path.read_text()).get("dependencies", []):
        # Entries are "name", "name@marketplace", or {"name", "version", "marketplace"}.
        if isinstance(dependency, dict):
            name, source = dependency.get("name"), dependency.get("marketplace", marketplace)
        else:
            name, _, source = str(dependency).partition("@")
            source = source or marketplace
        if source == marketplace and name not in listed:
            problems.append(
                f'.claude-plugin/plugin.json depends on "{name}", which marketplace.json does not list'
            )
    return problems


def check_plugin(root: Path) -> list[str]:
    spec = json.loads((root / "plugin.json").read_text())
    claude_path = root / ".claude-plugin/plugin.json"
    problems = check_schema(spec)
    if claude_path.exists():
        problems += check_claude_manifest(spec, json.loads(claude_path.read_text()))
    else:
        problems.append(".claude-plugin/plugin.json is missing")
    return problems + check_spec_mode_layout(root) + check_skills(root)


def main() -> int:
    marketplace = json.loads((REPO / ".claude-plugin/marketplace.json").read_text())
    listed = {entry["name"] for entry in marketplace["plugins"]}
    failed = False
    for entry in marketplace["plugins"]:
        name, root = entry["name"], (REPO / entry["source"]).resolve()
        has_root_manifest = (root / "plugin.json").exists()
        dependency_problems = check_dependencies(root, listed, marketplace["name"])
        if name in CLAUDE_ONLY:
            for problem in dependency_problems:
                failed = True
                print(f"✘ {name}: {problem}")
            if has_root_manifest:
                failed = True
                print(f"✘ {name}: listed in CLAUDE_ONLY but has a root plugin.json")
            elif not dependency_problems:
                print(f"– {name}: Claude-only (no root plugin.json)")
            continue
        if not has_root_manifest:
            failed = True
            print(f"✘ {name}: no root plugin.json; add one, or list the plugin in CLAUDE_ONLY")
            continue
        problems = dependency_problems + check_plugin(root)
        if problems:
            failed = True
            for problem in problems:
                print(f"✘ {name}: {problem}")
        else:
            print(f"✔ {name}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
