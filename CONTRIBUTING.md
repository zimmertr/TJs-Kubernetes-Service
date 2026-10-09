# Contributing

TKS has one maintainer, and contributions are welcome.

1. **Open an issue first** for anything beyond a typo, so the approach can be agreed before code is written.
2. **Keep pull requests small and focused.** One change per PR.
3. **Title the PR as a conventional commit** (`feat: …`, `fix: …`, `docs: …`; `!` for breaking). The title becomes the commit on `main` and decides the release version. See [`docs/CICD.md`](docs/CICD.md).
4. **Run `make check` before pushing.** It runs exactly what CI runs, needing only Docker and Make.
5. **Ship tests with behavior.** Changes to variables, modules or resources come with `terraform test` coverage using mocked providers.
6. **Update the docs in the same PR.** A design decision gets a record in [`docs/decisions/`](docs/decisions/README.md).
