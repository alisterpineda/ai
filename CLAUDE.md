# AI Customizations Repo

Personal plugin marketplace for AI coding-agent customizations (skills, hooks, agents, MCP config). Primary consumer is Claude Code; the Claude plugin/marketplace format is also read natively by GitHub Copilot (CLI + VS Code) and OpenAI Codex, so this repo serves all three without any sync scripts.

## Repo layout

- `.claude-plugin/marketplace.json` — marketplace manifest (`alisterpineda-ai`). Every plugin must be listed here with `name` + `source` (relative path under `./plugins`).
- `plugins/<plugin-name>/` — one directory per plugin.
- `README.md` — install instructions per tool.
- `scripts/check-manifests.py` — checks every plugin's Agent Plugins 1.0 conformance: the root manifest against the schema its `$schema` names (fetched at run time, so it needs network) and against the Claude manifest, the Copilot layout, and skill frontmatter limits. It also fails any `.claude-plugin/plugin.json` `dependencies` entry that names a plugin missing from this marketplace, and any `skills/*/references/<name>` file whose copies in a plugin's other skills differ. Its `CLAUDE_ONLY` set lists the plugins exempt from carrying a root manifest. Run with `uv run scripts/check-manifests.py`.

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
├── evals/<skill-name>/      # `claude plugin eval` suite per skill, one directory per case, plus a README
├── .mcp.json                # MCP servers, Claude Code format (Copilot reads it only for plugins without a root plugin.json)
├── mcp.json                 # MCP servers, Agent Plugins format ($schema + mcpServers, ${PLUGIN_ROOT}); Copilot's copy
│                            #   of .mcp.json for plugins with a root plugin.json
└── com.github.copilot/      # Copilot's agents/, commands/, hooks/hooks.json for plugins with a root plugin.json
```

After adding a plugin, or after changing any manifest: register it in `.claude-plugin/marketplace.json`, then run `claude plugin validate ./plugins/<plugin-name>` and `uv run scripts/check-manifests.py`. Claude's validator ignores the root `plugin.json`, so only the check script catches drift between the two manifests.

## Conventions

- **Claude Code is the source of truth.** Design skills, agents, and hooks for Claude Code first; anything created for another harness (Copilot, Codex) is a derivative of the Claude Code version and must not fork behavior — when they drift, the Claude Code version wins and the derivative is regenerated from it.
- **Skills are the portable unit.** Prefer a skill over a slash command or per-vendor prompt file for anything reusable.
- **Skills are self-contained.** A skill reads no file outside its own directory: the Agent Skills spec defines only a skill's own directory, and hosts that install a skill on its own leave a `../` path dangling. Content several skills need is copied into each one's `references/` under the same name, or inlined where each skill words it differently; the check script fails when same-named copies differ. A skill may call another skill by name, with a fallback when the host can't reach it. Revisit this when the Agent Skills spec defines content shared between skills.
- **Read any input, write a consistent output.** A skill takes its input in whatever shape it comes (a spec, ticket, or report written by any tool or person) and normalizes it itself; another skill's output format is the easy case, not a requirement. Documents written for a team (commit messages, PR descriptions, specs) take their format from the user's request, then the repo's instructions and templates, then the user's standing instructions, then a clear pattern in recent history, and only then the skill's default.
- **Portable skills** stick to the vendor-neutral Agent Skills frontmatter fields (agentskills.io): `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Claude-only extensions (`context: fork`, `model`, `hooks`, dynamic `` !`cmd` `` injection, etc.) are allowed only in skills deliberately marked Claude-only — note it in the skill's `description` or `compatibility`. (One partial exception: VS Code Copilot Chat honors `context: fork` experimentally behind `github.copilot.chat.skillTool.enabled`; Copilot CLI ignores it and loads the skill inline.)
- **Agent Plugins 1.0 (root `plugin.json`).** Every portable plugin carries one. Plugins that are Claude-only by nature leave it out and are listed in the check script's `CLAUDE_ONLY` set, which is the single record of that exemption. The root manifest changes how other tools load the plugin. Claude Code ignores it, but Copilot (CLI and VS Code) prefers it over `.claude-plugin/plugin.json` and switches to Agent Plugins mode. In that mode:
  - Skills still load from `skills/`, with Claude's frontmatter extensions honored. Skills must still meet the Agent Skills limits (name matches its directory, `description` ≤ 1024 characters, `compatibility` ≤ 500), because strict clients skip skills that don't.
  - Agents, commands, and hooks are read only from `com.github.copilot/`. MCP servers come only from `mcp.json`, in the spec's format, which differs from `.mcp.json`.
  - Components declared in `.claude-plugin/plugin.json` (`skills`, `agents`, `commands`, `hooks`, `mcpServers`) are ignored, so portable plugins keep components in their default locations only.
  - `${CLAUDE_PLUGIN_ROOT}` is not expanded. The Copilot copies under `com.github.copilot/` and `mcp.json` use `${PLUGIN_ROOT}` instead.

  So a plugin with a root manifest that adds Claude-layout hooks, agents, commands, or `.mcp.json` needs the Copilot copy too, regenerated from the Claude version with the path variable swapped. The check script fails until the copy exists and is free of `${CLAUDE_PLUGIN_ROOT}`. The marketplace format is unaffected: the spec defines none, and Copilot reads `.claude-plugin/marketplace.json`.
