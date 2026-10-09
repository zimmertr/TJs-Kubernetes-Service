# 0021. The compatibility check reads the Kubernetes range from Talos's source, not from `talosctl gen config`

- Status: Accepted
- Date: 2026-10-09
- Decider: Claude, within the scope TJ set for T21 (keep it small)
- Issues and PRs: T21, the TKS v2 PR

## Context

[0012](0012-renovate-automerge.md) said the compatibility workflow would run `talosctl gen config` at the proposed Talos and Kubernetes pair and fail if they were not compatible.

## Decision

`.github/scripts/talos-k8s-compat.sh` downloads `pkg/machinery/compatibility/talosNNN/talosNNN.go` from the `siderolabs/talos` tag of each pinned Talos version. It reads `MinimumKubernetesVersion` and `MaximumKubernetesVersion`, and fails if the Kubernetes version falls outside that range. It checks the defaults in `variables.tf` and every `vars/*.tfvars`, and it runs on every PR. The comment is posted only on Renovate's PRs that change a version, since those are the ones a reviewer decides on from the comment (TJ, 2026-10-09). The rest of 0012 stands.

## Evidence

- 2026-10-09: `talosctl gen config` and `talosctl validate` at Talos 1.14 accepted Kubernetes versions outside the supported range, so they could not catch a bad pair.
- 2026-10-09: Talos v1.14.2's `talos114.go` gives a range of 1.32.0 to 1.37.99. This is the same data `talosctl upgrade-k8s` checks.

## Alternatives rejected

- `talosctl gen config`: it doesn't reject unsupported pairs.
- A hand-maintained table of supported versions: it goes stale with every Talos release.

## Consequences

- The check depends on the file's path and constant names in Talos's source. If Talos moves them, the check fails closed ("no support matrix") rather than passing.
- The compat check must be added to the `main` ruleset's required checks once it exists on `main`, so it blocks Renovate's auto-merge.
