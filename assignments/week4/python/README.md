# Assignment W4.4: Review Python

## 1. Virtual environment (venv, not conda)
* Used the built-in `venv` module with the system Python (`/usr/bin/python3`, 3.9.6), not Anaconda. Conda downloads many libraries this project doesn't need and can cause low-level conflicts.
* The environment lives in `.venv/`, which is git-ignored.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 2. pip vs pipx
| Tool | Installs into | Used for |
|---|---|---|
| `pip install click` | The active venv | Libraries a program imports (`click` here) |
| `pipx install python-openstackclient` | Its own isolated venv, with the command put on `PATH` | Command-line apps such as the OpenStack client (installed with pipx, as required) |

`pipx inject python-openstackclient python-blazarclient` adds a plugin to that app's venv (used in W4.3).

## 3–6. Imports, functions, main, and command-line arguments
All of these are in [`review.py`](review.py):

| Topic | Where |
|---|---|
| Import statements | `import os`, `import subprocess`, `import shlex`, `import click` |
| `os.system("ls")` | `ls` command |
| Functions | `greeting()`, `run_command()` |
| main | `def main()` plus `if __name__ == "__main__": main()` |
| Command-line arguments | `click`: `@click.argument` for positional values, `@click.option` for flags (`--count`, `--shout`) |
| Shell commands | `os.system()` in `ls`, `subprocess.run()` in `run` |

**click vs argparse:** with click, the function's parameters *are* the CLI arguments. The decorators turn `greet(name, count, shout)` into `greet NAME --count N --shout` and generate `--help` automatically.

## 7. Running shell commands from Python
* `os.system(cmd)` runs `cmd` in a shell. The output goes straight to the terminal, and you only get the exit code back.
* `subprocess.run(args, capture_output=True, text=True)` returns an object with `returncode`, `stdout` and `stderr`. It's the better choice when the program needs the output. Passing a list (via `shlex.split`) avoids shell-injection problems.

## Example run
```
$ python review.py ls .
requirements.txt
review.py
os.system exit code: 0

$ python review.py run "echo hello from subprocess"
hello from subprocess
subprocess.run exit code: 0

$ python review.py greet Shabbir --count 2 --shout
HELLO, SHABBIR!
HELLO, SHABBIR!
```
