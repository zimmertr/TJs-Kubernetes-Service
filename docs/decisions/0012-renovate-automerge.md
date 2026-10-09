# 0012. Renovate auto-merges everything below a major, except Kubernetes minors, and comments on Talos and Kubernetes compatibility

- Status: Accepted. The compatibility check's mechanism is amended by 0021
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

TKS already uses Renovate for provider bumps. TJ asked for automatic update PRs, auto-merging minor and patch updates and leaving majors for him. The Talos and Kubernetes versions are plain strings in variable defaults. Each Talos release supports a bounded range of Kubernetes versions, and mocked CI cannot tell whether a pair is supported.

## Decision

- Renovate tracks providers, `required_version`, SHA-pinned Actions, CI tool images, and the Talos and Kubernetes versions (through regex managers).
- Auto-merge: every `patch` and `digest` update, every `minor` update except Kubernetes, and Talos minors.
- Waiting for TJ: Kubernetes minors and every major.
- A workflow on any PR that changes the Talos or Kubernetes version runs `talosctl gen config` at the proposed pair, posts or updates one comment saying whether they are compatible, and fails if they are not, which also blocks auto-merge.
- The Talos and Kubernetes managers land with the v2 refactor, not before, so no bump can auto-merge into v1 `main`, where a version change still replaces VMs.

## Evidence

- Dependabot reads provider blocks and manifests only, so it cannot see version strings inside variable defaults.
- Whether `talosctl gen config` rejects an unsupported Kubernetes version is to be verified in T21. If it does not, the fallback is Sidero's published support matrix.

## Alternatives rejected

- Dependabot: it would not track Talos or Kubernetes, and needs a separate auto-merge workflow.
- Auto-merging Kubernetes minors: risks an unsupported pair that only fails at `apply`.

## Consequences

- Auto-merge is only as safe as the required checks. Branch protection must require them, including the compatibility check.
