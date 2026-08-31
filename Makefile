.PHONY: lint setup-env providers-lock

# Installs the pinned tool versions from .tool-versions (terraform,
# terraform-docs, checkov, pre-commit) via mise, plus the repository's git
# hooks. Idempotent - safe to rerun any time, including after pulling a
# Renovate version-bump PR that changes .tool-versions.
setup-env:
	command -v mise >/dev/null 2>&1 || curl https://mise.run | sh
	mise install
	mise exec -- pre-commit install
	mise exec -- pre-commit install --hook-type commit-msg

# Runs all pre-commit hooks (formatting, docs, commit lint, terraform
# fmt/validate/checkov) against the full repository.
lint:
	mise exec -- pre-commit run --all-files

# Regenerates .terraform.lock.hcl for every module and example with hashes
# for all platforms CI and local macOS use. Plain `terraform init` only
# records the current host platform; committing that makes the
# terraform_validate pre-commit hook fail on Linux CI with
# "files were modified by this hook". Run after adding a module/example or
# bumping a provider constraint, then commit the updated lock files.
#
# Usage:
#   make providers-lock                          # all modules + examples
#   make providers-lock DIRS="modules/foo examples/foo"
providers-lock:
	@dirs="$(if $(DIRS),$(DIRS),$(wildcard modules/*/ examples/*/))"; \
	for d in $$dirs; do \
		[ -f "$$d/versions.tf" ] || [ -f "$$d/main.tf" ] || continue; \
		echo "=== $$d ==="; \
		(cd "$$d" && mise exec -- terraform providers lock \
			-platform=linux_amd64 \
			-platform=darwin_amd64 \
			-platform=darwin_arm64); \
	done
