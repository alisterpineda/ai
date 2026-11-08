#!/usr/bin/env bash
# A skill planted with what an align must cut (a "Done when" that repeats its
# step, a "so that" reason, prose restating the template) and what it must
# keep (a scoping condition, the report's fixed strings, a rule-carrying
# "Done when").
set -euo pipefail
mkdir -p skills/triage
cat > skills/triage/SKILL.md <<'SKILL'
---
name: triage
description: Triage a bug report into a label and a next step. Use when asked to triage an issue.
---

# Triage

## 1. Read the report

Read the issue text and every file it names. Search only the directory your prompt names, when your prompt names one. Note the version, the steps to reproduce, and the expected and actual behavior.

Done when you have noted the version, the steps to reproduce, and the expected and actual behavior.

## 2. Reproduce

Try to reproduce the bug in up to 3 rounds, each in a fresh environment, so that state left over from one round can't hide or fake the bug in the next.

Done when the bug reproduces, or after round 3: a bug not reproduced by then is reported as unconfirmed.

## 3. Report

Your final message is this template:

```
## Triage: <issue title>
Label: <bug | needs-info | not-a-bug>
Next step: <one sentence>
```

The report starts with a Triage heading naming the issue title, then a Label line with one of bug, needs-info, or not-a-bug, then a Next step line holding one sentence. When there is nothing to do, the report's last line is exactly `No action needed.`
SKILL
