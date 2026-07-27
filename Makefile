.PHONY: lint setup-lint

setup-lint:
	pip install pre-commit checkov
	pre-commit install
	pre-commit install --hook-type commit-msg

# Runs all pre-commit hooks (formatting, docs, commit lint, terraform
# fmt/validate/checkov) against the full repository.
lint:
	pre-commit run --all-files
