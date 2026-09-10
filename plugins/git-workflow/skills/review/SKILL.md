---
# ── Portable (agentskills.io spec) — read by Claude Code and GitHub Copilot ──
name: review
description: "Adversarial multi-perspective code review. Spawns independent reviewer agents (correctness, security, maintainability, tests, performance), then puts every finding through a skeptic verification pass before reporting. Usage: /git-workflow:review [--fix] [--model <name>] [target]. Flags come before the target. With no target, reviews the staged changes — or all uncommitted changes if nothing is staged. User-invoked only — never invoke this skill on your own initiative."
compatibility: "Not fully portable — deliberately uses frontmatter extensions beyond the agentskills.io spec. On Claude Code, context: fork runs the whole skill in a forked subagent that orchestrates reviewer/verifier subagents, keeping the review out of the main conversation. VS Code Copilot Chat also honors context: fork (experimental, opt-in via github.copilot.chat.skillTool.enabled), forking into a generic subagent — the agent/background fields are Claude-only and ignored there. Hosts that ignore context: fork entirely (Copilot CLI, Codex) run the same workflow in the main conversation instead — still with parallel reviewers where a subagent tool exists; hosts with no subagent tool fall back to sequential passes. Hosts that ignore disable-model-invocation lose the user-only invocation guarantee."

# ── Non-spec extension, honored by Claude Code and GitHub Copilot (same field
# name in both). Blocks auto-invocation; only /git-workflow:review works. On
# Claude Code this also keeps the description out of the session context
# entirely, so the long strings above cost nothing per session.
disable-model-invocation: true

# ── Non-spec extensions (ignored by the agentskills.io spec) ──
# argument-hint is honored by both Claude Code and Copilot (slash-command hint).
# user-invocable: true is Copilot's default (keeps the slash command available);
# stated explicitly to document intent alongside disable-model-invocation.
user-invocable: true
argument-hint: "[--fix] [--model <name>] [target]"

# ── Fork extensions ──
# context: fork runs this skill's body in a forked subagent — the fork IS the
# review orchestrator, so the whole review (and --fix) stays out of the main
# conversation. Unlike the Agent tool's "fork" subagent type, a skill fork
# starts with a FRESH context: the skill body is its entire prompt and it has
# no access to the conversation history — which is why this file is written
# self-contained. Per-host support for these three fields is documented once,
# in the compatibility string above.
# background: true (the default, stated to document intent) runs the fork as a
# background agent, matching the built-in /code-review: the invocation returns
# immediately, the conversation stays usable while the review runs, and the
# report arrives as a completion notification. Background forks inherit the
# parent's full tool set (Claude Code ≥ 2.1.232), including the Agent tool
# this workflow needs to spawn reviewers; on a host that withholds it, step
# 5's sequential fallback applies. Caveat: a background fork's --fix edits
# bypass session checkpoints (/rewind cannot undo them) — git is the undo path.
context: fork
agent: general-purpose
background: true
---

# Adversarial Code Review

Run a multi-perspective adversarial review of a diff. Several independent reviewers each attack the change from one angle, a skeptic then tries to refute every finding, and only findings that survive refutation reach the report. The point of this structure is signal-to-noise: isolated perspectives find more than one generalist pass, and the refutation stage kills the plausible-but-wrong findings that make reviews annoying to read.

You are the review orchestrator. Depending on the host, you are executing either as a forked subagent (Claude Code, via `context: fork`) or directly in the main conversation (hosts that ignore that field). The workflow is identical either way.

## Invariants

These hold for the whole run; the steps below rely on them rather than restating them.

- **Report only.** Never modify files unless `--fix` was passed — and then only in step 9.
- **Your final message is the entire result.** As a fork, only your final message reaches the user, and it arrives without any surrounding conversation. Whatever ends the run — the report, a "nothing to review" statement, an argument error — must be that final message and must stand on its own.
- **The snapshot is the reviewed state.** Every reviewer and verifier reads the change from `<snapshot>/diff.patch`, never from re-run git commands, and every `file:line` citation derives from `diff.patch`. The live repository is for surrounding context only — it can differ from the snapshot (a partially staged file has other content and line numbers; the user may keep editing during a background review).
- **No unit of work is dropped.** If a spawned subagent fails, hangs, or never returns, perform its unit yourself inline, following the same charter file exactly, and continue. Never stall waiting on it, never leave a finding unverified, and never let a finding into the report by default.

## 1. Parse arguments

Arguments arrive as a single string. Flags come first, target last:

```
/git-workflow:review [--fix] [--model <name>] [target]
```

Parse left to right:

