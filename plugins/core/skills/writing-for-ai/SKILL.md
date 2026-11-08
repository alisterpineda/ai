---
name: writing-for-ai
description: "Write instructions an agent follows the same way every run, at the lowest load: SKILL.md files, subagent definitions and charters, the prompts a skill gives its subagents, CLAUDE.md and AGENTS.md, and slash commands. Use when creating, restructuring, tightening, or reviewing one. Not for one-line fixes, prompts written on the fly, or writing for people."

# Maintainer notes (hosts that strip frontmatter never show these to the model):
# - Structure, steps, wording, and description rules restate ideas from Matt
#   Pocock's writing-for-agents (github.com/mattpocock/skills).
# - Load, maintainer-note, template, and editing rules come from trimming swe's
#   code-review-core and plan (9f55b5c, ff67881), checked with evals at --runs 3:
#   - code-review-core's SKILL.md shrank 28%, its charters only 6-10%.
#   - Eval cost moved -1% against ±12-19% per-case noise.
#   - Loosening "when your prompt names one" to "when there is one" made the
#     verifier refute valid findings in 2 of 3 runs.
# - Host facts checked 2026-11: Claude Code and Copilot CLI strip skill
#   frontmatter, Codex and VS Code pass it; Claude Code strips CLAUDE.md HTML
#   comments, Codex keeps AGENTS.md ones; Codex reads neither invocation field.
---

# Writing for AI

An agent runs its instructions rather than reads them. Write them so it takes the same path every run, and so every word earns the tokens it costs each time it loads.

## Structure

- Put in the main file what every path through it needs. Move what only some paths need into a reference file, behind a pointer that says when to read it.
- Keep a concept's definition, rules, and exceptions under one heading.
- State each rule once. When several files need one section of another, move that section into a small reference file they all point at: reading a file for one section loads all of it.
- Leave out what one lookup finds (package scripts, config, `--help`). Write down what no file says: unwritten conventions and gotchas.

## Steps

- End each step on a condition the agent can check. Where thoroughness matters, make it demanding: "every caller accounted for", not "list the callers".
- When an agent rushes a step, sharpen its condition first. Move the later steps behind a subagent or hand-off only if a sharp condition still gets rushed; steps split within one context stay visible.
- Drop a "Done when" line that repeats its step's last sentence. Fold one that adds a rule ("a finding unresolved after round 3 is open") into the step.
- Turn prose that restates a template into placeholders inside it: `<one row per criterion; a refuted unmet criterion is unverifiable>`.

## Wording

- State the behavior you want: "write one-line comments". A ban names the unwanted behavior and makes it likelier; keep one only as a hard guardrail, next to the behavior you want instead.
- Name a recurring idea with one word the model already knows, and reuse that word instead of re-explaining the idea, in the description, the body, and the repo's own docs. A coined word costs its definition.
- Delete a sentence that asks for what the agent does by default. When unsure what the default is, run it without the sentence.
- Keep a reason only when it is the instruction itself, and then write the instruction: "The command stands alone so the shell reports its exit code" becomes "Run exactly this one command, with nothing chained to it." Other reasons are maintainer notes.

## Load

- CLAUDE.md, AGENTS.md, skill descriptions, and inline skills stay in the conversation: they are paid again every turn.
- An orchestrator's prompt to a subagent is paid once per subagent it spawns.
- A forked skill's or subagent's own file is paid once per run, then discarded.

Look first between an orchestrator and the files its subagents read: a prompt restating rules the subagent's charter already holds. Keep the rule in the charter and give the prompt paths.

## Descriptions and invocation

- A description loads in every session. Lead with the skill's key word, give one trigger per distinct case (synonyms are one case), and leave out what the body says.
- Make a skill user-invoked with `disable-model-invocation: true` unless the agent or another skill must reach it on its own. Its description then leaves the model's context, and only `/name` runs it. `user-invocable: false` is the reverse: hidden from the `/` menu, still loaded by the model, description still paid.
- Claude Code, Copilot CLI, and VS Code honor both fields. Codex reads neither; it takes `policy.allow_implicit_invocation: false` in the skill's `agents/openai.yaml`.
- Two user-invoked skills can't call each other. Put rules both need in a plain file both point at.

## Maintainer notes

Why a rule exists, and which files depend on it, is for maintainers. Put it where the host hides it from the model:

- In a file with YAML frontmatter (skill, subagent, command): `#` comments in the frontmatter. Claude Code and Copilot CLI strip it; Codex and VS Code Copilot Chat show it.
- In CLAUDE.md: block-level `<!-- -->` comments, which Claude Code strips. AGENTS.md comments reach the model.
- In AGENTS.md, which has no hidden place: a file beside it the agent doesn't load, such as a README. Keep a reason inline only when the agent needs it to act.

## Editing existing instructions

- Keep every scoping condition exactly as written: "in the named slice, when your prompt names one" and "when there is one" select different cases.
- Keep every string something else matches on: headings, fixed lines, IDs, anything a grader, script, or other skill reads.
- A rewrite that keeps the meaning keeps the mistakes. When the agent already misjudges a case, add one explicit sentence covering it, as a separate change.
- Run the project's tests or evals afterwards. They show behavior held; their cost is too noisy to show what a cut saved.
