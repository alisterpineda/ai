---
name: ideate
description: Interview the user in rounds until you share an understanding of a plan, design, or decision, in any domain. Use when the user explicitly asks to be grilled, interviewed, stress-tested, or to have holes poked in a plan, design, or decision, or to work through one together before acting. Not for interviews that produce content, such as a Q&A write-up, a mock job interview, or a quiz. A single question with a clear answer gets a direct answer instead.
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
- **"N/A" or a skip** prunes that branch and everything hanging off it. If a later decision truly needs it, re-raise it once and say why it is needed. A second N/A is the user's decision: record it under Decisions as declined, with what the later decision assumes in its place.
- **A deferral** ("I'll decide that later") is the user's decision: record it under Decisions as deferred, with who decides or when, and take it off the frontier.
- **No answer** carries the question to the next round under its number.
- **A reversal** of an earlier decision: name it as a reversal, and reopen the decisions that hung off the old answer.
- **An answer resting on a wrong fact**: correct the fact once, with its source, then accept the user's decision.

## Ending

The interview ends when the frontier is empty, or when the user says stop. Every branch is then decided, pruned, or open. A decision is open for one of two reasons only:

- **Not reached**: the user stopped before it was settled.
- **Waiting on a fact** that no one in the conversation has and no lookup can find, such as a quote, a measurement, or someone else's view.

Anything else you could still ask is not open: ask it before ending. Send the block, leaving out **Open** when nothing is open:

```
## Shared understanding

**Decisions**
1. <decision> — <why>
2. Declined: <item> — <later decision> assumes <assumption> instead
3. Deferred: <item> — <who decides, or when>

**Open**
- <item> — not reached
- <item> — waiting on <fact>
```

Ask the user to confirm it. Correct and resend it until they do.
