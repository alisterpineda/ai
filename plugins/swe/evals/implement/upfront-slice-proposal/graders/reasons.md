---
type: llm
focus: last_message
---
The spec has three slices. Slice 1 is marked "Done: 2026-10-01."; slice 2 (line_count) has no marker, but
the code and tests already meet its criterion; slice 3 (top_words) is unbuilt. PASS only if the final
message (1) proposes slice 3 as the slice to build, (2) says slice 1 counts as finished because it is
marked done, (3) says slice 2 counts as finished because the existing code already meets its criterion,
and (4) asks the user to confirm before building. FAIL if any is missing, or if it reports having built
anything.
