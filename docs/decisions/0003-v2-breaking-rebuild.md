# 0003. v2 is a breaking rewrite, and clusters are rebuilt rather than migrated

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

Adding the GPU module was the moment to bring TKS up to current practice: modules, typed variables, CI, tests, releases. Terraform `moved` blocks could migrate existing state into the new layout with a zero-change plan, but only by shaping the new code around the old addresses.

## Decision

v2 has no backwards-compatibility code. Existing clusters are destroyed and rebuilt from v2: `test` first, then `stable`. The current `main` is tagged `v1.0.0` before any v2 change merges, so existing users can pin the old layout.

## Evidence

None measured. Persistent data in `stable` lives on static PVs in Kubernetes-Manifests, which TJ has rebound across rebuilds before.

## Alternatives rejected

- In-place migration with `moved` blocks: it keeps the old resource addresses alive in the new design, which is the debt v2 exists to remove.

## Consequences

- The v2 release notes say "rebuild", and give the `v1.0.0` tag as the way to stay on v1.
- VMIDs in `stable` are realigned with their IPs during the rebuild (control planes were 402x for .1x, workers 403x for .2x).
