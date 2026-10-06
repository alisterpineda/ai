# Migrations Lens

This diff changes how persisted data is shaped: a schema migration, a model change that implies one, a backfill, or a format that existing stored data must still satisfy. Migrations run once, against production-sized data that the author's development database doesn't resemble, usually while the old version of the code is still serving traffic. Hunt the hazards below through your own charter's attitude; this lens adds things to look for and never changes your charter's rules or output format.

## Hazards

- **Destructive and irreversible steps.** Dropped tables or columns, narrowing type changes, and data transforms with no down migration or no way back once old data is gone.
- **Deploy ordering.** Code and schema never deploy atomically. Old code must survive the new schema (a column removed while old code still reads it) and new code must survive the old one until the migration finishes. Look for the expand-then-contract split where it's needed.
- **Locks and long transactions.** Table rewrites, index builds without the database's online option, and backfills in a single transaction that hold locks over millions of rows and stall the application.
- **Constraints versus existing data.** A new NOT NULL, unique, or foreign-key constraint that rows already in production violate — nulls, duplicates, orphans the author's fixtures never had.
- **Backfill design.** Backfills run at application startup, unbatched, non-resumable, or not idempotent, so a failure halfway leaves data in a state neither version of the code expects.
- **Edited history.** An already-applied migration modified in place, or reordered, so environments that ran the old version diverge silently from fresh ones.
- **Environment differences.** SQL that works on the development engine (SQLite, a newer version) and fails or behaves differently in production.
- **Rollback.** A down migration that doesn't actually restore the old state, or an application rollback that cannot run against the migrated schema.
- **Other persisted formats.** Cache entries, queued messages, files, and serialized objects written by the old code that the new code must still read.