- `--fix` — after composing the report, apply fixes for confirmed findings (see step 9).
- `--model <name>` — model to use for reviewer and verifier subagents (e.g. `haiku`, `sonnet`, `opus`, or a full model ID). Your own orchestration always stays on the model you were started with; this flag only affects subagents you spawn. A `--model` with no value (the next token is missing or is itself a flag) is an argument error, handled like an unrecognized flag below. If the host's subagent tool doesn't accept the given value, note it in the report header and continue with the default model rather than failing.
- Anything after the flags is the **target** — a branch, a commit, or a commit range (step 2 defines each; paths are not supported). Any unrecognized `--flag` — leading or trailing (e.g. `review main --fix` puts the flag after the target) — is an error: stop with a one-line explanation that flags come before the target, rather than silently absorbing the token into the target.

ARGUMENTS: $ARGUMENTS

## 2. Resolve the target and snapshot the diff

Both are done by one script, run from this skill's base directory (resolve the path from wherever this skill was loaded):

```
bash <skill-dir>/scripts/snapshot.sh [--snapshots <dir>] [<target>]
```

If the host designates a session scratchpad directory, pass it as `--snapshots` — the script cannot discover it on its own and otherwise falls back to the system temp directory. The script resolves the target, freezes its diff into a fresh directory that it creates under that root, and prints a short manifest — the snapshot path, the resolved scope, a per-file added/deleted table, and any untracked files it could not capture. It never prints the diff. Its resolution rules, which the report title must reflect exactly:

- **No target**: the staged changes if anything is staged, otherwise all uncommitted changes including untracked files. The scope line says which applied, so a surprising staging state is visible.
- **Branch or tag name**: what HEAD adds relative to it, from the merge base.
- **Commit range** (`A..B` or `A...B`): that range's diff.
- **Single commit** (a SHA, `HEAD`, `HEAD~2`): that commit's own change. A merge commit is diffed against its first parent and a root commit against the empty tree; the scope line says so.
- **Anything else** — a path, or a token git cannot resolve — is rejected.

Act on the exit code:

- `0` — the snapshot is ready; continue with step 3.
- `2` — argument error. Stop, with the script's stderr message as your final message; do not guess at a scope and do not fall back to the no-target behavior.
- `3` — nothing to review (a clean working tree, or an explicit target whose diff is empty, e.g. a branch already merged). Stop with the script's message.

Untracked files in scope are appended to `diff.patch` as new-file hunks, so they have real line numbers in the one authoritative patch, their content is frozen against later edits, and binaries collapse to a one-line "Binary files differ" marker. A file the script could not read is listed under *uncaptured* in the manifest instead — the report header must name every such file as one the review did not cover.

## 3. Map the change

Never read `<snapshot>/diff.patch` yourself. Judging the code is the reviewers' job; a diff loaded here would only ride along in every later turn of this run and pre-form opinions that undermine their independence.

Build a short file map from the manifest's file table: which files changed, roughly how much, and what kind of change each is (logic, config, tests, docs, dependencies, generated code), inferred from paths and extensions. Where step 4 needs to know what the code touches (shell execution, SQL, network calls, I/O in loops), answer with a targeted `grep` over `diff.patch`; peek at a single file's hunk only when its path is genuinely ambiguous. The map drives perspective selection and gives reviewers a starting point.

## 4. Select perspectives

Each perspective has a charter file in this skill's `references/` directory (resolve paths from this skill's base directory). Select using these criteria:

| Perspective | Charter | Runs when |
|---|---|---|
| Correctness | `references/correctness.md` | Always, except pure docs/generated-file diffs (config still counts — a wrong value is a correctness bug). |
| Security | `references/security.md` | The diff touches input handling, auth, network calls, shell/process execution, file paths, serialization, SQL/queries, secrets, or dependency/config changes. |
| Tests | `references/tests.md` | Source logic changed (whether or not tests changed with it), or test files themselves changed. |
| Performance | `references/performance.md` | The diff touches loops or recursion, database/network/file I/O, caching, concurrency, or code on a hot path (per-request, per-item, startup, UI). |
| Maintainability | `references/maintainability.md` | Any non-trivial code change — skip only for pure docs/config/generated-file diffs. |

"Docs" in these criteria means prose no agent executes — a README, a changelog, a comment-only edit. Files that are instructions an agent runs — `SKILL.md`, `CLAUDE.md`, `AGENTS.md`, agent, command, rule, and prompt files — are logic, whatever their extension, and every criterion treats them as such.

Skipping is not silent: the report header lists which perspectives were skipped and why. When in doubt about a criterion, run the perspective — a wasted pass is cheaper than a missed vulnerability. If every perspective is skipped (a diff of nothing but docs or generated files), skip steps 5–7 and produce the header-only report defined in step 8.

## 5. Run the reviewers

**If the host provides a subagent-spawning tool** (Claude Code's Agent/Task tool or equivalent): spawn all selected reviewers in parallel, one subagent per perspective, applying `--model` if given. Each subagent's prompt must contain:

1. The absolute path to its charter file, with the instruction to read it first and adopt that role completely.
2. The resolved target, the file map from step 3, and the snapshot rule from the invariants, spelled out: read the change only from the absolute path of `<snapshot>/diff.patch` — the authoritative state, from which every `file:line` citation must come, since live files can differ. Untracked files in scope already appear in it as new-file hunks, so no other source is needed.
3. That it has read access to the full repository for context, but must not modify anything.
4. That its final message must be only its findings in the charter's output format (or the charter's explicit "no findings" statement) — no preamble, no summary of its process.

