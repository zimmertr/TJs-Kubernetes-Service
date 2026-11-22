# 0042. CI takes yggdrasil v3: the scripts are shellchecked by the lint module, and Scorecard runs

- Status: Accepted. Supersedes [0038](0038-titles-workflow-lint-and-releases-come-from-yggdrasil.md) and [0039](0039-terraform-checks-come-from-yggdrasil.md) in part: the scripts' shellcheck moves to yggdrasil's lint module, and the `Makefile` keeps only `docs`
- Date: 2026-11-21
- Decider: TJ (zimmertr/yggdrasil#133), which moves every repo onto yggdrasil's v3 modules, and for this repo drops its own `shellcheck` job.
- Issues and PRs: zimmertr/yggdrasil#133

## Context

[0038](0038-titles-workflow-lint-and-releases-come-from-yggdrasil.md) kept a `shellcheck` job and `make shellcheck` here, because yggdrasil's lint module shellchecked only the workflows' `run:` blocks. zimmertr/yggdrasil v3.0.0 added a `shellcheck` job to that module, over every script in the repo, and a `docs` job for links and em dashes. v3 also added a `scorecard` module, and its release module now asks for two more permissions to attest what it pushes.

## Decision

- Every module call pins v3.0.0.
- `Lint / shellcheck` checks `.github/scripts/talos-k8s-compat.sh` and `bin/tks`. `pr.yml`'s own `shellcheck` job, `make shellcheck` and `make check` are gone, and the `Makefile` keeps only `docs`.
- `Lint / docs` checks the Markdown links and anchors, and refuses an em dash.
- `release.yml` grants `attestations: write` and `id-token: write`. TKS pushes no image or chart, so nothing is attested, but GitHub refuses the run if the caller grants less than a module job asks for.
- `scorecard.yml` runs OpenSSF Scorecard weekly and on every push to `main`, with its findings in the Security tab.

## Evidence

- 2026-11-21, zimmertr/yggdrasil#133: the lint module's shellcheck and docs jobs had no findings in this repo.
- 2026-11-21: yggdrasil's `compose.yml` pins `koalaman/shellcheck-alpine` v0.11.0, the version `make shellcheck` ran, and finds `bin/tks` by its executable bit.

## Alternatives rejected

- Keep `make shellcheck` for local runs: a second shellcheck pin for Renovate to bump, when the module's runs locally through yggdrasil's `compose.yml` like the Terraform checks do.

## Consequences

- The ruleset requires `Lint / shellcheck` and `Lint / docs` in place of `shellcheck`, set in zimmertr/yggdrasil's `repos/zimmertr/TJs-Kubernetes-Service.yml`.
- A new script anywhere in the repo is shellchecked with no change here.
