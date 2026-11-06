# 0038. PR titles, workflow lint and releases come from yggdrasil's modules; the Terraform checks stay here

- Status: Accepted
- Date: 2026-11-06
- Decider: TJ (zimmertr/yggdrasil#7)
- Issues and PRs: zimmertr/yggdrasil#7

## Context

TJ's repos share CI through reusable workflows in zimmertr/yggdrasil, each pinned by commit SHA. TKS had its own versions of three of them: a regex title check, `actionlint` through `make actionlint`, and `.github/scripts/next-version.sh` for releases. Its Terraform checks, the Trivy misconfiguration scan and the Talos and Kubernetes compatibility check have no yggdrasil module.

## Decision

- `pr-title.yml` calls yggdrasil's `pr-title` module. The ruleset requires `PR Title / PR Title` in place of `title`. The allowed types are the ones [0013](0013-ci-and-semver-releases.md) named.
- `lint.yml` calls yggdrasil's `lint` module: actionlint, zizmor's pedantic audits and one Semgrep Dockerfile rule. The ruleset requires `Lint / actionlint`, `Lint / zizmor` and `Lint / semgrep` in place of `actionlint`.
- actionlint shellchecks only the workflows' `run:` blocks, so `make shellcheck` and the `shellcheck` job check `.github/scripts/*.sh` and `bin/tks`, and the ruleset requires `shellcheck`.
- `release.yml` calls yggdrasil's `release` module on every push to `main`. GitVersion reads the bump from the squash commit's title with the module's default patterns, counts from the latest `v*` tag, and the module tags the commit and publishes a GitHub Release with generated notes. `next-version.sh` is gone. On a PR, the same module runs with `dry-run: true` and its job summary names the version the merge releases.
- TKS keeps its own `fmt`, `validate`, `lint`, `scan` and `test` jobs, `trivy.yaml`, and `compat.yml` with `talos-k8s-compat.sh`.
- Renovate stays (zimmertr/yggdrasil#40 decides between it and Dependabot). Its rule for `zimmertr/yggdrasil` waits three days before a patch or minor merges itself.

## Evidence

- 2026-11-06: of the repo's 89 PRs, the 74 from #49 on have titles the `pr-title` module accepts. The 15 it would refuse are #1 to #48, from before TKS checked titles.
- 2026-11-06: the `siderolabs/talos` provider 0.12.0 rendered a `talos_machine_configuration` for Talos v1.14.0 with Kubernetes v1.20.0, a pair outside the 1.32.0 to 1.37.99 range in [0021](0021-compat-check-reads-talos-support-matrix.md), with no error or warning. Terraform 1.17.1 in Docker, local state only. The provider also sees only `talos_config_version`, not the installed `talos_version`.
- 2026-11-06: `make shellcheck` (koalaman/shellcheck v0.11.0) passes on the scripts and fails on a test script with an unquoted `$1` (SC2086).

## Alternatives rejected

- Keeping `next-version.sh`: it repeats the release module, which Bluebird and hevy-trainer-sync already release through.
- Dropping `talos-k8s-compat.sh` for the provider's own checks: the provider accepts an unsupported pair.
- Moving the Trivy scan into a yggdrasil module: no module scans Terraform, and writing one is outside zimmertr/yggdrasil#7. `trivy.yaml` stays here as TKS's own setting.
- Dropping shellcheck on the scripts: `bin/tks` is about 300 lines of shell that users run by hand.

## Consequences

- A change to the title rules, the workflow audits or the release flow happens in yggdrasil, and reaches TKS through Renovate's bump of the pin.
- The module makes plain tags where `next-version.sh` made annotated ones. GitVersion reads both.
- GitVersion's types and the `pr-title` module's types must stay the same list. Both live in yggdrasil.
