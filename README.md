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
| `writing-for-ai` | model-invoked | Rules for writing agent instructions (skills, subagent charters and prompts, `CLAUDE.md`/`AGENTS.md`, slash commands) that an agent follows the same way every run, at the lowest load: what goes in the main file and what in a reference, checkable step conditions, wording that states the wanted behavior, where text loads and for how long, descriptions and invocation choice across hosts, where maintainer notes go, and, when editing, keeping scoping conditions and matched strings exactly. Fires when you create, restructure, tighten, or review one. |

### git-workflow (deprecated)

Git-related skills. **Deprecated:** superseded by `swe`. The skills still work but get no further updates; each row names its successor.

On Copilot, uninstall `git-workflow` once `swe` is installed: Copilot keeps only the first skill it finds with a given name, so with both plugins it may load the frozen `commit-message` instead of `swe`'s.

| Skill | Invocation | What it does |
|---|---|---|
| `commit-message` | model-invoked | Commit staging discipline and message format conventions. Successor: `swe:commit-message`. |
| `pr-description` | model-invoked | Generates PR titles and descriptions from a branch diff. Successor: `swe:pr-writeup`. |
| `review` | **user-only**: `/git-workflow:review [--full] [--model <name>] [--effort <level>] [target]` | Adversarial multi-perspective code review — parallel reviewer subagents (correctness, security, maintainability, tests, performance), sharpened by domain lenses (agent instructions, public API, migrations, frontend, infra/CI), plus a skeptic verification pass on every finding. Small diffs get fewer reviewers, with the remaining perspectives folded in; `--full` lifts that cap. Defaults to uncommitted changes; always report-only — apply fixes from the report in the main conversation. Successor: `/swe:code-review`, which doesn't yet cover the separate security, performance, and tests passes or the domain lenses. |
| `conflict-triage` | **user-only**: `/git-workflow:conflict-triage [--fix] [target]` | Triages conflicts from a merge, rebase, cherry-pick, revert, or stash pop — or predicts them for a GitHub / Azure DevOps pull request — and reports a per-file resolution plan with its risks. Read-only unless `--fix` is passed. No successor. |

### publishing

Document production skills.

| Skill | Invocation | What it does |
|---|---|---|
| `typst` | model-invoked | Writes and iterates on Typst documents with a compile → render → inspect loop. Ships a neutral `base.typ`, conservative design principles, and `render.sh` / `probe.sh` scripts for deterministic verification. Requires the `typst` CLI. |

### swe

Software-engineering workflow skills. Depends on `core`, which Claude Code installs automatically; on Copilot and Codex, install `core` alongside it.

