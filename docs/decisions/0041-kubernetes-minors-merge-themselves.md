# 0041. Kubernetes minors merge themselves like every other update below a major

- Status: Accepted. Supersedes [0012](0012-renovate-automerge.md) and [0040](0040-renovate-rules-come-from-yggdrasils-preset.md) in part: Kubernetes minors no longer wait for review
- Date: 2026-11-21
- Decider: TJ (zimmertr/yggdrasil#133): "Terraform provider minors and patches merge themselves like every other update, and so do Kubernetes minors in TJs-Kubernetes-Service." And: "No fix adds recurring manual work."
- Issues and PRs: zimmertr/yggdrasil#133

## Context

[0012](0012-renovate-automerge.md) held every Kubernetes minor for TJ, because a Talos release supports only a bounded range of Kubernetes versions and mocked CI couldn't tell whether a pair was supported. [0021](0021-compat-check-reads-talos-support-matrix.md) then gave the `talos-kubernetes` check that answer, and the check is required on `main`. So the hold left TJ a review that the check already does.

## Decision

- `.github/renovate.json` has no rule of its own for `kubernetes/kubernetes`. A Kubernetes minor merges itself once its seven days are up and every required check passes, like every other update below a major.
- A Kubernetes major still waits for TJ, from the preset.

## Evidence

- 2026-11-21: `talos-kubernetes` is a required check on `main` (zimmertr/yggdrasil's `repos/zimmertr/TJs-Kubernetes-Service.yml`), and `compat.yml` fails it when any Talos and Kubernetes pair in `variables.tf` or `vars/*.tfvars` is outside the range Talos supports.
- 2026-11-21: nothing in CI plans or applies against a cluster ([`docs/CICD.md`](../CICD.md)), so a merged bump changes only the default and the tfvars. A cluster takes it at the next manual `apply`.

## Alternatives rejected

- Keep holding Kubernetes minors: a review for TJ on every minor, which the required check already covers.

## Consequences

- Auto-merge is only as safe as `talos-kubernetes`. It must stay required, and keep reading Talos's supported range.
- A merged Kubernetes minor reaches a cluster only when TJ next applies its tfvars, so TJ still chooses when an upgrade runs.
