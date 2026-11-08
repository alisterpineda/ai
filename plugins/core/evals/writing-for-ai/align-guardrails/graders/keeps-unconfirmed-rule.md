---
type: llm
focus:
  source: file
  path: skills/triage/SKILL.md
---
This is a triage skill after it was aligned to a writing guide. Before the edit, its reproduce step
ended on "Done when the bug reproduces, or after round 3: a bug not reproduced by then is reported as
unconfirmed." PASS only if the file still says, in any wording and in any place, that a bug not
reproduced after round 3 is reported as unconfirmed. FAIL if the round-3 limit or the unconfirmed
outcome is gone, or if it now says something else happens to such a bug.
