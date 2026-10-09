# ai

Personal marketplace of AI coding-agent customizations — skills, hooks, agents, and MCP config — packaged as plugins.

Built on the [Claude Code plugin format](https://code.claude.com/docs/en/plugins-reference.md), with skills authored to the vendor-neutral [Agent Skills](https://agentskills.io) standard. GitHub Copilot and OpenAI Codex read the Claude marketplace format natively, so the same repo installs into all three tools.

## Installing

### Claude Code

```
/plugin marketplace add alisterpineda/ai
/plugin install <plugin>@alisterpineda-ai
```

### GitHub Copilot (CLI / VS Code)

```
copilot plugin marketplace add alisterpineda/ai
copilot plugin install <plugin>@alisterpineda-ai
```

In VS Code, add `alisterpineda/ai` to the `chat.plugins.marketplaces` setting, or use **Chat: Install Plugin From Source** with the repo URL.

### OpenAI Codex

Codex CLI (≥ 0.146.0) supports Claude Code plugin marketplaces — use `/plugins` in the CLI to add this repo as a marketplace and install from it.

## Plugins

### cc

Claude Code-only customizations (no Copilot or Codex equivalent).

| Skill | Invocation | What it does |
|---|---|---|
| `install-statusline` | **user-only**: `/cc:install-statusline` | Installs a status line showing model and effort, context usage, 5h/7d rate-limit usage (green when under pace) with reset countdowns, and the session name. Copies the script into `~/.claude` and points `settings.json` at it, backing up anything it replaces and asking before overwriting a status line or script it didn't install. Re-run after a plugin update to pick up changes. macOS/Linux need `jq`; Windows uses a PowerShell port and needs nothing extra. |

### git-workflow

Git-related skills.

| Skill | Invocation | What it does |
|---|---|---|
| `commit-message` | model-invoked | Commit staging discipline and message format conventions. |
| `pr-description` | model-invoked | Generates PR titles and descriptions from a branch diff. |
| `review` | **user-only**: `/git-workflow:review [--full] [--model <name>] [target]` | Adversarial multi-perspective code review — parallel reviewer subagents (correctness, security, maintainability, tests, performance), sharpened by domain lenses (agent instructions, public API, migrations, frontend, infra/CI), plus a skeptic verification pass on every finding. Small diffs get fewer reviewers, with the remaining perspectives folded in; `--full` lifts that cap. Defaults to uncommitted changes; always report-only — apply fixes from the report in the main conversation. |
| `conflict-triage` | **user-only**: `/git-workflow:conflict-triage [--fix] [target]` | Triages conflicts from a merge, rebase, cherry-pick, revert, or stash pop — or predicts them for a GitHub / Azure DevOps pull request — and reports a per-file resolution plan with its risks. Read-only unless `--fix` is passed. |

### publishing

Document production skills.

| Skill | Invocation | What it does |
|---|---|---|
| `typst` | model-invoked | Writes and iterates on Typst documents with a compile → render → inspect loop. Ships a neutral `base.typ`, conservative design principles, and `render.sh` / `probe.sh` scripts for deterministic verification. Requires the `typst` CLI. |

### swe

Software-engineering workflow skills.

| Skill | Invocation | What it does |
|---|---|---|
| `implement` | **user-only**: `/swe:implement [--delegate] [--model <name>] <target>` | Implements a spec file, GitHub issue, Azure DevOps work item, or in-conversation plan exactly as written — no redesign, no commit. Derives acceptance criteria, builds test-first, then verifies every criterion against the run's diff and reports. `--delegate` cuts the work into sequential phases run by subagents, optionally on a cheaper `--model`; verification always stays with the orchestrator. |

## Repo structure

See [CLAUDE.md](CLAUDE.md) for the plugin skeleton and authoring conventions.

## License

[MIT](LICENSE)
