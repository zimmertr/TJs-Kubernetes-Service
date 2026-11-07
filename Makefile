# The checks only this repo runs, each from a pinned container image, so the
# only local requirements are Docker and Make. The Terraform checks (fmt,
# validate, test, tflint, Trivy) come from zimmertr/yggdrasil's terraform module
# instead (decision record 0039); docs/CICD.md says how to run them locally.
# Renovate bumps the versions below through the `# renovate:` annotations.

# renovate: datasource=docker depName=koalaman/shellcheck
SHELLCHECK_VERSION := v0.11.0
# renovate: datasource=github-releases depName=terraform-docs/terraform-docs extractVersion=^v(?<version>.+)$
TFDOCS_VERSION := 0.24.0

# terraform-docs publishes per-architecture tags only.
TFDOCS_ARCH := $(if $(filter arm64 aarch64,$(shell uname -m)),arm64,amd64)

# Docker Hub images come through Google's public mirror: GitHub's shared
# runners hit Docker Hub's anonymous pull limit and timeouts often.
DOCKERHUB := mirror.gcr.io

# Run as the invoking user so files written into the repo are not root-owned.
DOCKER := docker run --rm -v $(CURDIR):/src -w /src --user $(shell id -u):$(shell id -g) -e HOME=/tmp
SHELLCHECK := $(DOCKER) $(DOCKERHUB)/koalaman/shellcheck:$(SHELLCHECK_VERSION)
TFDOCS := $(DOCKER) quay.io/terraform-docs/terraform-docs:$(TFDOCS_VERSION)-$(TFDOCS_ARCH)

.PHONY: check shellcheck docs

check: shellcheck

# The workflows are linted by yggdrasil's lint module (lint.yml), which
# shellchecks only their `run:` blocks.
shellcheck:
	$(SHELLCHECK) .github/scripts/*.sh bin/tks

docs:
	$(TFDOCS) --config .terraform-docs.yml .
