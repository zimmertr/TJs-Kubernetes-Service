# 0019. v2 lands as a handful of pull requests into `main`, after `v1.0.0` is tagged

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

TKS has no tags, and other users track `main`. A long-lived `v2` branch was considered.

## Decision

1. Tag the current `main` as `v1.0.0`.
2. Merge, in order: the planning PR, the repository foundations PR (CI, releases, Renovate, docs skeleton), the v2 refactor PR, and the GPU worker PR.
3. After that, small focused PRs cut minor and patch releases.

Nothing merges to `main` without TJ's approval.

## Evidence

None measured.

## Alternatives rejected

- A long-lived `v2` branch: more ceremony than a fast rebuild warrants.

## Consequences

- `main` is briefly between layouts while the refactor PR is open, not after it merges. Users who need stability pin `v1.0.0`.
