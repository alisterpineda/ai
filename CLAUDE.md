# AI Customizations Repo

Personal plugin marketplace for AI coding-agent customizations (skills, hooks, agents, MCP config). Primary consumer is Claude Code; the Claude plugin/marketplace format is also read natively by GitHub Copilot (CLI + VS Code) and OpenAI Codex, so this repo serves all three without any sync scripts.

## Repo layout

- `.claude-plugin/marketplace.json` — marketplace manifest (`alisterpineda-ai`). Every plugin must be listed here with `name` + `source` (relative path under `./plugins`).
- `plugins/<plugin-name>/` — one directory per plugin.
- `README.md` — install instructions per tool.
- `scripts/check-manifests.py` — checks every plugin's Agent Plugins 1.0 conformance: the root manifest against the schema its `$schema` names (fetched at run time, so it needs network) and against the Claude manifest, the Copilot layout, and skill frontmatter limits. Its `CLAUDE_ONLY` set lists the plugins exempt from carrying a root manifest. Run with `uv run scripts/check-manifests.py`.

## Plugin skeleton

When creating a new plugin, use this structure. `.claude-plugin/plugin.json` is always required, and portable plugins also require the root `plugin.json`; add the other pieces as needed.

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json          # required: {"name": "<plugin-name>", "version": "0.1.0", "description": "..."}
├── plugin.json              # Agent Plugins 1.0 manifest: "$schema" plus name/version/description/author/license
│                            #   copied from .claude-plugin/plugin.json. Omit only for plugins in the check script's CLAUDE_ONLY.
├── skills/                  # portable layer — read by Claude Code, Copilot, Codex, Cursor
│   └── <skill-name>/
│       ├── SKILL.md         # YAML frontmatter + instructions
│       ├── references/      # docs loaded on demand
│       └── scripts/         # executables the skill invokes
├── hooks/
│   ├── hooks.json           # Claude Code hook wiring
│   └── scripts/             # standalone hook scripts (keep logic here, wiring thin)
├── agents/                  # Claude Code subagents (one .md per agent, YAML frontmatter)
├── commands/                # Claude Code slash commands — prefer skills instead
├── .mcp.json                # MCP servers, Claude Code format (Copilot reads it only for plugins without a root plugin.json)
├── mcp.json                 # MCP servers, Agent Plugins format ($schema + mcpServers, ${PLUGIN_ROOT}); Copilot's copy
│                            #   of .mcp.json for plugins with a root plugin.json
└── com.github.copilot/      # Copilot's agents/, commands/, hooks/hooks.json for plugins with a root plugin.json
```

After adding a plugin, or after changing any manifest: register it in `.claude-plugin/marketplace.json`, then run `claude plugin validate ./plugins/<plugin-name>` and `uv run scripts/check-manifests.py`. Claude's validator ignores the root `plugin.json`, so only the check script catches drift between the two manifests.

## Conventions

- **Claude Code is the source of truth.** Design skills, agents, and hooks for Claude Code first; anything created for another harness (Copilot, Codex) is a derivative of the Claude Code version and must not fork behavior — when they drift, the Claude Code version wins and the derivative is regenerated from it.
- **Skills are the portable unit.** Prefer a skill over a slash command or per-vendor prompt file for anything reusable.
- **Portable skills** stick to the vendor-neutral Agent Skills frontmatter fields (agentskills.io): `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Claude-only extensions (`context: fork`, `model`, `hooks`, dynamic `` !`cmd` `` injection, etc.) are allowed only in skills deliberately marked Claude-only — note it in the skill's `description` or `compatibility`. (One partial exception: VS Code Copilot Chat honors `context: fork` experimentally behind `github.copilot.chat.skillTool.enabled`; Copilot CLI ignores it and loads the skill inline.)
- **Agent Plugins 1.0 (root `plugin.json`).** Every portable plugin carries one. Plugins that are Claude-only by nature leave it out and are listed in the check script's `CLAUDE_ONLY` set, which is the single record of that exemption. The root manifest changes how other tools load the plugin. Claude Code ignores it, but Copilot (CLI and VS Code) prefers it over `.claude-plugin/plugin.json` and switches to Agent Plugins mode. In that mode:
  - Skills still load from `skills/`, with Claude's frontmatter extensions honored. Skills must still meet the Agent Skills limits (name matches its directory, `description` ≤ 1024 characters, `compatibility` ≤ 500), because strict clients skip skills that don't.
  - Agents, commands, and hooks are read only from `com.github.copilot/`. MCP servers come only from `mcp.json`, in the spec's format, which differs from `.mcp.json`.
  - Components declared in `.claude-plugin/plugin.json` (`skills`, `agents`, `commands`, `hooks`, `mcpServers`) are ignored, so portable plugins keep components in their default locations only.
  - `${CLAUDE_PLUGIN_ROOT}` is not expanded. The Copilot copies under `com.github.copilot/` and `mcp.json` use `${PLUGIN_ROOT}` instead.

  So a plugin with a root manifest that adds Claude-layout hooks, agents, commands, or `.mcp.json` needs the Copilot copy too, regenerated from the Claude version with the path variable swapped. The check script fails until the copy exists and is free of `${CLAUDE_PLUGIN_ROOT}`. The marketplace format is unaffected: the spec defines none, and Copilot reads `.claude-plugin/marketplace.json`.
- **Hooks are not portable.** Claude Code, Copilot, and Codex each have different hook config formats and event sets. Keep hook logic in standalone scripts under `hooks/scripts/` so the per-vendor wiring stays a thin wrapper. Use `${CLAUDE_PLUGIN_ROOT}` for paths in the Claude-layout `hooks/hooks.json`, and `${PLUGIN_ROOT}` in Copilot's `com.github.copilot/hooks/hooks.json`.
- **Version discipline:** bump `version` in `.claude-plugin/plugin.json` (and in the root `plugin.json`, if the plugin has one) in any commit that changes files under `plugins/<name>/` — all consumers (Claude Code, Copilot, Codex) cache installed plugins and only refetch when the version string changes. Changes outside plugin directories (README, CLAUDE.md, marketplace.json) never need a bump. One bump per commit; a commit touching two plugins bumps each.
  - **Major:** a consumer-visible break — removing or renaming a skill/command/agent (renames change the `<plugin>:<skill>` namespace), removing a hook, or restructuring how the plugin is invoked. Removing or renaming a single skill's flag or argument is not a restructure — it's minor, provided the skill's argument error names the flags it supports (add that wording in the same change if the error lacks it): the `<plugin>:<skill>` name still resolves, and the error tells the user what remains.
  - **Minor:** additions and behavior changes — a new skill/agent/hook, a new workflow step, or any edit that changes what a skill does or when it triggers (`description` edits that alter triggering are minor; triggering is the skill's interface).
  - **Patch:** no observable behavior change — typo/wording fixes, script bugfixes, formatting, tightening instructions without changing the outcome.
  - Minor-vs-patch tiebreaker for prose edits: if you'd want the change to stand out in version history when debugging why a skill started acting differently, it's minor.
  - Plugins stay pre-1.0 but follow the same semantics (no "0.x means anything goes"); cut 1.0 when a plugin is stable enough that a rename would be annoying.
- **Naming:** kebab-case for plugin and skill names. Skill names become namespaced as `<plugin-name>:<skill-name>` in Claude Code.
