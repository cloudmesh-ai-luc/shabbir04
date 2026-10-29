"""InferScale: one ML inference service on three clouds with cmx vm."""
from importlib.metadata import PackageNotFoundError, version

try:
    __version__ = version("inferscale")
except PackageNotFoundError:  # running from a source tree that is not installed
    __version__ = "0.0.0"
