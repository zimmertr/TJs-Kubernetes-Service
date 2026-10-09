# 0013. Every pull request runs format, validate, lint, scan, test and workflow lint, and releases are cut from PR titles

- Status: Accepted
- Date: 2026-10-09
- Decider: TJ (planning interview)
- Issues and PRs: the v2 planning PR

## Context

TKS had no CI, no tags and no releases. Bluebird is the reference for a mature project: conventional-commit PR titles, automatic semver releases, SHA-pinned actions, and Makefile targets that match CI.

## Decision

- Pull requests run `terraform fmt -check`, `terraform validate` (every root), `tflint` with the Terraform ruleset, `trivy config`, `terraform test` with mocked providers, and `actionlint` on the workflows. Each check is also a Makefile target.
- PR titles must be conventional commits. Squash-merging to `main` cuts a semver tag and a GitHub Release: `!` for major, `feat` for minor, everything else for patch.
- GitHub secret scanning and push protection are on.

## Evidence

- `mock_provider` needs Terraform 1.7 or newer. The latest Terraform is 1.16.5.
- tfsec's maintainers point users to Trivy.

## Alternatives rejected

- Plans against a real Proxmox host in CI: GitHub's runners cannot reach it, and a self-hosted runner is more machinery than TKS needs. Real applies are manual, on `test`.

## Consequences

- Behavior changes ship with `terraform test` coverage.
- Trivy has no Proxmox- or Talos-specific checks, so it mainly catches generic misconfiguration. It is kept because it is cheap.
- Every merge cuts a release, including Renovate's patch bumps.
