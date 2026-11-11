# 0040. Renovate's shared rules come from yggdrasil's preset, and every update waits seven days

- Status: Accepted. Supersedes [0038](0038-titles-workflow-lint-and-releases-come-from-yggdrasil.md) in part
- Date: 2026-11-11
- Decider: TJ (zimmertr/yggdrasil#40). On the wait: "Lets make sure everything has at least a 1-week cooldown then." On one preset: "I am tempted to switch everything and just define it in yggdrasil and import it into the child repos." On yggdrasil's own modules: "Those can go immediately".
- Issues and PRs: zimmertr/yggdrasil#40, zimmertr/yggdrasil#90, zimmertr/yggdrasil#94

## Context

[0012](0012-renovate-automerge.md) had Renovate merge everything below a major as soon as the checks passed, with no wait. [0038](0038-titles-workflow-lint-and-releases-come-from-yggdrasil.md) added a three-day wait for yggdrasil's modules and left the choice between Renovate and Dependabot to zimmertr/yggdrasil#40. That issue is settled: every repo of TJ's uses Renovate, and the rules they share live once, in yggdrasil's `defaults/renovate.json` (its record 0056).

## Decision

- `.github/renovate.json` extends `github>zimmertr/yggdrasil//defaults/renovate` in place of `config:recommended` and its two helpers, which the preset extends itself.
- The preset's rules replace TKS's copies: every release waits seven days, everything below a major then merges itself, and yggdrasil's own modules merge with no wait.
- TKS keeps what is its own: Kubernetes minors wait for review, the regex managers for the `Makefile`, `variables.tf` and `vars/*.tfvars`, and both PR limits at `0`.
- Terraform providers keep merging themselves below a major, as they have since 0012. yggdrasil holds its own providers for TJ because a merge there applies to real repos. Nothing in TKS's CI applies.

## Evidence

- 2026-11-11: `renovate-config-validator --strict` passes on the new file, in the `renovate/renovate` image.
- 2026-11-11, on zimmertr/yggdrasil, the first repo on the preset: Renovate opened zimmertr/yggdrasil#91 and #92, and both merged themselves once the checks passed. Eight more updates were held as too young.

## Alternatives rejected

- Keeping TKS's own rules beside the preset: two copies of the same rules, which drift.
- Holding Terraform providers for TJ, as yggdrasil does: a provider update here changes nothing until someone runs `terraform apply`, and the tests run against every bump.

## Consequences

- A Talos or Kubernetes patch reaches `main` seven days after its release, not the same day.
- A change to the shared rules happens in yggdrasil and reaches TKS on Renovate's next run, with no PR here.
- The compat check still runs on every PR and comments on Renovate's version PRs ([0021](0021-compat-check-reads-talos-support-matrix.md)).
