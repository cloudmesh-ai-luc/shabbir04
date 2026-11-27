# Makefile for InferScale (shabbir04)

.PHONY: all install install-model test clean docs serve certs image up down logs passwords

# The version from VERSION also tags the Docker images (inferscale-api:<version>, inferscale-web:<version>)
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

# A self-signed certificate for the VM's public IP (and 127.0.0.1 for checks on the VM).
# The private key is made on the VM and never leaves it. Usage: make certs IP=<public IP>
certs:
	@test -n "$(IP)" || { echo "usage: make certs IP=<public IP of the VM>"; exit 1; }
	mkdir -p secrets
	sudo openssl req -x509 -newkey rsa:2048 -nodes -days 30 -subj "/CN=$(IP)" \
	  -addext "subjectAltName=IP:$(IP),IP:127.0.0.1" -keyout secrets/tls.key -out secrets/tls.crt

# Build the api and web images (CPU-only PyTorch with the model; nginx with the web page)
image:
	docker compose build

# Start db, api and web in the background (each waits until the one before it is healthy).
# Needs secrets/: tls.crt and tls.key (make certs) and htpasswd and metrics.htpasswd (make passwords on the laptop).
SECRETS := tls.key htpasswd metrics.htpasswd
up: db.env
	@for f in tls.crt $(SECRETS); do test -f secrets/$$f || { echo "missing secrets/$$f (see make certs and make passwords)"; exit 1; }; done
	cd secrets && sudo chown 101:101 $(SECRETS) && sudo chmod 600 $(SECRETS)   # 101 is the nginx user
	docker compose up -d

# Stop and remove the containers; the database volume is kept
down:
	docker compose down

# Follow the container logs
logs:
	docker compose logs -f --tail=50

# ---- Accounts: run this on the laptop ----

# Random passwords for the four accounts, kept only in ~/.config/inferscale (readable only by me).
# Only their bcrypt hashes (htpasswd, metrics.htpasswd) are copied to the VM.
CONFIG := $(HOME)/.config/inferscale
passwords:
	@mkdir -p $(CONFIG) && chmod 700 $(CONFIG)
	@for u in owner demo client prometheus; do \
	  test -f $(CONFIG)/$$u.password || (umask 077 && openssl rand -base64 24 > $(CONFIG)/$$u.password); \
	done
	@umask 077 && for u in owner demo client; do \
	  htpasswd -niB -C 5 $$u < $(CONFIG)/$$u.password | head -1; done > $(CONFIG)/htpasswd
	@umask 077 && for u in owner prometheus; do \
	  htpasswd -niB -C 5 $$u < $(CONFIG)/$$u.password | head -1; done > $(CONFIG)/metrics.htpasswd
	@echo "Passwords and hashes are in $(CONFIG), readable only by you"
