# The one task only this repo runs, from a pinned container image, so the only
# local requirements are Docker and Make. The checks (Terraform, and shellcheck
# on the scripts) come from zimmertr/yggdrasil's terraform and lint modules
# instead (decision records 0039 and 0042); docs/CICD.md says how to run them
# locally. Renovate bumps the version below through its `# renovate:`
# annotation.

# renovate: datasource=github-releases depName=terraform-docs/terraform-docs extractVersion=^v(?<version>.+)$
TFDOCS_VERSION := 0.25.1

# terraform-docs publishes per-architecture tags only.
TFDOCS_ARCH := $(if $(filter arm64 aarch64,$(shell uname -m)),arm64,amd64)

# Run as the invoking user so files written into the repo are not root-owned.
DOCKER := docker run --rm -v $(CURDIR):/src -w /src --user $(shell id -u):$(shell id -g) -e HOME=/tmp
TFDOCS := $(DOCKER) quay.io/terraform-docs/terraform-docs:$(TFDOCS_VERSION)-$(TFDOCS_ARCH)

.PHONY: docs

docs:
	$(TFDOCS) --config .terraform-docs.yml .
