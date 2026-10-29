"""Command line for InferScale: `inferscale serve` starts the API."""
import click
import uvicorn

from inferscale import __version__


@click.group()
@click.version_option(__version__, prog_name="inferscale")
def cli():
    """InferScale: one ML inference service on three clouds."""


@cli.command()
@click.option("--host", default="127.0.0.1", show_default=True, help="Use 0.0.0.0 inside the container.")
@click.option("--port", default=8000, show_default=True)
def serve(host, port):
    """Start the API (FastAPI + DistilBERT). Needs `make install-model`."""
    uvicorn.run("inferscale.app:app", host=host, port=port)
