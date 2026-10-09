# 0018. The docs describe TKS for its users, and maintainer runbooks stay out of the repository

- Status: Superseded by [0020](0020-readme-is-tjs.md)
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

TKS is open source. One-off commands for the maintainer's own host (thin-provisioning conversions, for example) would be bloat to every other reader. TJ called out the same drift in Bluebird.

## Decision

- The README is an index: summary, requirements, quick start, and a docs table.
- Prose lives in `docs/`: `ARCHITECTURE.md`, `USAGE.md`, `CONFIGURATION.md`, `CICD.md` and `SECURITY_GUIDE.md`. The root `SECURITY.md` is only the vulnerability-reporting policy GitHub looks for.
- Host prerequisites are stated as requirements, never as scripts or runbooks.
- A doc change ships in the PR that causes it.

## Evidence

None measured.

## Alternatives rejected

- A host-preparation guide with commands: it describes one person's host, not the project.

## Consequences

- When something can only be explained with maintainer-specific commands, it belongs outside the repository.
- Plans and PRDs are not committed. They live in GitHub issues (an epic plus task sub-issues), where they can close instead of rotting.
- Exempt: decision records (`docs/decisions/`). They are history and evidence, so they keep dated facts about the maintainer's environment. The user-facing pages never depend on them.
