# CI/CD

Every pull request is checked, every merge to `main` is released, and Renovate keeps dependencies current. Nothing here plans or applies against real infrastructure: GitHub's runners cannot reach a Proxmox host, so applies are manual. Decisions: [0012](decisions/0012-renovate-automerge.md), [0013](decisions/0013-ci-and-semver-releases.md), [0038](decisions/0038-titles-workflow-lint-and-releases-come-from-yggdrasil.md).

The title check, the workflow lint and the release come from [zimmertr/yggdrasil](https://github.com/zimmertr/yggdrasil)'s reusable workflows, pinned by commit SHA with the version beside it. The Terraform checks are this repo's own.

## Checks

`.github/workflows/pr.yml` runs on every pull request and on every push to `main`. Each job is one Make target, so any failure reproduces locally with the same command. Each target runs its tool from a pinned container image, so local and CI versions match. Docker Hub images are pulled through `mirror.gcr.io`, because GitHub's shared runners often hit Docker Hub's anonymous pull limit.

| Job | Make target | What it does |
| --- | --- | --- |
| `fmt` | `make fmt-check` | `terraform fmt -recursive -check` |
| `validate` | `make validate` | `terraform init -backend=false` and `validate` in every directory that holds `.tf` files |
| `lint` | `make lint` | tflint with the Terraform ruleset's recommended preset |
| `scan` | `make scan` | `trivy config` at HIGH and CRITICAL severity. The SARIF report goes to code scanning |
| `test` | `make test` | `terraform test` (with mocked providers) in every directory that has tests. `bootstrap/` is tested with `vars/bootstrap.tfvars` |
| `shellcheck` | `make shellcheck` | shellcheck on `.github/scripts/` and `bin/tks` |

`.github/workflows/lint.yml` runs yggdrasil's `lint` module on every pull request: `Lint / actionlint` (actionlint, with shellcheck on each `run:` block), `Lint / zizmor` (zizmor's pedantic audits of the workflows) and `Lint / semgrep` (a Dockerfile rule; TKS has no Dockerfile, so it scans nothing). A finding is fixed, or silenced inline with a `# zizmor: ignore[<audit>]` comment that gives the reason.

`.github/workflows/compat.yml` runs on every pull request too. It reads the Kubernetes range that each pinned Talos version supports from Talos's source, fails if any Talos and Kubernetes pair in `variables.tf` or `vars/*.tfvars` falls outside it, and comments the table on Renovate's PRs that change a version.

`make check` runs the Make targets. `make fmt` and `make docs` (which regenerates [`CONFIGURATION.md`](CONFIGURATION.md)) change files rather than check them. The only local requirements are Docker and Make.

## Pull request titles

PRs are squash-merged, and the PR title becomes the commit title on `main`, so the title has to be a [conventional commit](https://www.conventionalcommits.org): `type(optional scope)!: description`, where `type` is one of `feat`, `fix`, `perf`, `refactor`, `chore`, `docs`, `style`, `test`, `ci` or `build`. `.github/workflows/pr-title.yml` calls yggdrasil's `pr-title` module, whose `PR Title / PR Title` check fails any other title.

## Releases

`.github/workflows/release.yml` calls yggdrasil's `release` module on every push to `main`. GitVersion reads the merged commit's title and counts from the latest `v*` tag, then the module tags the commit and publishes a GitHub Release with generated notes. On a pull request the same module runs as a dry run, and the `Release / Version` job summary shows the version that merging would release.

| Title | Bump | Example |
| --- | --- | --- |
| Any type with `!` before the colon | Major | `feat!: …`, `fix(gpu)!: …` |
| `feat` | Minor | `feat: add the GPU worker` |
| Anything else | Patch | `fix: …`, `docs: …`, `chore(deps): …` |

Every merge releases, including Renovate's dependency bumps.

## Dependency updates

Renovate (`.github/renovate.json`) opens PRs for Terraform providers, `required_version`, GitHub Actions (pinned to commit SHAs), the tool images in the `Makefile` (through their `# renovate:` comments), and `talos_version` and `kubernetes_version` in `variables.tf` and `vars/*.tfvars`. It leaves `talos_config_version` alone, because that is pinned when a cluster is created. It keeps a dependency dashboard issue.

Updates below a major (minor, patch, digest and pin) merge themselves through GitHub auto-merge once the required checks pass. Majors and Kubernetes minors wait for a maintainer, since each Talos release supports a limited range of Kubernetes versions. A patch or minor of yggdrasil's workflows merges itself only once the release is three days old.

## Protecting `main`

A ruleset on `main` requires a pull request and every check above, and blocks force pushes and deletion. It requires no approving review: GitHub does not let authors approve their own PRs, and Renovate needs to auto-merge. Merges are squash-only, and branches are deleted after merge.
