---
# ── Portable (agentskills.io spec) — read by Claude Code and GitHub Copilot ──
name: implement
description: "Implement a spec or ticket exactly as written, with no redesign and no commit: derive acceptance criteria, build test-first, then verify every criterion against the diff and report. Optionally splits the work into sequential phases delegated to subagents on a cheaper model. Usage: /swe:implement [--delegate] [--model <name>] <target> — target is a spec file or directory, a GitHub issue, an Azure DevOps work item, or 'conversation' for a plan agreed in this session. User-invoked only — never invoke this skill on your own initiative."
compatibility: "Claude-first. --delegate needs a host with a subagent-spawning tool that accepts a model choice (Claude Code's Agent tool); hosts without one run the whole implementation in the main context and ignore --model. GitHub fetching uses the gh CLI; Azure DevOps fetching uses whatever work-item tool the host exposes (MCP or az boards), or falls back to asking for a paste. The snapshot script is Bash and needs git. Hosts that ignore disable-model-invocation lose the user-only invocation guarantee."

# ── Non-spec extension, honored by Claude Code and GitHub Copilot ──
# Blocks auto-invocation; only /swe:implement works. Also keeps the long
# description above out of the session context on Claude Code.
disable-model-invocation: true

# ── Non-spec extensions (ignored by the agentskills.io spec) ──
user-invocable: true
argument-hint: "[--delegate] [--model <name>] <target>"
---

# Implement

Build work that has already been decided. The target — a spec, a ticket, or a plan agreed in this conversation — is the whole input; the output is a working tree that satisfies it, plus a report proving that criterion by criterion. Nothing is committed, staged, or pushed: review and commit are the user's next step.

You are the orchestrator. You run inline in the main conversation; the user can see and interrupt you. With `--delegate` you dispatch each phase to an implementer subagent and verify their work; without it you implement directly.

Paths below are relative to this skill's directory; resolve them from wherever the skill was loaded.

## Invariants

- **The plan is closed.** Take the spec as written. When it is ambiguous, choose the most conservative reading, build that, and flag the choice in the report. When it contradicts itself, halt before writing code and report the contradiction as your final message. Design questions to the user never happen. **Scope questions** — what is in this session — are allowed once, in step 5, before any code exists.
- **No git state changes.** Never stage, commit, stash, switch branches, or create worktrees. Never write to GitHub or Azure DevOps. The working tree is the only thing you change.
- **Criteria drive everything.** The numbered acceptance-criteria list from step 5 is what phases are cut from, what tests are written against, and what the final verification walks. A criterion that never got written down never gets verified.
- **No unit of work is dropped.** If a subagent fails, hangs, or returns nothing, the retry rules in step 6 apply; work never silently disappears from the run.

## 1. Parse arguments

Arguments arrive as a single string. Flags come first, target last:

```
/swe:implement [--delegate] [--model <name>] <target>
```

- `--delegate` — cut the work into phases and dispatch each to an implementer subagent (step 6b). Without it, you implement everything yourself (step 6a).
- `--model <name>` — model for implementer subagents (`haiku`, `sonnet`, `opus`, or a full model ID). Your own model never changes. Requires `--delegate`; without it, stop with a one-line message that `--model` only applies to delegated phases. A `--model` with no value is the same error. If the host's subagent tool rejects the value, note that in the report header and continue with the default model.
- Everything after the flags is the **target**. An unrecognized `--flag` anywhere is an error: stop with a one-line explanation that flags come before the target.

ARGUMENTS: $ARGUMENTS

## 2. Choose a scratch directory

Scratch holds the criteria list, the phase plan, the snapshot, and subagent reports. It must be readable by subagents (absolute paths) and must never enter the repo's diff. First match wins:

1. The session scratchpad directory, when the host names one.
2. An existing directory inside the repo that `git check-ignore -q <dir>` confirms is ignored and whose name says local scratch (`.local`, `.scratch`, `.tmp`, `tmp`, or similar). Read `.gitignore` for candidates.
3. The system temp directory.

Never edit `.gitignore` to manufacture option 2; a tracked-file edit would land in your own diff. Record the chosen path; every later step writes under it.

## 3. Resolve the target

Read `references/resolving-targets.md` and follow it. Classifying the argument is your judgment, not a script's: the same characters can name a file, an issue number, or a work item, and a wrong guess implements the wrong thing. That reference covers file and directory targets, GitHub issues, Azure DevOps work items, bare numbers, and the conversation case, plus how to fetch each and what to do when nothing can fetch.

Completion criterion: the target's full text is in your context, and you have echoed a one-line `Implementing: <title> (<kind>: <ref>)` to the user. Do that echo before anything else happens, so a wrong resolution is visible in the first line of output.

## 4. Snapshot the start state

```
bash <skill-dir>/scripts/snapshot.sh start --scratch <scratch-dir>
```