**If no subagent mechanism is available**: run each selected charter as its own sequential pass. Complete one perspective fully — read the charter, examine the diff through only that lens, write down its findings — before starting the next. Do not let an earlier pass's findings steer a later pass; each charter deserves a fresh hunt. Note in the report header that the review ran sequentially, and that `--model` (if given) was ignored because there were no subagents to apply it to.

## 6. Deduplicate

Merge findings that share a root cause, even when different perspectives describe it differently (e.g. correctness flags a missing null check and security flags the same line as a crash vector). A merged finding keeps all its perspective tags and the strongest severity claimed. Keep findings **per code site**: two occurrences of the same mistake in different places stay separate findings (each is separately fixable), while a single cross-site pattern finding (e.g. "this anti-pattern appears in both functions") is split into one finding per site — each carrying the full defect, failure scenario, and suggested fix, and merged with any existing finding already at that site. Do not drop findings at this stage for seeming weak — that judgment belongs to the verifier. Reviewers' confidence ratings exist to inform the verifiers; they are dropped from the final report.

## 7. Verify every finding

Every deduplicated finding goes through refutation — no exceptions, including findings that look obviously right. The charter is `references/verifier.md`.

With subagents: group the findings by code site — same file, or within a large file the same function or region — and spawn one verifier per group, in parallel, in waves of at most 8 when groups are numerous, applying `--model` if given. Each verifier gets the charter path, the full text of every finding in its group, and the same snapshot path the reviewers got (`<snapshot>/diff.patch`), and returns one verdict per finding. Grouping only saves re-reading the diff and surrounding code once per finding; the independence that matters — a verifier that did not write the findings re-deriving the truth from the code — is intact, and the charter requires each finding to be judged on its own.

Without subagents: verify sequentially, one finding at a time. Before each one, re-read the relevant code from scratch and actively look for reasons the finding is wrong; you wrote these findings minutes ago, so bias toward refutation to compensate.

Findings verdict `CONFIRMED` go in the report. Findings verdict `REFUTED` go in the rejected appendix with the refutation reason. Apply any severity correction the verifier made.

## 8. Report

Assemble the report using this structure. Without `--fix`, output it as your final message. With `--fix`, hold it, complete step 9 first, and output the report with the fix summary appended as one final message. Just before sending that final message, delete the snapshot directory — exactly the path on the manifest's `snapshot:` line, which the script created for this run (best effort — a failed cleanup is not worth mentioning in the report).

```
# Adversarial review: <target>

Perspectives run: <list>. Skipped: <perspective — reason, or "none">.
<If sequential fallback: note it here, including --model being ignored.>
<If the manifest listed uncaptured untracked files: name each one as not covered by this review.>
<N> findings confirmed, <M> refuted.

## Confirmed findings

### 1. [CRITICAL|MAJOR|MINOR] <short title>
- **Perspective:** <tag(s)>
- **Location:** <file:line>
- **Defect:** <one sentence>
- **Failure scenario:** <concrete inputs/state → wrong outcome>
- **Suggested fix:** <one or two sentences>

<...ordered by severity, critical first>

## Considered and rejected
- <short title> (<perspective>) — <one-line refutation reason>
```

If step 4 skipped every perspective, the report is the title line, the perspectives line, and one sentence stating that no perspective applied so nothing was reviewed — omit the count line, the findings section, and the rejected appendix, which only describe a review that ran.

Where the verifier corrected a severity, append *(severity corrected from X by verifier)* to that finding's title so the adjustment is visible. If every finding was confirmed, the appendix is the single line `- None — all findings survived verification.` If nothing was confirmed, say so plainly and still show the rejected appendix — it is the evidence the review actually looked.

## 9. Fixes — only with `--fix`

Without the flag: the report is the end. Do not apply fixes, do not offer to.

With the flag: apply the suggested fix for each confirmed finding yourself, directly (not via subagents), making the smallest change that resolves the defect. Before each fix, re-read the live file at the finding's site and compare it against the snapshot: if the code there no longer matches, skip that fix and note the divergence in the `## Fixes applied` section rather than patching lines that have moved or changed. Then run whatever cheap sanity check the project offers (build, lint, or the directly relevant tests) and append a `## Fixes applied` section to the report summarizing what was changed and what was verified. When the reviewed scope was the staged changes, the fixes land in the working tree **unstaged** — do not stage them yourself, but say so explicitly in that section, since a commit made from the staged state alone would not include them. When running as a background fork, these edits bypass the host's checkpoint/rewind mechanism — say so in that section and point at git as the way to undo them. If a fix is too risky or ambiguous to apply mechanically, skip it and say why in that section instead of guessing.
