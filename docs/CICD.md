# CI/CD

Every pull request is checked, every merge to `main` is released, and Renovate keeps dependencies current. Nothing here plans or applies against real infrastructure: GitHub's runners cannot reach a Proxmox host, so applies are manual. Decisions: [0012](decisions/0012-renovate-automerge.md), [0013](decisions/0013-ci-and-semver-releases.md), [0038](decisions/0038-titles-workflow-lint-and-releases-come-from-yggdrasil.md), [0039](decisions/0039-terraform-checks-come-from-yggdrasil.md).

The title check, the workflow lint, the Terraform checks and the release come from [zimmertr/yggdrasil](https://github.com/zimmertr/yggdrasil)'s reusable workflows, pinned by commit SHA with the version beside it.

## Checks

`.github/workflows/pr.yml` runs on every pull request and on every push to `main`. Its `Terraform` job calls yggdrasil's `terraform` module, which runs each tool in the container image yggdrasil's `compose.yml` pins. `validate`, `test` and Trivy run in each folder `pr.yml` lists: `.`, `bootstrap` and the four under `modules/`. A new folder with Terraform joins that list.

| Check | What it does |
| --- | --- |
| `Terraform / fmt` | `terraform fmt -recursive -check` |
| `Terraform / validate` | `terraform init -backend=false` and `validate` in each listed folder |
| `Terraform / test` | `terraform test` (with mocked providers) in each listed folder. `bootstrap/tests/terraform.tfvars` is a link to `vars/bootstrap.tfvars`, which `terraform test` loads by itself, so the bootstrap tests check the values that get applied |
| `Terraform / tflint` | tflint's bundled recommended rules, over every folder |
| `Terraform / trivy` | `trivy config` with yggdrasil's `defaults/trivy.yaml`, in each listed folder. Any finding fails |
| `shellcheck` | `make shellcheck`: shellcheck on `.github/scripts/` and `bin/tks` |

To run a Terraform check locally, clone zimmertr/yggdrasil beside this repo and run the module's command through its `compose.yml`, for example:

```sh
docker compose -f ../yggdrasil/compose.yml --project-directory . run --rm -T terraform fmt -recursive
```

`.github/workflows/lint.yml` runs yggdrasil's `lint` module on every pull request: `Lint / actionlint` (actionlint, with shellcheck on each `run:` block), `Lint / zizmor` (zizmor's pedantic audits of the workflows) and `Lint / semgrep` (a Dockerfile rule; TKS has no Dockerfile, so it scans nothing). A finding is fixed, or silenced inline with a `# zizmor: ignore[<audit>]` comment that gives the reason.

`.github/workflows/compat.yml` runs on every pull request too. It reads the Kubernetes range that each pinned Talos version supports from Talos's source, fails if any Talos and Kubernetes pair in `variables.tf` or `vars/*.tfvars` falls outside it, and comments the table on Renovate's PRs that change a version.

`make check` runs `shellcheck`. `make docs` regenerates [`CONFIGURATION.md`](CONFIGURATION.md). The only local requirements are Docker and Make.

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

Renovate (`.github/renovate.json`) opens PRs for Terraform providers, `required_version`, GitHub Actions (pinned to commit SHAs), the shellcheck and terraform-docs versions in the `Makefile` (through their `# renovate:` comments), and `talos_version` and `kubernetes_version` in `variables.tf` and `vars/*.tfvars`. It leaves `talos_config_version` alone, because that is pinned when a cluster is created. It keeps a dependency dashboard issue.

Updates below a major (minor, patch, digest and pin) merge themselves through GitHub auto-merge once the required checks pass. Majors and Kubernetes minors wait for a maintainer, since each Talos release supports a limited range of Kubernetes versions. A patch or minor of yggdrasil's workflows merges itself only once the release is three days old.

## Protecting `main`

A ruleset on `main` requires a pull request and every check above, and blocks force pushes and deletion. It requires no approving review: GitHub does not let authors approve their own PRs, and Renovate needs to auto-merge. Merges are squash-only, and branches are deleted after merge.
