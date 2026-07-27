.PHONY: lint setup-lint fmt fmt-check validate checkov docs

# Directories containing standalone Terraform configurations (modules and
# examples each get their own provider requirements and are validated
# independently).
TF_DIRS := $(shell find modules examples -mindepth 1 -maxdepth 1 -type d)

setup-lint:
	pip install pre-commit checkov
	pre-commit install
	pre-commit install --hook-type commit-msg

# Runs all pre-commit hooks (formatting, docs, commit lint, terraform
# fmt/validate/checkov) against the full repository.
lint:
	pre-commit run --all-files

# Individual targets are kept for fast local iteration without invoking
# pre-commit, and are also reused by CI so failures are easy to reproduce.
fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -recursive -check -diff

validate:
	@set -e; \
	for dir in $(TF_DIRS); do \
		echo "==> terraform validate: $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false > /dev/null; \
		terraform -chdir=$$dir validate; \
	done

checkov:
	@set -e; \
	for dir in $(TF_DIRS); do \
		echo "==> checkov: $$dir"; \
		checkov -d $$dir --quiet --compact; \
	done

docs:
	@for dir in modules/*; do \
		terraform-docs markdown table --output-file README.md --output-mode inject $$dir; \
	done
