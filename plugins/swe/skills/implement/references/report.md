# Final report

The report is the run's final message and must stand on its own for someone who did not watch the run. Facts only: what was asked, what was built, what was checked, what is still open. Fill every section; a section with nothing to say gets the single word `None`.

```
# Implemented: <title> (<kind>: <ref>)

Mode: direct | delegated (<n> phases, implementer model: <name or "inherited">).
Scratch: <absolute path>
<Retries or takeovers: "Phase 3 retried once; phase 5 implemented by orchestrator after two failures." — or omit the line.>
<Files already dirty at start, one line, or omit.>
<Notes from the run: --model rejected by host, no subagent tool available, no test infrastructure, etc. — or omit.>

## Criteria

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | <criterion text> | pass | `path/to/test.ts` — <test name> |
| 2 | <criterion text> | verified by inspection | `src/x.ts:40-58` — <one clause on what was read> |
| 3 | <criterion text> | fail | <what was observed, and what the remediation round tried> |

## Project checks

| Check | Command | Result |
|---|---|---|
| Typecheck | `<command>` | clean |
| Lint | `<command>` | clean / <n> warnings / not configured |
| Tests | `<command>` | <passed>/<total> |

## Untraceable changes

- `path:line-range` — <what it does, and why no criterion covers it>

## Ambiguities resolved conservatively

- <the ambiguity> → <the reading chosen>, <where in the code>

## Out of scope but touched

- `path` — <why the phase or slice needed it>

## Next step

The working tree holds the implementation, uncommitted and unstaged. Review it with `/git-workflow:review`, then commit. Nothing in this run changed git state.
```

## Rules

- Criteria appear in the order of `criteria.md`, with any criterion added in verification step 5 appended and marked *(added during verification)*.
- A **pass** cites a test that was read, not just run. **Verified by inspection** cites the code location. **Fail** describes what was observed, never what was hoped.
- Untraceable hunks are reported with file and line and are left in the working tree. The user decides whether to keep them.
- No prose summary above the table. The title line and the mode line are the whole introduction.
