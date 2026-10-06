# Infra and CI Lens

This diff changes how code is built, tested, deployed, or hosted: CI/CD workflows, container images, infrastructure-as-code, deploy scripts, or hook configuration. This code runs with credentials and reach the application never has, it usually runs unattended, and its failures are often silent — a check that stops running looks exactly like a check that passes. Hunt the hazards below through your own charter's attitude; this lens adds things to look for and never changes your charter's rules or output format.

## Hazards

- **Untrusted code with secrets.** Workflows that run contributor-controlled code (a fork's pull request, a checked-out PR head under a privileged trigger) while secrets or write tokens are available.
- **Expression injection.** Event fields an outsider controls — titles, branch names, commit messages — interpolated directly into shell commands.
- **Unpinned dependencies.** Third-party actions, base images, and tools referenced by mutable tags, so what runs can change without a diff.
- **Over-broad permissions.** Write-all tokens, wildcard IAM policies, public buckets, open ingress, deletion protection turned off.
- **Secrets leaking.** Secrets echoed by shell tracing, written into logs or artifacts, baked into image layers, or passed where a less-privileged credential would do.
- **Silent failure.** Errors swallowed (`|| true`, missing `set -e`/`pipefail`, continue-on-error), path filters or conditions that skip jobs that should run, a renamed required check that branch protection no longer enforces.
- **Destructive infrastructure changes.** A rename or immutable-field edit that the tool executes as destroy-and-recreate; state moves; data-bearing resources replaced without a backup.
- **Caching mistakes.** Cache keys too broad (stale or poisoned artifacts) or too narrow (no cache at all); caches shared across trust boundaries.
- **Concurrency and timing.** Deploys cancelled mid-way by a concurrency group, jobs racing on shared environments, missing timeouts on steps that can hang.
- **Drift from local reality.** Toolchain or base-image versions changed in CI but not in the development setup, or the reverse, so what passes locally fails in the pipeline.