- **Hooks are not portable.** Claude Code, Copilot, and Codex each have different hook config formats and event sets. Keep hook logic in standalone scripts under `hooks/scripts/` so the per-vendor wiring stays a thin wrapper. Use `${CLAUDE_PLUGIN_ROOT}` for paths in the Claude-layout `hooks/hooks.json`, and `${PLUGIN_ROOT}` in Copilot's `com.github.copilot/hooks/hooks.json`.
- **Version discipline:** bump `version` in `.claude-plugin/plugin.json` (and in the root `plugin.json`, if the plugin has one) once per branch that changes files under `plugins/<name>/`, measured against `main` — all consumers (Claude Code, Copilot, Codex) install from `main`, cache installed plugins, and only refetch when the version string changes. The first such change on a branch raises the version one step over `main`; later commits on the same unmerged branch leave it alone, unless a later change needs a bigger step (patch → minor → major), which replaces the earlier bump rather than adding to it. Changes outside plugin directories (README, CLAUDE.md, marketplace.json) never need a bump. A branch touching two plugins bumps each once.
  - **Major:** a consumer-visible break — removing or renaming a skill/command/agent (renames change the `<plugin>:<skill>` namespace), removing a hook, or restructuring how the plugin is invoked. Removing or renaming a single skill's flag or argument is not a restructure — it's minor, provided the skill's argument error names the flags it supports (add that wording in the same change if the error lacks it): the `<plugin>:<skill>` name still resolves, and the error tells the user what remains.
  - **Minor:** additions and behavior changes — a new skill/agent/hook, a new workflow step, or any edit that changes what a skill does or when it triggers (`description` edits that alter triggering are minor; triggering is the skill's interface).
  - **Patch:** no observable behavior change — typo/wording fixes, script bugfixes, formatting, tightening instructions without changing the outcome.
  - Minor-vs-patch tiebreaker for prose edits: if you'd want the change to stand out in version history when debugging why a skill started acting differently, it's minor.
  - Plugins stay pre-1.0 but follow the same semantics (no "0.x means anything goes"); cut 1.0 when a plugin is stable enough that a rename would be annoying.
- **Evals:** each skill's `claude plugin eval` suite lives in `plugins/<plugin>/evals/<skill-name>/`: one flat directory per case, grouped by tags and a name prefix (`trigger-*`, `args-*`) rather than subdirectories. The suite's README holds only what is specific to it: the tags and what each case checks, the run command with its tool grants, and the suite's own costs and caveats. Everything below applies to every suite.
  - **Case format.** Write a case as `prompt.md` (frontmatter plus the prompt as its body). Use `case.yaml` only when the case needs `context:` (`scaffold_script`, `history_file`), which `prompt.md` frontmatter rejects.
  - **Scope.** Cases cost money and are noisy, so keep them for behavior that needs a model. Test anything deterministic (a script's argument parsing, error messages, git plumbing) with a plain test script next to the script it tests. Give each case a grader for each thing it exists to check, not copies of checks other cases already make.
  - **Fixtures.** A `scaffold_script` runs from its own path in the case directory, with the run's empty workspace as its working directory. Cases that need the same repository share one fixture (a base script sourced with `source "$(dirname "$0")/../<base>.sh"`, or a call to the other case's `fixture.sh`) instead of copying it.
  - **Models.** Run with `--model opus --judge-model opus`; Opus is the model in use, and pinning it keeps results comparable. Swap in `--model fable` for an occasional check. A case that passes a model through a flag names `opus`. The default haiku judge fails reports that meet their rubric.
  - **Where to run.** Run from `plugins/`, pointing `--eval-dir` at the suite: the harness loads only plugins inside the directory it is pointed at, so a plugin that depends on another (swe needs `core`) fails when run from its own directory. Cases run once by default; pass `--runs 3` before trusting a change to a skill.
  - **Graders.** An `llm` grader with `focus: trace` sees only the head and tail of a long trace, so grade what happens in the middle with `regex` or `tool_used`. Graders can't run commands. Grade a file's final contents, whether the run created or only edited it, with a `regex` `target` or `llm` `focus` of `{ source: file, path: <path> }`, which holds whether the run used `Write` or `Edit`; grade how the run got there through the inputs of `Write`, `Edit`, and `Bash` calls. `file_exists` can check that a run didn't create a file, but not that a fixture's file survived. A `regex` grader checks text a script prints or a line a template fixes, never wording the skill leaves to the agent.
  - **Sandbox.** Don't run the harness as root: its sandbox then makes `$TMPDIR` read-only, and every `Bash` call fails. On Linux it needs `bubblewrap` and `socat` to grant `Bash`.
- **Naming:** kebab-case for plugin and skill names. Skill names become namespaced as `<plugin-name>:<skill-name>` in Claude Code.
