# Every check CI runs is a target here. Each tool runs from a pinned container
# image, so a local run and a CI run use the same versions and the only local
# requirements are Docker and Make. Renovate bumps the versions below through
# the `# renovate:` annotations.

# renovate: datasource=docker depName=hashicorp/terraform
TERRAFORM_VERSION := 1.16.5
# renovate: datasource=docker depName=ghcr.io/terraform-linters/tflint
TFLINT_VERSION := v0.64.0
# renovate: datasource=docker depName=ghcr.io/aquasecurity/trivy
TRIVY_VERSION := 0.75.0
# renovate: datasource=docker depName=rhysd/actionlint
ACTIONLINT_VERSION := 1.7.12
# renovate: datasource=github-releases depName=terraform-docs/terraform-docs extractVersion=^v(?<version>.+)$
TFDOCS_VERSION := 0.24.0

# terraform-docs publishes per-architecture tags only.
TFDOCS_ARCH := $(if $(filter arm64 aarch64,$(shell uname -m)),arm64,amd64)

# Docker Hub images come through Google's public mirror: GitHub's shared
# runners hit Docker Hub's anonymous pull limit and timeouts often.
DOCKERHUB := mirror.gcr.io

CACHE := $(CURDIR)/.cache
# Run as the invoking user so files written into the repo are not root-owned.
DOCKER := docker run --rm -v $(CURDIR):/src -w /src --user $(shell id -u):$(shell id -g) -e HOME=/tmp
TERRAFORM := $(DOCKER) -v $(CACHE)/plugins:/plugins -e TF_PLUGIN_CACHE_DIR=/plugins -e TF_IN_AUTOMATION=1 $(DOCKERHUB)/hashicorp/terraform:$(TERRAFORM_VERSION)
# GITHUB_TOKEN, when set, lifts the GitHub API rate limit for plugin downloads.
TFLINT := $(DOCKER) -v $(CACHE)/tflint:/tflint -e TFLINT_PLUGIN_DIR=/tflint -e GITHUB_TOKEN --entrypoint tflint ghcr.io/terraform-linters/tflint:$(TFLINT_VERSION)
TRIVY := $(DOCKER) -v $(CACHE)/trivy:/trivy-cache ghcr.io/aquasecurity/trivy:$(TRIVY_VERSION) --cache-dir /trivy-cache
ACTIONLINT := $(DOCKER) $(DOCKERHUB)/rhysd/actionlint:$(ACTIONLINT_VERSION)
TFDOCS := $(DOCKER) quay.io/terraform-docs/terraform-docs:$(TFDOCS_VERSION)-$(TFDOCS_ARCH)

# Every directory holding .tf files is validated, so new modules and roots are
# picked up without editing this file.
TF_DIRS := $(sort $(dir $(shell find . -name '*.tf' -not -path '*/.terraform/*' -not -path './.cache/*')))
# `terraform test` runs in each directory that owns a *.tftest.hcl file, either
# directly or under its tests/ directory.
TEST_DIRS := $(sort $(shell find . -name '*.tftest.hcl' -not -path '*/.terraform/*' -not -path './.cache/*' | sed -E 's|/tests/[^/]+$$||; s|/[^/]+\.tftest\.hcl$$||; s|^\./?||; s|^$$|.|'))

# Extra arguments for CI, e.g. SARIF output for code scanning.
TRIVY_ARGS ?=

.PHONY: check fmt fmt-check validate lint scan test actionlint docs cache

check: fmt-check validate lint scan test actionlint

cache:
	@mkdir -p $(CACHE)/plugins $(CACHE)/tflint $(CACHE)/trivy

fmt:
	$(TERRAFORM) fmt -recursive

fmt-check:
	$(TERRAFORM) fmt -recursive -check -diff

validate: cache
	@set -e; for d in $(TF_DIRS); do \
		echo "==> validate $$d"; \
		$(TERRAFORM) -chdir=$$d init -backend=false -input=false -no-color >/dev/null; \
		$(TERRAFORM) -chdir=$$d validate -no-color; \
	done

lint: cache
	$(TFLINT) --init
	$(TFLINT) --recursive --config /src/.tflint.hcl

scan: cache
	$(TRIVY) config --config trivy.yaml $(TRIVY_ARGS) .

test: cache
	@set -e; if [ -z "$(TEST_DIRS)" ]; then echo "No terraform tests yet."; exit 0; fi; \
	for d in $(TEST_DIRS); do \
		echo "==> test $$d"; \
		$(TERRAFORM) -chdir=$$d init -backend=false -input=false -no-color >/dev/null; \
		$(TERRAFORM) -chdir=$$d test -no-color; \
	done

actionlint:
	$(ACTIONLINT) -color
	$(DOCKER) --entrypoint shellcheck $(DOCKERHUB)/rhysd/actionlint:$(ACTIONLINT_VERSION) .github/scripts/*.sh bin/manage_nodes

docs:
	$(TFDOCS) --config .terraform-docs.yml .
