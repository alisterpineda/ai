---
name: ideate
description: Interview the user in rounds until you share an understanding of a plan, design, or decision, in any domain. Use when the user explicitly asks to be grilled, interviewed, or stress-tested, or to work through a plan, design, or decision together before acting. A single question with a clear answer gets a direct answer instead.
---

# Ideate

Interview the user until you both hold the same understanding of their idea, then hand it back as a **Shared understanding** block. You facilitate; the conversation is the only output.

## The design tree

Map the idea as a **design tree**: every decision branches into the decisions that depend on it. The **frontier** is every open decision whose prerequisites are settled.

Decisions belong to the user. Facts belong to you: when a question rests on something you can look up (the codebase, files, docs, the web), look it up before asking, delegating to a subagent when one is available, and put what you found into the question. A lookup still running blocks only the questions downstream of it.

## Rounds

Ask in rounds. The first round opens with a **premise check**: is this the right problem, framed the right way? Then work the frontier.

Every round obeys these rules:

- **Numbering continues across the session.** If the last round ended at Q4, this one starts at Q5. A question carried over keeps its number.
- **No question in a round can be invalidated by another's answer.** When one answer could change or void another question, the second waits for a later round. Close the round by naming what is waiting and on what.
- **At most five questions.** The rest of the frontier waits.
- **Every question lists its options and a recommendation with its reason**, in this shape:

```
❓ **Q5 – <short title>**: <the question>

- **(a) <option>.** <what it means>
- **(b) <option>.** <what it means>

➡️ **(a).** <why>
```

Open each round after the first with a one-line recap of what the last answers settled.

## Handling answers

- **Agreement** settles the decision; recompute the frontier.
- **"N/A" or a skip** prunes that branch and everything hanging off it. If a later decision truly needs it, re-raise it once and say why it is needed; a second N/A sends it to Open.
- **No answer** carries the question to the next round under its number.
- **A reversal** of an earlier decision: name it as a reversal, and reopen the decisions that hung off the old answer.
- **An answer resting on a wrong fact**: correct the fact once, with its source, then accept the user's decision.

## Ending

The interview ends when the frontier is empty, or when the user says stop. Every branch is then decided, pruned, or open. Send the block:

```
## Shared understanding

**Decisions**
1. <decision> — <why>

**Open**
- <unsettled or deferred item> — <why it is open>
```

Ask the user to confirm it. Correct and resend it until they do.
