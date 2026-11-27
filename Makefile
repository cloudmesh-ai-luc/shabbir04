# Makefile for InferScale (shabbir04)

.PHONY: all install install-model test clean docs serve image up down logs

# The version from VERSION also tags the Docker image (inferscale-api:<version>)
VERSION := $(shell cat VERSION)
export VERSION

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

# ---- Docker: run these on the VM (cmx vm run); the Mac has no Docker ----

# A random database password, made once on the VM and never committed (*.env is in .gitignore)
db.env:
	umask 077 && echo "POSTGRES_PASSWORD=$$(openssl rand -hex 16)" > $@

# Build the api image (CPU-only PyTorch, model included)
image:
	docker compose build

# Start db and api in the background; api starts when the database is healthy
up: db.env
	docker compose up -d

# Stop and remove the containers; the database volume is kept
down:
	docker compose down

# Follow the container logs
logs:
	docker compose logs -f --tail=50