| Skill | Invocation | What it does |
|---|---|---|
| `spec` | **user-only**: `/swe:spec [context]` | Turns the current conversation, starting from `core:ideate`'s Shared understanding block if there is one, into `.scratch/YYYYMMDD-<slug>-spec.md` (`.local/` instead when the repo has that directory, already gitignores it, and has no `.scratch/`), or the spec location the repo's `CLAUDE.md` / `AGENTS.md` names. Sections: source, problem, goals and non-goals, decisions with their reasons, an optional design section, acceptance criteria, and open questions; a spec template the repo has, or a structure its earlier specs share, replaces these. `context` narrows the scope and names the file. Every run writes a new file, and gaps become open questions instead of guesses. `plan` writes to the same location. |
| `plan` | **user-only**: `/swe:plan [target …] [context]` | Works out how to build a spec file, GitHub issues, Azure DevOps work items, or (with no target) what the conversation agreed (a Shared understanding block, an Agreed fix from `diagnose`, or the discussion), and writes it to `.scratch/YYYYMMDD-<slug>-plan.md`, or wherever `spec` would put it. It reads the code first, and changes none. The spec can be in any format. The plan holds the goal, the acceptance criteria (a spec's numbered ones copied word for word; otherwise derived from its requirements and shown to you before drafting), decisions, cautious readings, the project's checks, slices only for work bigger than one session, and numbered steps that each name their criteria, the files and symbols they change, the test to write first and the seam it goes through, and the check that shows the step is done. Text after the targets narrows the scope, such as `criteria 7 to 9`. It asks only about choices a user would notice: once before drafting, and again only when a review finding needs your choice; held-back text from outsiders' tickets waits for your yes. A fresh subagent then reviews the plan for coverage, real files and symbols, step order, reachable test seams, and real commands, up to 3 rounds. The report ends with the `/swe:implement` command that builds it. |
| `implement` | **user-only**: `/swe:implement [--worker-model <name>] [target …] [context]` | Builds decided work with the session's model as orchestrator. The source is a plan, a spec in any format, GitHub issues, Azure DevOps work items, or (with no target) what the conversation agreed; text after the targets narrows it, such as `slice 2`. A plan's unfinished steps are the units as written; for anything else it lists a short breakdown in the conversation and writes no plan file. Units run one at a time: each well-specified one goes to a worker subagent on a cheaper model (`opus` unless `--worker-model` names another), and the session builds the tiny and the judgment-heavy ones itself. It checks every unit itself by running the unit's check and the project's checks and reading the changes; a worker that fails gets one re-brief, then the session takes the unit over. A plan step's test-first is followed; otherwise tests go where the repo already tests that area. It asks only about contradictions, choices a user would notice, and held-back text from outsiders' tickets, once before building. It marks each passed plan step `Done:`, never touches git state, and ends with a per-unit report and, when the source is a file, the `/swe:code-review` command. On hosts without a subagent tool that takes a model, the session builds everything. |
| `diagnose` | **user-only**: `/swe:diagnose [target …] [context]` | Investigates one or more bugs down to their root cause and fixes nothing. Targets are GitHub issues, Azure DevOps work items, a spec whose code misbehaves, or a bug-report file, told apart by what the file says; free text or the conversation also work, and context after the targets applies to all of them. It reproduces where it can, may add temporary instrumentation to files without uncommitted changes and removes it again, reads history for regressions, and bisects only with your yes, in a temporary worktree. It quotes outsiders' repro commands and runs them only with your yes. The report groups the items by root cause, labels each cause confirmed, likely, or hypothesis, and adds scope, a workaround, fix options, and, for ticket targets, a summary to paste into the ticket; it never writes to a tracker. It then offers a hand-off: an `## Agreed fix` block of the fix's decisions and acceptance criteria, for `/swe:plan` to pick up from the conversation; the fix's criteria and a decision added to the target spec in its own structure, with the `/swe:plan` command that plans just those criteria; or stop. |
| `code-review` | **user-only**: `/swe:code-review [--spec <spec, plan, or ticket URL>] [--slice <n>] [--model <name>] [--effort <level>] [target]` | Reviews a diff in a background subagent along three axes, each run by its own reviewer: correctness (bugs and security basics), standards (the rules in the repo's `CLAUDE.md` / `AGENTS.md` and the files they point to, plus a Fowler code-smell baseline as judgment calls), and spec (an acceptance-criteria table and scope creep, only with `--spec`, which takes a spec or plan file in any format, or a GitHub issue or Azure DevOps work-item URL; `--slice` limits it to one slice, phase, or milestone's criteria, however the spec writes them). A skeptic tries to refute every finding before the report, which has one section per axis. Report-only. With no target, reviews the staged changes, or all uncommitted changes if nothing is staged; otherwise a branch, commit, or commit range. |
| `fetch-tickets` | model-invoked, hidden from the `/` menu | The ticket reader behind `plan`, `implement`, `diagnose`, and `code-review`: fetches GitHub issues and Azure DevOps work items read-only, marks each author on the project or an outsider, and flags outsiders' text as held back. |
| `commit-message` | model-invoked | Commit staging discipline and message format conventions. The format follows your request, then the repo's conventions and commit template, then your standing instructions, then a pattern its recent commits share, before the skill's own rules. |
| `pr-writeup` | model-invoked | Writes a PR title and description from a branch's net change, in the repo's pull-request template or the format its recent PRs share when it has one, and prints them for pasting; it doesn't open the PR. |

## Repo structure

See [CLAUDE.md](CLAUDE.md) for the plugin skeleton and authoring conventions.

## License

[MIT](LICENSE)
