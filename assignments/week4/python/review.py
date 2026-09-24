#!/usr/bin/env python3
"""W4.4 Python review: imports, functions, main, CLI arguments, shell commands.

    python review.py ls [PATH]
    python review.py run "COMMAND"
    python review.py greet NAME [--count N] [--shout]
"""
import os
import shlex
import subprocess

import click


def greeting(name, shout=False):
    """Return a greeting for name."""
    text = f"Hello, {name}!"
    return text.upper() if shout else text


def run_command(command):
    """Run a shell command with subprocess.run and return (exit code, stdout)."""
    result = subprocess.run(shlex.split(command), capture_output=True, text=True)
    return result.returncode, result.stdout.strip()


@click.group()
def cli():
    """Small CLI for reviewing Python basics."""


@cli.command()
@click.argument("path", default=".")
def ls(path):
    """List PATH with os.system("ls")."""
    exit_code = os.system(f"ls {shlex.quote(path)}")
    click.echo(f"os.system exit code: {exit_code}")


@cli.command()
@click.argument("command")
def run(command):
    """Run COMMAND with subprocess.run and capture its output."""
    code, output = run_command(command)
    click.echo(output)
    click.echo(f"subprocess.run exit code: {code}")


@cli.command()
@click.argument("name")
@click.option("--count", default=1, show_default=True, help="How many times to greet.")
@click.option("--shout", is_flag=True, help="Uppercase the greeting.")
def greet(name, count, shout):
    """Greet NAME, COUNT times."""
    for _ in range(count):
        click.echo(greeting(name, shout))


def main():
    cli()


if __name__ == "__main__":
    main()