It records the working tree, including untracked files, as a git tree object without touching the index, and prints the snapshot directory, the tree id, and every file that was already modified or untracked. Keep the `snapshot:` path; step 7 diffs against it. A dirty tree is fine — that is why the snapshot exists — but list the pre-existing dirty files in the report header so nobody mistakes them for your work.

## 5. Derive the acceptance criteria

Read the target closely and write `<scratch>/criteria.md`: a numbered list where each item is one observable behaviour the finished work must have. Take explicit acceptance criteria verbatim when the target has them; derive the rest from the description, comments, and discussion. Each criterion must be checkable by a test or by reading a specific part of the code — "works correctly" is not a criterion, "returns 404 for an unknown id" is.

Print the list to the user. This is not an approval gate; it is the run stating what it will build.

This is the one point where you may ask the user, and only about **scope**: whether child items or linked tickets are part of this run, whether a section that already appears implemented should be redone, which of two spec files is authoritative. Ask everything at once, wait, then continue. If the target contradicts itself in a way that no conservative reading resolves, stop here and report the contradiction instead.

Completion criterion: every requirement in the target maps to at least one criterion, and no criterion exists that the target does not support.

## 6. Implement

Both modes obey `references/test-first.md`. Read it now if you are implementing directly; hand its path to every subagent if you are delegating.

### 6a. Direct (no `--delegate`)

Implement the criteria as one continuous piece of work in the main context. Work criterion by criterion where the code allows it, keeping the tree typechecking as you go. Run single test files as you touch them; the full suite waits for step 7.

### 6b. Delegated (`--delegate`)

**Plan the phases.** Write `<scratch>/phases.md`. A phase is a **vertical slice**: after it lands, the tree typechecks, its tests pass, and at least one criterion is fully satisfied end to end. A phase that satisfies no whole criterion merges into a neighbour. Phases are ordered so each one builds on the last; there is no cap on their number. Each phase section holds: a name, the criteria it satisfies (by number), the files it is expected to own, and any pointers into the codebase the implementer needs to start fast.

**Dispatch sequentially.** One phase at a time, in order, in the shared working tree; the next phase sees the previous phase's edits. Spawn a general-purpose subagent, applying `--model` if given. Its prompt contains, and nothing more:

1. The phase's section from `phases.md`, inlined, with the text of its criteria.
2. Absolute paths to the target text (or the spec file), `criteria.md`, and `references/test-first.md`, with the instruction to read the test-first reference before writing any code.
3. The scope rule: implement only this phase; touch files outside its ownership only when the phase cannot land otherwise, and name every such file in the report.
4. Its own checks: typecheck, and the test files it touched. Not the full suite.
5. Git rules: no staging, committing, stashing, or branch changes.
6. The report contract, which is its entire final message: **Changed** (files, one line each), **Tests added** (file and what each asserts), **Criteria** (each of its numbers with done / partial / not done and why), **Out of scope touched**, **Could not do**.

**Gate each phase.** When the subagent returns: read its report, run `git diff --stat` against the state before dispatch, and run the project's typecheck. The phase passes when typecheck is clean, every one of its criteria reports done, and the diff touches only files it owns or names. Otherwise it fails.

**On failure**: dispatch once more, same model, with the original prompt plus the failure — what the gate saw, what the report claimed. If the retry fails too, implement the phase yourself in the main context, exactly as 6a would. There is no third dispatch. Record every retry and takeover for the report header.

**If the host has no subagent tool**: say so once, then run 6a. `--model` was given nothing to apply to; note that in the header.

## 7. Verify

Verification is yours alone, on whichever model you started with. Do not delegate it.

1. Produce the run's diff:
   ```
   bash <skill-dir>/scripts/snapshot.sh diff <snapshot-dir>
   ```
   This is exactly what changed since step 4, new files included, with pre-existing dirt excluded.
2. Run the project's typecheck, lint, and **full** test suite once, from whatever the repo itself defines (package scripts, Makefile, CI config). Record each command and its result.
3. Walk `criteria.md`. For every criterion, find the test that proves it or the code that implements it, and mark it **pass**, **fail**, or **verified by inspection** (no test could exist, per test-first.md, so you read the code). A criterion with a green test you did not read is not yet a pass.
4. Walk the diff hunk by hunk. Every hunk traces to a criterion or to what a criterion needed (a helper, a type, a fixture). Hunks that trace to nothing are **untraceable** — record them with file and line. Flag them; never revert them.
5. Re-read the target once more against the criteria list, looking for anything the target asks for that never became a criterion. Add it as a criterion and evaluate it now.

**One remediation round.** If any criterion fails or any suite step is red, fix it: in delegated mode, one subagent per failing phase with the failure attached; in direct mode, yourself. Then run steps 1 to 4 again once. Whatever the second verification shows is the result. No further loops.

Completion criterion: every criterion has a verdict, every hunk is traced or flagged, and every project check has a recorded result.

## 8. Report

Compose the report using the template in `references/report.md` and send it as your final message. It ends with the hand-off: the working tree is uncommitted and unstaged, ready for `/git-workflow:review` and then a commit. Nothing in this run touches git state, so that step is the user's.
