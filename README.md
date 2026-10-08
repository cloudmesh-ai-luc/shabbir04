# shabbir04

*  Accounts: [Piazza account post](https://piazza.com/class/mt5rkdsycb31c3/post/24)

Note:
*  put files in `<repor>/assignments/week3/`

## Week 6

* [x] Assignment W6.1-5: VMs via Python (libcloud) (Due Oct 8, 2026, 9am)
  * [x] Continue the libcloud assignment.
  * [ ] Communicate in class.
  * [x] Use GitHub: fork [Shabbir04/cloudmesh-ai-vm](https://github.com/Shabbir04/cloudmesh-ai-vm), one feature branch per fix.
  * [x] Stay up to date with the latest commits (all branches based on `main` @ 8b727be, Oct 6).
  * [x] Use two providers: **Multipass** (local, macOS) and **Chameleon** (KVM@TACC).
  * [x] Smoke test for at least one provider: Multipass smoke tests fixed and passing (`tests/smoke/test_multipass_smoke.py`, `tests/smoke/test_cli_multipass.py`, `tests/smoke-class/test-multipass-with-credentials-class.py`).
  * [x] Adapt the smoke test to a second provider: new `tests/smoke/test_chameleon_smoke.py` (start, info, list, floating IP, run over SSH, stop, restart, delete), passes against KVM@TACC in ~56 s.
  * [x] Fix issues for each provider in separate, small, mergeable pull requests:
    * Multipass
      * [x] [#39](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/39) fix(multipass): restore `get_security_groups` (`cmx vm security-group list` crashed)
      * [x] [#40](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/40) fix(multipass): `delete_key` removes the key uploaded under that name
      * [x] [#41](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/41) test(multipass): use `key list` in CLI smoke test (`cmx vm keys` does not exist)
      * [x] [#42](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/42) fix(multipass): list images with `multipass find` (`cmx vm image` always empty)
      * [x] [#43](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/43) fix(multipass): `unshelve` starts the existing VM instead of launching a new one
    * Chameleon / OpenStack
      * [x] [#47](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/47) fix(openstack): strip `/v3` from `auth_url` (every libcloud call returned a Keystone 404)
      * [x] [#44](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/44) fix(openstack): use `_find_node` in `info`, `suspend`, `restart` (driver has no `get_node`)
      * [x] [#46](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/46) fix(openstack): read the floating IP from the libcloud node (`cmx vm run` found no IP)
      * [x] [#45](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/pull/45) test(chameleon): add real-cloud smoke test for KVM@TACC
  * [x] With all 9 PRs merged together: 97/98 unit tests pass (remaining failure is the existing WSL2 `test_list_parsing`), all Multipass and Chameleon smoke tests pass.
  * [x] Issues opened for problems that need a class decision before fixing:
    * [x] [#48](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/48) no command to attach a floating IP; `assign_floating_ip()` can take a classmate's free IP in a shared project
    * [x] [#49](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/49) `cmx vm start <name>` cannot power on a stopped VM ("already exists")
    * [x] [#50](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/50) generated VM names fall back to `user-N` instead of the login name
  * [x] Commented on a classmate's issue: [#37](https://github.com/cloudmesh-ai/cloudmesh-ai-vm/issues/37#issuecomment-6049958904) (Jetstream flavor 404 is likely the `/v3` bug fixed in #47).
  * [x] Other findings, not reported yet:
    * Unit tests write into the real `~/.config/cloudmesh/clouds.yaml`.
    * `tests/unit/test_vm.py` imports the missing `cloudmesh.ai.cmc`; `ChameleonManager.py` fails to import (`List` not imported) but is unused by the CLI.
    * Creating Chameleon leases through the API (CLI, python-chi) returns HTTP 500; leases were created in the dashboard.
  * [x] All test resources cleaned up (VMs, floating IPs, lease).

### Self-assessment (Week 6)

**What I got done.** Week 6 asked for two providers, so I used Multipass on my Mac and Chameleon (KVM@TACC). For Multipass, the smoke tests already existed but failed. After the fixes in #39 to #43, all three Multipass smoke test files pass. For Chameleon I adapted the smoke test pattern into a new one (#45). It runs start, info, list, floating IP, `run` over SSH, stop, restart and delete, and it passes in about a minute. Getting there took three fixes: the `/v3` login bug (#47), the `get_node` crash (#44) and the floating IP lookup (#46). Each fix is its own small PR, and all 9 merge cleanly together. I also opened issues #48 to #50 for things that need a decision first, and pointed AnieWall's issue #37 to #47 because it had the same 404.

**What I didn't finish.**
* I still need to talk about this in class or on Piazza.
* I only had time for two providers. I didn't try a third.
* The Chameleon smoke test can't make its own lease, because the lease API fails for me (see Week 5). You have to create the lease in the dashboard first and pass its flavor in `CHAMELEON_FLAVOR`.
* One finding isn't reported yet: the unit tests write into my real `~/.config/cloudmesh/clouds.yaml`.

**What I didn't understand.** I'm not sure how `shelve` is supposed to work on a local provider. Multipass has no real shelve, so the code just stops the VM. I left it that way.

**What was already done.** Someone had already noted the misspelled `security_groups` and `ssh_config` commands in the Chameleon CLI test, so I didn't redo that. My new smoke test is a separate file.

## Week 5

* [ ] Assignment W5.1: VMs via python (libcloud) (Due Oct 1, 2026, 9am)
  * [x] Fork and clone <https://github.com/cloudmesh-ai/cloudmesh-ai-vm>, work on feature branches, submit PRs (9 PRs, see Week 6).
  * [x] Cloud implementation: improve commands for Multipass (unshelve, image, security-group, key delete) and OpenStack/Chameleon (auth, info, suspend, restart, run).
  * [x] Code understanding: Click CLI ↔ `clouds.yaml` ↔ provider interfaces.
  * [ ] Feature completeness: implement all mentioned commands across the selected clouds.
  * [ ] Validation: shell script (`verify_vm.sh`) showing success/failure of each command.
  * [ ] Collaboration: GitHub issues, PRs, peer review, Piazza (9 PRs, 3 issues and 1 comment done; no PR reviews yet).
  * [ ] Documentation: cloud-specific examples in the markdown docs.
  * [x] Self-assessment: tasks completed, not completed, not understood, already done (see below).

### Self-assessment (Week 5)

**What I got done.** I forked and cloned `cloudmesh-ai-vm` and worked on a separate branch for each change. I learned how the pieces fit: click commands in `command/vm/`, settings from `~/.config/cloudmesh/clouds.yaml` (plus `~/.config/openstack/clouds.yaml` for credentials), and one provider class per cloud. The providers I worked on were Multipass and Chameleon. On Multipass, `unshelve`, `image`, `security-group list` and key delete were broken. On Chameleon nothing worked at first, not even listing images, because of a 404 at login. All of these are fixed in PRs (see Week 6).

**What I didn't finish.**
* I didn't use `verify_vm.sh`. I used the pytest smoke tests instead.
* Not every command works yet. There's no command to attach a floating IP, and `cmx vm start` can't power a stopped VM back on. These change the CLI for every provider, and the assignment says to discuss new commands first, so I opened issues #48 and #49 instead of changing them.
* I didn't add provider examples to the docs.
* I haven't reviewed anyone else's PR yet.
* I was late. My PRs went in on Oct 7, after the Oct 1 deadline.

**What I didn't understand.** Creating a Chameleon lease through the API fails with HTTP 500, both with the `openstack` CLI and with python-chi. The same lease works fine in the dashboard. I still don't know why, so I made my leases in the dashboard.

**What was already done.** I had fixed a startup crash on Sep 29 but never submitted it. When I came back, `main` already had the fix, so I deleted my branch.

## Week 4

* [x] Assignment W4.1: VM on local machine via Makefile (Due Sep 24, 2026, 9am)
  * [x] Pick a local VM framework and install it (Multipass).
  * [x] Write a Makefile with all the targets needed to manage a single VM.
  * [x] Can you manage multiple machines? How.
  * [x] How do you organize Makefiles for different local and cloud environments (directories).
  * [x] [local/](https://github.com/cloudmesh-ai-luc/shabbir04/tree/main/assignments/week4/local)

* [x] Assignment W4.2: VM on Jetstream 2 (Due Sep 24, 2026, 9am)
  * [x] Install the openstack commandline client.
  * [x] Write a Makefile with all the targets needed to manage a single VM.
  * [x] Can you manage multiple machines?
  * [x] Check it into your repository. [jetstream/](https://github.com/cloudmesh-ai-luc/shabbir04/tree/main/assignments/week4/jetstream)

* [x] Assignment W4.3: VM on Chameleon Cloud (Due Sep 24, 2026, 9am)
  * [x] Install the openstack commandline client.
  * [x] Install python-chi.
  * [x] Write a Makefile with all the targets needed to manage a single VM.
  * [x] Can you manage multiple machines?
  * [x] Check it into your repository. [chameleon/](https://github.com/cloudmesh-ai-luc/shabbir04/tree/main/assignments/week4/chameleon)
  * [x] Other: tested on KVM@TACC (create, ssh, stop/start, clean). Lease creation via the API returns HTTP 500, so the lease was made in the dashboard (documented in the README).

* [x] Assignment W4.4: Review Python (Due Sep 24, 2026, 9am)
  * [x] Set up a python virtual environment (venv, not conda).
  * [x] Using pip install and pipx install.
  * [x] Import statements; program using `os.system("ls")`.
  * [x] Create a `__main__`.
  * [x] Write a function.
  * [x] Pass arguments from the commandline (click).
  * [x] Run shell commands from python (`os.system()`, `subprocess.run()`).
  * [x] [python/](https://github.com/cloudmesh-ai-luc/shabbir04/tree/main/assignments/week4/python)

* [x] Every week: update the `README.md` with the list of assignments posted each week.

## Week 3

* [x] Assignment W3.1: VM on Jetstream (Due Sep 17, 2026, 9am)
  * [x] Start a VM on Jetstream and follow the tutorial provided.
  * [x] Improve the tutorial while creating pull requests in the lecture notes if you see issues.
  * [x] Document your activity with a screenshot of the terminal (800x600).
  * [x] [Comparing VM Creation.md](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/assignments/week3/Comparing%20VM%20Creation.md), [jetstream.png](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/assignments/week3/jetstream.png)


* [x] Assignment W3.2: VM on Chameleon Cloud (Due Sep 17, 2026, 9am)
  * [x] Set your preferred time zone in Chameleon settings.
  * [x] Make sure you have a key in your `.ssh` dir on your laptop and upload the public key to Chameleon.
  * [x] Explore the portal and browse around to develop a plan first.
  * [x] Make a reservation not exceeding 1 hour.
  * [x] Start up a VM using a Chameleon Cloud image for Ubuntu 24.04 using the smallest image size possible.
  * [x] Document your activity with a screenshot of the terminal (800x600).
  * [x] [Comparing VM Creation.md](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/assignments/week3/Comparing%20VM%20Creation.md), [chameleon.png](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/assignments/week3/chameleon.png)


* [ ] Assignment W3.3: OPTIONAL: VM on public cloud (Due Sep 17, 2026, 9am)
  * [ ] Optional: Create a VM on a cloud of your choice (AWS, Azure, Google) using the free tier.
  * [ ] Document with screenshots how you created your account, ensuring sensitive information is blurred out.
  * [ ] Not done (optional)


* [x] Assignment W3.4: Compare (Due Sep 17, 2026, 9am)
  * [x] Compare your experience between starting a VM on your local machine vs using Chameleon Cloud.
  * [x] Put all assignment answers into `assignments/week3/`. [Comparing VM Creation.md](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/assignments/week3/Comparing%20VM%20Creation.md)
  * [x] [Comparing VM Creation.md](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/assignments/week3/Comparing%20VM%20Creation.md)
     
* [x] Assignment W3.5: README.md (Due Sep 17, 2026, 9am)
  * [x] [README.md](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/README.md)
     
 * [x] Assignment W3.6 git from commandline
   * [x] put the url of a pull request here

## Week 2
  
* [x] Assignment W2.1: Google Account, Piazza Account post cleanup (Due Sep 10, 2026, 9am)
  * [x] Locate your account post in Piazza and add your google account.
  * [x] Correct your Chameleon ID to the registered email.
  * [x] Fix your subject line to `Firstname Lastname (lucid@luc.edu)`.


* [x] Assignment W2.2: GitHub Repository (Due Sep 10, 2026, 9am)
  * [x] Verify that you can write into a file in your assigned GitHub repository.
  * [x] Put something useful into the README such as your first and last name. [README.md](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/README.md)
  * [x] Upload your public key. [Shabbir04.keys](https://github.com/Shabbir04.keys)


* [x] Assignment W2.3: Backup Your Computer (Due Sep 10, 2026, 9am)
  * [x] Write a one‑paragraph explanation (4–6 sentences) on why backing up a computer is important. 
  * [x] List three real‑world consequences of not having a backup.
  * [x] Choose one backup method and outline the setup steps.
  * [x] Create a weekly backup schedule (day, time, what to back up).
  * [x] Research an example from cloud computing where a missing backup strategy led to issues and write a short incident case.
  * [x] Submit to `/assignments/week2/`. [Backup.md](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/assignments/week2/Backup.md)


* [x] Assignment W2.4: Local VM (Due Sep 10, 2026, 9am)
  * [x] Windows: Install a terminal on Windows (Git Bash/WSL). macOS (not Windows)
  * [x] Pick a hypervisor (VirtualBox, VMware, Hyper-V, Multipass). Multipass
  * [x] Create and start a minimal VM (e.g., Ubuntu 22.04).
  * [x] Capture proof of login with a terminal screenshot (≤ 800×600 px) showing your prompt and a command.
  * [x] Write/update the tutorial in `assignments/week1/local-vm.md` and save the screenshot as `assignments/week1/vm-login.png`. [local-vm.md](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/assignments/week1/local-vm.md), [local-vm.png](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/assignments/week1/local-vm.png)


* [x] Assignment W2.5: Project proposal (Due Sep 10, 2026, 9am)
  * [x] Start working towards a project proposal and fill out administrative fields and text. [project.md](https://github.com/cloudmesh-ai-luc/shabbir04/blob/main/project.md)


# Week 1

  * [x] Assignment W1.1: What hardware do you have? (Past Due) [LINK]
  * [x] Fill out the LUC Hardware Questionnaire.


* [x] Assignment W1.2: Lecture review (Past Due)
  * [x] Review all sections under LECTURES -> INTRODUCTIONS and post questions on Piazza.


* [x] Assignment W1.3: Look over the assignment sections (Past Due)
  * [x] Review all sections under ASSIGNMENTS (Overview and weekly sections).


* [x] Assignment W1.4: Create class accounts (Past Due)
  * [x] Create an account on access-ci.org.
  * [x] Create an account on chameleoncloud.org.
  * [x] Set up a GitHub account.
  * [x] Post account information to Piazza under the accounts category. [Piazza post](https://piazza.com/class/mt5rkdsycb31c3/post/24)


* [x] Assignment W1.5: Work ahead: Refresh knowledge about Python and Linux (Past Due)
  * [x] Review optional material in the class documentation.


* [x] Assignment W1.6: Improve the Web Site (Past Due)
  * [x] Update errors or notify instructors throughout the semester.


