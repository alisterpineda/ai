# Test-first rules

Tests are written before the code that makes them pass, one slice at a time, at the seams the spec names. These rules apply to every phase, whether the orchestrator or an implementer subagent is writing the code. The seam and anti-pattern material here follows the shape of Matt Pocock's `tdd` skill, restated so this plugin has no dependency on it and so no step requires interviewing the user.

## Seams

A **seam** is the public boundary you observe behaviour at without reaching inside: a function's signature, an HTTP route, a CLI invocation, a rendered component's output, a database's state after an operation. Tests live at seams, never against internals; internals may be rewritten without the tests moving.

Seams are **pre-agreed** in this order, and the first source that yields one is used without asking anyone:

1. Seams the spec or ticket names explicitly.
2. The seam each acceptance criterion in `criteria.md` describes — a criterion is by construction an observable behaviour at some boundary, so it names its seam.
3. The nearest existing public interface in the code the criterion touches.

Read `CONTEXT.md`, `CONTRIBUTING.md`, and any ADR directory when present so test names and vocabulary match the project's domain language.

## The loop

- **One slice at a time.** One seam, one test, one minimal implementation per cycle. Watch the test fail for the reason you expect before making it pass. A test that passes on first run proves nothing about the code you are about to write.
- **Red means the right red.** A compile error or a missing import is not the failure you want; the assertion is. Fix setup until the assertion is what fails.
- **Refactor on green only.** Restructuring happens after the test passes and before the next slice.
- **Typecheck after every slice.** Run single test files as you go; the full suite is run once, by the orchestrator, at verification.

## What a good test asserts

- **Behaviour at the seam**, not the shape of the implementation. Renaming a private helper should break no test.
- **An independent expected value**: a known-good literal, a worked example from the spec, a value a person could check by hand. Expected values never come from the code under test.
- **One reason to fail.** A test that asserts five unrelated things reports one failure and hides four.

## Anti-patterns to keep out

- **Tautological**: the assertion recomputes the expected value the way the code does, so it passes by construction.
- **Mock of the thing under test**: mocking the seam and then asserting on the mock. Mock only what is beyond the seam (network, clock, filesystem) and only when the real thing is impractical.
- **Implementation-coupled**: asserting on call order, private state, or internal method invocations.
- **Snapshot without a reader**: a serialized blob nobody could tell is right or wrong.
- **Test-after retrofit**: writing the code first and then a test shaped to whatever it happens to do. If you notice this happened, delete the test and write it from the criterion.

## Which project tooling

Use what the repo uses: its test runner, its assertion style, its file placement convention. Discover these from the existing tests and package or build configuration; do not introduce a new framework or a new directory convention.

## When there is no test infrastructure

Choosing a test framework is a design decision, and the plan is closed. Write no tests. Instead, say so plainly in your report, and note for each criterion that it will need **verification by inspection**: the orchestrator reads the implementing code against the criterion. Where the project has *some* runner but a criterion is impractical to test (it needs live external systems, or a UI with no harness), the same rule applies to that criterion alone.
