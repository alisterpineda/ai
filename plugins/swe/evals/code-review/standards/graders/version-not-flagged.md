---
type: llm
focus: last_message
---
The repo's CLAUDE.md requires bumping VERSION in any commit that changes src/, and the reviewed
commit DID bump VERSION from 1.2.0 to 1.3.0. PASS if no confirmed finding (a "### " heading and
its bullets) claims the VERSION rule was broken or the bump is missing. FAIL otherwise.
