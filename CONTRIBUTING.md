# Contributing

TKS has one maintainer, and contributions are welcome.

1. **Open an issue first** for anything beyond a typo, so the approach can be agreed before code is written.
2. **Keep pull requests small and focused.** One change per PR.
3. **Title the PR as a conventional commit** (`feat: …`, `fix: …`, `docs: …`; `!` for breaking). The title becomes the commit on `main` and decides the release version. See [`docs/CICD.md`](docs/CICD.md).
4. **Let CI run the checks.** The Terraform checks come from zimmertr/yggdrasil's `terraform` module; [`docs/CICD.md`](docs/CICD.md) says how to run one locally with Docker. `make check` runs shellcheck on the scripts.
5. **Ship tests with behavior.** Changes to variables, modules or resources come with `terraform test` coverage using mocked providers.
6. **Update the docs in the same PR.** A design decision gets a record in [`docs/decisions/`](docs/decisions/README.md).
