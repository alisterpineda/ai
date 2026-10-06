# Public API Lens

This diff changes something consumed outside the repository or by a separately deployed component — a library's exports, a CLI, an HTTP or RPC endpoint, configuration, a schema or wire format, an event, a plugin or skill interface. Those consumers are invisible to an in-repo search: every caller you can find may be updated while the ones that matter are not. Hunt the hazards below through your own charter's attitude; this lens adds things to look for and never changes your charter's rules or output format.

## Hazards

- **Removed or renamed surface.** An exported symbol, flag, subcommand, env var, config key, endpoint, field, or skill/command name that existing consumers still use. Check whether an alias, a deprecation warning, or a version bump carries them across.
- **Changed defaults.** Everyone who never set the value silently gets new behavior. A default change is a behavior change for the largest group of consumers.
- **Narrowed inputs, widened outputs.** A parameter newly required or accepting fewer values; a return that can now be null, a new error type, a new enum member that exhaustive matches downstream don't handle.
- **Same signature, new meaning.** Units, ordering, idempotency, nullability, time zones, rounding, or side effects changed while the types stayed the same — nothing fails to compile, everything is subtly wrong.
- **Wire and schema formats.** Field removal, rename, or type change; casing or ordering a parser relies on; serialization of new values old readers reject. Old and new versions of producer and consumer will coexist during any rollout.
- **Machine-read output.** Exit codes, stdout formats, and error messages that scripts and other tools parse are part of the interface even when nobody wrote them down as such.
- **Accidental surface.** Something newly exported, documented, or reachable becomes a contract the author did not mean to sign.
- **Versioning and notes.** The project's own convention for marking breaks — semver bumps, changelog entries, migration notes — not followed for a change that breaks consumers.
