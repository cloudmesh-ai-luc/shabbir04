# InferScale API image: FastAPI + DistilBERT on CPU
# Build: make image    (run on the VM; see compose.yaml)
FROM python:3.15.2-slim

ENV PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HF_HOME=/opt/hf
WORKDIR /app

# 0. Debian security updates for the base image (Trivy in CI found a fixed libzstd1)
RUN apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

# 1. CPU-only PyTorch: about 200 MB instead of several GB with the GPU libraries
RUN pip install torch==2.15.0 --index-url https://download.pytorch.org/whl/cpu

# 2. The app and its dependencies (only these files reach the image, see .dockerignore).
#    Then a newer setuptools (PyTorch needs it; the old one carried a vulnerable copy of wheel), and
#    pip is removed: the running service never installs packages, and pip carries its own copies of
#    urllib3, msgpack and setuptools, which Trivy in CI reported as vulnerable.
COPY pyproject.toml VERSION README.md ./
COPY src ./src
RUN pip install . \
 && pip install --upgrade "setuptools>=78.1.1" \
 && pip uninstall -y pip

# 3. Download the model now, so the container starts without the internet
RUN python -c "from inferscale.app import MODEL; from transformers import pipeline; pipeline('sentiment-analysis', model=MODEL)"
ENV HF_HUB_OFFLINE=1

# 4. Run as a normal user (app, uid 10001), not root; the number works even where the name is unknown
RUN useradd --uid 10001 --no-create-home app
USER 10001

EXPOSE 8000
# the model needs up to a minute to load, so the first checks may fail
HEALTHCHECK --interval=10s --timeout=5s --start-period=120s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=4)"]
CMD ["inferscale", "serve", "--host", "0.0.0.0"]
