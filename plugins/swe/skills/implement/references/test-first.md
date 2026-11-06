# Test-first rules

Tests are written before the code that makes them pass, one behavior at a time, at the seams the spec names. These rules apply to every line of code the run writes: the first build, fixes for failing checks, and fixes for review findings. The seam and anti-pattern material follows the shape of Matt Pocock's `tdd` skill, restated here so this plugin has no dependency on it.

## Seams

A **seam** is the public boundary you observe behavior at without reaching inside: a function's signature, an HTTP route, a CLI invocation, a rendered component's output, a database's state after an operation. Tests live at seams, never against internals, so internals can be rewritten without the tests moving.

Take the seam from the first of these that names one:

1. A seam the spec names explicitly.
2. The seam an acceptance criterion describes. A criterion is an observable behavior at some boundary, so it names its seam.
3. The nearest existing public interface in the code the criterion touches.

Read `CONTEXT.md`, `CONTRIBUTING.md`, and any ADR directory when present, so test names match the project's domain language.

## The loop

- **One behavior at a time.** One seam, one test, one minimal implementation per cycle. Watch the test fail for the reason you expect before making it pass: a test that passes on its first run proves nothing about the code you are about to write.
- **The right red.** A compile error or a missing import is not the failure you want; the assertion is. Fix setup until the assertion is what fails.
- **Refactor on green only.** Restructure after the test passes and before the next behavior.
- **Typecheck after every cycle**, and run the test files you touched. The full suite runs at the project-checks step.

## What a good test asserts

- **Behavior at the seam**, not the shape of the implementation. Renaming a private helper breaks no test.
- **An independent expected value**: a known-good literal, a worked example from the spec, a value a person could check by hand. Expected values never come from the code under test.
- **One reason to fail.** A test that asserts five unrelated things reports one failure and hides four.

## Anti-patterns to keep out

- **Tautological**: the assertion recomputes the expected value the way the code does, so it passes by construction.
- **Mock of the thing under test**: mocking the seam and then asserting on the mock. Mock only what lies beyond the seam (network, clock, filesystem), and only when the real thing is impractical.
- **Implementation-coupled**: asserting on call order, private state, or internal method calls.
- **Snapshot without a reader**: a serialized blob nobody could tell is right or wrong.
- **Test-after retrofit**: code first, then a test shaped to whatever it happens to do. If that happened, delete the test and write it again from the criterion.

## Which tooling

Use what the repo uses: its test runner, its assertion style, its file placement. Discover them from the existing tests and the package or build configuration, and introduce no new framework or directory convention.

## No test infrastructure

Choosing a test framework is a design decision the spec did not make. Write no tests; mark every criterion for **verification by inspection** (you read the implementing code against the criterion), and say so in the report's notes. When the project has a runner but one criterion is impractical to test (it needs a live external system, or a UI with no harness), the same rule applies to that criterion alone.
