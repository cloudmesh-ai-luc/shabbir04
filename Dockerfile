# InferScale API image: FastAPI + DistilBERT on CPU
# Build: make image    (run on the VM; see compose.yaml)
FROM python:3.15.2-slim

ENV PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HF_HOME=/opt/hf
WORKDIR /app

# 1. CPU-only PyTorch: about 200 MB instead of several GB with the GPU libraries
RUN pip install torch==2.15.0 --index-url https://download.pytorch.org/whl/cpu

# 2. The app and its dependencies (only these files reach the image, see .dockerignore)
COPY pyproject.toml VERSION README.md ./
COPY src ./src
RUN pip install .

# 3. Download the model now, so the container starts without the internet
RUN python -c "from inferscale.app import MODEL; from transformers import pipeline; pipeline('sentiment-analysis', model=MODEL)"
ENV HF_HUB_OFFLINE=1

# 4. Run as a normal user, not root
RUN useradd --uid 10001 --no-create-home app
USER app

EXPOSE 8000
# the model needs up to a minute to load, so the first checks may fail
HEALTHCHECK --interval=10s --timeout=5s --start-period=120s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=4)"
CMD ["inferscale", "serve", "--host", "0.0.0.0"]
