.PHONY: lint setup-lint

setup-env:
	command -v mise >/dev/null 2>&1 || curl https://mise.run | sh
	mise install
	mise exec -- pre-commit install
	mise exec -- pre-commit install --hook-type commit-msg

# Installs the pinned tool versions from .tool-versions (terraform,
# terraform-docs, checkov, pre-commit) via mise, plus the repository's git
# hooks. Idempotent - safe to rerun any time, including after pulling a
# Renovate version-bump PR that changes .tool-versions.
setup-lint:
	command -v mise >/dev/null 2>&1 || curl https://mise.run | sh
	mise install
	mise exec -- pre-commit install
	mise exec -- pre-commit install --hook-type commit-msg

# Runs all pre-commit hooks (formatting, docs, commit lint, terraform
# fmt/validate/checkov) against the full repository.
lint:
	mise exec -- pre-commit run --all-files
