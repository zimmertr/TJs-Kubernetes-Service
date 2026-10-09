# CI/CD

Every pull request is checked, every merge to `main` is released, and Renovate keeps dependencies current. Nothing here plans or applies against real infrastructure: GitHub's runners cannot reach a Proxmox host, so applies are manual. Decisions: [0012](decisions/0012-renovate-automerge.md), [0013](decisions/0013-ci-and-semver-releases.md).

## Checks

`.github/workflows/pr.yml` runs on every pull request and on every push to `main`. Each job is one Make target, so any failure reproduces locally with the same command. Each target runs its tool from a pinned container image, so local and CI versions match. Docker Hub images are pulled through `mirror.gcr.io`, because GitHub's shared runners often hit Docker Hub's anonymous pull limit.

| Job | Make target | What it does |
| --- | --- | --- |
| `fmt` | `make fmt-check` | `terraform fmt -recursive -check` |
| `validate` | `make validate` | `terraform init -backend=false` and `validate` in every directory that holds `.tf` files |
| `lint` | `make lint` | tflint with the Terraform ruleset's recommended preset |
| `scan` | `make scan` | `trivy config` at HIGH and CRITICAL severity. The SARIF report goes to code scanning |
| `test` | `make test` | `terraform test` (with mocked providers) in every directory that has tests |
| `actionlint` | `make actionlint` | actionlint on the workflows, and shellcheck on `.github/scripts/` |

`.github/workflows/compat.yml` runs on every pull request too. It reads the Kubernetes range that each pinned Talos version supports from Talos's source, fails if any Talos and Kubernetes pair in `variables.tf` or `vars/*.tfvars` falls outside it, and comments the table on Renovate's PRs that change a version.

`make check` runs the Make targets. `make fmt` and `make docs` (which regenerates [`CONFIGURATION.md`](CONFIGURATION.md)) change files rather than check them. The only local requirements are Docker and Make.

## Pull request titles

PRs are squash-merged, and the PR title becomes the commit title on `main`, so the title has to be a [conventional commit](https://www.conventionalcommits.org): `type(optional scope)!: description`, where `type` is one of `feat`, `fix`, `perf`, `refactor`, `chore`, `docs`, `style`, `test`, `ci` or `build`. `.github/workflows/pr-title.yml` fails any other title, and its job summary shows the version that merging would release.

## Releases

`.github/workflows/release.yml` runs on every push to `main`. It reads the merged commit's title, computes the next version from the latest `v*` tag with `.github/scripts/next-version.sh`, then pushes an annotated tag and publishes a GitHub Release with generated notes.

| Title | Bump | Example |
| --- | --- | --- |
| Any type with `!` before the colon | Major | `feat!: …`, `fix(gpu)!: …` |
| `feat` | Minor | `feat: add the GPU worker` |
| Anything else | Patch | `fix: …`, `docs: …`, `chore(deps): …` |

Every merge releases, including Renovate's dependency bumps.

## Dependency updates

Renovate (`.github/renovate.json`) opens PRs for Terraform providers, `required_version`, GitHub Actions (pinned to commit SHAs), the tool images in the `Makefile` (through their `# renovate:` comments), and `talos_version` and `kubernetes_version` in `variables.tf` and `vars/*.tfvars`. It leaves `talos_config_version` alone, because that is pinned when a cluster is created. It keeps a dependency dashboard issue.

Updates below a major (minor, patch, digest and pin) merge themselves through GitHub auto-merge once the required checks pass. Majors and Kubernetes minors wait for a maintainer, since each Talos release supports a limited range of Kubernetes versions.

## Protecting `main`

A ruleset on `main` requires a pull request and every check above, and blocks force pushes and deletion. It requires no approving review: GitHub does not let authors approve their own PRs, and Renovate needs to auto-merge. Merges are squash-only, and branches are deleted after merge.
