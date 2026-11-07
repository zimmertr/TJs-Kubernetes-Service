# 0039. The Terraform checks come from yggdrasil's terraform module, with no config files of TKS's own

- Status: Accepted. Supersedes [0038](0038-titles-workflow-lint-and-releases-come-from-yggdrasil.md) in part
- Date: 2026-11-07
- Decider: TJ (zimmertr/yggdrasil#8). On the shared module: "Shared module". On TKS's choices: link the bootstrap test to `vars/bootstrap.tfvars`, drop the Security tab upload, and remove the Makefile's Terraform targets, each the recommended option.
- Issues and PRs: zimmertr/yggdrasil#8, zimmertr/yggdrasil#47

## Context

[0038](0038-titles-workflow-lint-and-releases-come-from-yggdrasil.md) kept TKS's own `fmt`, `validate`, `lint`, `scan` and `test` jobs because no yggdrasil module checked Terraform. zimmertr/yggdrasil#47 (v0.10.0) added one, built from the same five checks, so TKS's copies became a second set of the same checks and pins.

## Decision

- `pr.yml`'s `Terraform` job calls yggdrasil's `terraform` module with the six folders that hold Terraform: `.`, `bootstrap` and the four under `modules/`. The ruleset requires `Terraform / fmt`, `Terraform / validate`, `Terraform / test`, `Terraform / tflint` and `Terraform / trivy` in place of `fmt`, `validate`, `lint`, `scan` and `test`.
- `.tflint.hcl` and `trivy.yaml` are gone. tflint with no file uses the same recommended rules the file turned on, and the module's `defaults/trivy.yaml` finds nothing in any folder, at any severity.
- `bootstrap/tests/terraform.tfvars` is a link to `vars/bootstrap.tfvars`. `terraform test` loads a `terraform.tfvars` from the test folder by itself, so the bootstrap tests still check the users and privileges that get applied, with no flag and no second copy.
- Trivy's findings no longer go to the Security tab. A finding fails the PR, as before.
- The `Makefile` keeps `shellcheck` and `docs` only. `make check` runs `shellcheck`.
- Every yggdrasil pin moves to v0.10.0 together.

## Evidence

- 2026-11-07, in Docker with the module's images (Terraform 1.17.1, tflint v0.65.0, Trivy 0.76.1): `trivy config` with `defaults/trivy.yaml` exited 0 in all six folders; `tflint --recursive` with no config reported nothing; `validate` and `test` passed in five folders. `bootstrap`'s tests failed for want of `users` ("No value for required variable") until `vars/bootstrap.tfvars` was in `bootstrap/tests/terraform.tfvars`, and then passed 7 of 7.

## Alternatives rejected

- A module input that passes a var file per folder: a new input and more shell in the module, for one folder whose file Terraform can already load.
- Moving `vars/bootstrap.tfvars`: the README and the docs point users to it.
- Adding the Security tab upload to the module: findings already fail the PR, and TKS has none.
- Keeping the Makefile's Terraform targets for local runs: a second copy of the checks and their pins.

## Consequences

- A new folder with Terraform is checked only once it joins `directories` in `pr.yml`.
- A local run of the Terraform checks uses yggdrasil's `compose.yml`, as [`docs/CICD.md`](../CICD.md) says.
- The tool versions move when Renovate bumps the yggdrasil pin, not through this repo's `Makefile`.
