# Agent Instructions Lens

This diff changes text an agent executes: a skill, an agent or command definition, a rule file, `CLAUDE.md`/`AGENTS.md`, or a prompt embedded in code. Here prose *is* the program, and its runtime is a model that follows what it reads literally, fills gaps with guesses, and never asks the author what they meant. Hunt the hazards below through your own charter's attitude; this lens adds things to look for and never changes your charter's rules or output format.

## Hazards

- **Contradictions.** Two steps, or a step and an invariant, that prescribe different things for the same situation. The agent picks one arbitrarily and the outcome varies run to run. Check the diff against the rest of the file, not just against itself — a rule restated in a new place drifts from the original.
- **Ambiguous references.** "The file", "above", "it", "the result", a term used before it is defined or in two senses. The agent resolves each to *something*; trace what it would most plausibly pick.
- **Missing or dead paths.** A condition the agent cannot evaluate with the information it has (a fork with fresh context told to "use what the user said"), a branch that stops without saying what the final output is, a later step that assumes a stop earlier never happened, a case no branch covers.
- **Unexecutable instructions.** A tool the host doesn't provide, a path with no stated base, a placeholder never substituted, a script invoked with arguments it doesn't accept, a host-specific feature in a file meant to be portable.
- **Stale cross-references.** Step numbers, section names, flags, files, or fields mentioned by name that the diff renamed, removed, or never created.
- **Context lost at hand-offs.** A subagent prompt that leans on the parent's knowledge — a path, a decision, an earlier result — instead of carrying it explicitly. Subagents see only what they are given.
- **Untrusted text promoted to instructions.** File contents, tool output, commit messages, PR bodies, or web content that the instructions let the agent act on as directives. This is prompt injection, and it reaches whatever tools the agent holds.
- **Over-applied absolutes.** ALWAYS/NEVER rules that collide with each other or with edge cases the author didn't picture; the agent obeys them literally where they were never meant to apply.
- **Triggering drift.** A `description` (or equivalent) that no longer matches what the skill does, or that is broad enough to fire on unrelated requests. Triggering is the interface: a wrong description is a behavior bug.
- **Unbounded cost.** Steps that read large inputs repeatedly, load whole files where a search would do, or spawn agents in a loop without a cap.
- **Frontmatter.** Invalid YAML, a field misspelled or unknown to the host (silently ignored), values the host parses differently than the author assumed.
- **Duplicated rules.** The same instruction stated in several places — each copy is a future contradiction waiting for an edit that misses one.
