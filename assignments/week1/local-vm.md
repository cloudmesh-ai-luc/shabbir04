# Local VM Setup Tutorial (macOS + Multipass)

This guide walks through setting up a lightweight local virtual machine on macOS using Multipass, logging into it, and verifying it works.

## 1. Prerequisites

- A Mac (Apple Silicon or Intel) with at least ~5 GB of free disk space.
- Terminal (built into macOS) — no separate shell installation is needed, since macOS already ships with a usable Unix shell.
- [Homebrew](https://brew.sh) package manager. Install it if it isn't already present:

  ```
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

## 2. Installing the Hypervisor

This tutorial uses **Multipass**, a lightweight CLI-based VM manager built by Canonical. It avoids the GUI wizard steps required by heavier hypervisors and works well on both Apple Silicon and Intel Macs.

```
brew install --cask multipass
```

Verify the install:

```
multipass version
```

## 3. Creating and Logging Into the VM

Launch a minimal Ubuntu 22.04 instance:

```
multipass launch 22.04 --name cs388-vm --cpus 2 --memory 2G --disk 10G
```

Confirm the instance is running:

```
multipass list
```

Log in to the VM:

```
multipass shell cs388-vm
```

Once inside, run a command to confirm the shell is live:

```
uname -a
```

or

```
ls -la
```

Exit the VM when finished:

```
exit
```

Stop the instance to free up resources (optional):

```
multipass stop cs388-vm
```

## 4. Screenshot

See `vm-login.png` in this same folder — it shows the `username@hostname` prompt inside the VM along with the output of a verification command, captured at 800x600 px or smaller.

`![VM login screenshot](vm-login.png)`

## 5. System-Specific Quirks

- On Apple Silicon Macs, Multipass automatically pulls an ARM64 Ubuntu image, so command output (e.g., `uname -a`) will show `aarch64` rather than `x86_64` — this is expected and not an error.
- The first `multipass launch` can take a few minutes since it downloads the base cloud image; subsequent launches of the same version are much faster.
- If `brew install --cask multipass` fails with a permissions error, running `sudo xattr -rd com.apple.quarantine /Applications/Multipass.app` after installation has resolved similar issues for other Multipass users on macOS.

## 6. Contributing

Multipass and VirtualBox aren't the only valid options for this assignment — VMware Fusion/Player, Hyper-V (Windows only), and other hypervisors work too. If a gap or error turns up in this guide, or a more current version of these steps is found, opening a pull request against this repository with the fix is the right move rather than rewriting the tutorial from scratch. Keep the same six-section structure (prerequisites, installation, creation/login, screenshot, quirks, contributing) so future students can follow the same pattern.
