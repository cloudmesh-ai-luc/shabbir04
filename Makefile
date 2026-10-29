# Makefile for InferScale (shabbir04)

.PHONY: all install install-model test clean docs serve

# Default target: install and run the tests
all: install test

# Install the project in editable mode with the test tools (the tests do not need PyTorch)
install:
	pip install -e ".[test]"

# Also install PyTorch, needed to run the real model
install-model:
	pip install -e ".[test,model]"

# Run the tests (they use a fake model and a fake database)
test:
	pytest tests/

# Remove build artifacts and caches
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	rm -rf .pytest_cache build dist src/*.egg-info

# Serve the documentation website locally
docs:
	pip install -e ".[docs]"
	mkdocs serve

# Start the API on http://127.0.0.1:8000 (needs make install-model and PostgreSQL)
serve:
	inferscale serve
