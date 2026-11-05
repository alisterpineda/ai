# ai

Personal marketplace of AI coding-agent customizations — skills, hooks, agents, and MCP config — packaged as plugins.

Built on the [Claude Code plugin format](https://code.claude.com/docs/en/plugins-reference.md), with skills authored to the vendor-neutral [Agent Skills](https://agentskills.io) standard. GitHub Copilot and OpenAI Codex read the Claude marketplace format natively, so the same repo installs into all three tools. Every plugin except `cc` also conforms to [Agent Plugins 1.0](https://agent-plugins.org), so any client that supports the spec can load it straight from its directory.

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

### core

General-purpose skills, not tied to one domain.

| Skill | Invocation | What it does |
|---|---|---|
| `ideate` | model-invoked | Interviews you in rounds until you share an understanding of a plan, design, or decision. It maps the idea as a tree of decisions, asks only questions that no other answer in the round can invalidate, gives each a recommendation with its reason, and looks up facts itself. It ends with a **Shared understanding** block of decisions and open items, and writes no files. |

### git-workflow

Git-related skills.

| Skill | Invocation | What it does |
|---|---|---|
| `commit-message` | model-invoked | Commit staging discipline and message format conventions. |
| `pr-description` | model-invoked | Generates PR titles and descriptions from a branch diff. |
| `review` | **user-only**: `/git-workflow:review [--full] [--model <name>] [--effort <level>] [target]` | Adversarial multi-perspective code review — parallel reviewer subagents (correctness, security, maintainability, tests, performance), sharpened by domain lenses (agent instructions, public API, migrations, frontend, infra/CI), plus a skeptic verification pass on every finding. Small diffs get fewer reviewers, with the remaining perspectives folded in; `--full` lifts that cap. Defaults to uncommitted changes; always report-only — apply fixes from the report in the main conversation. |
| `conflict-triage` | **user-only**: `/git-workflow:conflict-triage [--fix] [target]` | Triages conflicts from a merge, rebase, cherry-pick, revert, or stash pop — or predicts them for a GitHub / Azure DevOps pull request — and reports a per-file resolution plan with its risks. Read-only unless `--fix` is passed. |

### publishing

Document production skills.

| Skill | Invocation | What it does |
|---|---|---|
| `typst` | model-invoked | Writes and iterates on Typst documents with a compile → render → inspect loop. Ships a neutral `base.typ`, conservative design principles, and `render.sh` / `probe.sh` scripts for deterministic verification. Requires the `typst` CLI. |

### swe

Software-engineering workflow skills. Depends on `core`, which Claude Code installs automatically; on Copilot and Codex, install `core` alongside it.

| Skill | Invocation | What it does |
|---|---|---|
| `spec` | **user-only**: `/swe:spec [context]` | Turns the current conversation, starting from `core:ideate`'s Shared understanding block if there is one, into `.scratch/YYYYMMDD-<slug>-spec.md`, or the spec location the repo's `CLAUDE.md` / `AGENTS.md` names. Sections: problem, goals and non-goals, decisions with their reasons, acceptance criteria, open questions, and slices for work bigger than one session. `context` narrows the scope and names the file. Every run writes a new file, and gaps become open questions instead of guesses. |
| `code-review` | **user-only**: `/swe:code-review [--spec <path>] [--slice <n>] [--model <name>] [--effort <level>] [target]` | Reviews a diff in a background subagent along three axes, each run by its own reviewer: correctness (bugs and security basics), standards (the rules in the repo's `CLAUDE.md` / `AGENTS.md` and the files they point to, plus a Fowler code-smell baseline as judgment calls), and spec (an acceptance-criteria table and scope creep, only with `--spec`; `--slice` limits it to one slice's criteria). A skeptic tries to refute every finding before the report, which has one section per axis. Report-only. With no target, reviews the staged changes, or all uncommitted changes if nothing is staged; otherwise a branch, commit, or commit range. |
| `code-review-core` | model-invoked, hidden from the `/` menu | The engine behind `code-review`, for other skills to call with the same arguments. It runs in whatever context invokes it, so each caller chooses its own isolation. |

## Repo structure

See [CLAUDE.md](CLAUDE.md) for the plugin skeleton and authoring conventions.

## License

[MIT](LICENSE)
