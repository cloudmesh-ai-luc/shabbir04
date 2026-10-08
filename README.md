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
  * [x] Other (findings for class discussion, not fixed):
    * `assign_floating_ip()` takes the first free floating IP in the project, which can be a classmate's in a shared project; no `cmx` command assigns a floating IP.
    * `cmx vm start <name>` cannot power on a stopped VM ("already exists").
    * Generated VM names are `user-N` instead of the user's name, so they can clash in a shared project.
    * Unit tests write into the real `~/.config/cloudmesh/clouds.yaml`.
    * `tests/unit/test_vm.py` imports the missing `cloudmesh.ai.cmc`; `ChameleonManager.py` fails to import (`List` not imported) but is unused by the CLI.
    * Creating Chameleon leases through the API (CLI, python-chi) returns HTTP 500; leases were created in the dashboard.
  * [x] All test resources cleaned up (VMs, floating IPs, lease).

### Self-assessment (Weeks 5 and 6)

I did Weeks 5 and 6 together with Claude Code, an AI coding assistant. Claude ran the tests, tracked down the bugs and wrote most of the fixes. I picked the two providers, set up my Chameleon credentials and leases, and opened the pull requests from my account. Every commit lists Claude as co-author.

**What I got done.** I started with Multipass on my Mac. Five things were broken, and they're fixed in PRs #39 to #43. All the Multipass smoke tests pass now. Chameleon was worse at first. Nothing worked, not even listing images. The reason turned out to be small: the `auth_url` in `clouds.yaml` ends in `/v3`, and libcloud adds its own `/v3`, so every call got a 404 (#47). After that fix, `info`, `suspend` and `restart` crashed (#44), and `run` couldn't find the public IP (#46). I also wrote a Chameleon smoke test (#45). It passes on KVM@TACC in about a minute and cleans up after itself.

**What I didn't finish.**
* I didn't use `verify_vm.sh`. I used the pytest smoke tests instead.
* Not every command works yet. There's no command to attach a floating IP, and `cmx vm start` can't power a stopped VM back on. I didn't fix these because they change the CLI for every provider, and the assignment says to discuss new commands on Piazza first.
* I didn't add provider examples to the docs.
* I haven't opened GitHub issues or reviewed anyone else's PR yet.
* Week 5 was late. My PRs went in on Oct 7, after the Oct 1 deadline.

**What I didn't understand.** Creating a Chameleon lease through the API fails with HTTP 500, both with the `openstack` CLI and with python-chi. The same lease works fine in the dashboard. I still don't know why, so I made my leases in the dashboard.

**What was already done.** I had fixed a startup crash on Sep 29 but never submitted it. When I came back, `main` already had the fix, so I deleted my branch. Also, the misspelled `security_groups` and `ssh_config` commands in the Chameleon CLI test had already been found by a classmate (it's noted in that test file).

## Week 5

* [ ] Assignment W5.1: VMs via python (libcloud) (Due Oct 1, 2026, 9am)
  * [x] Fork and clone <https://github.com/cloudmesh-ai/cloudmesh-ai-vm>, work on feature branches, submit PRs (9 PRs, see Week 6).
  * [x] Cloud implementation: improve commands for Multipass (unshelve, image, security-group, key delete) and OpenStack/Chameleon (auth, info, suspend, restart, run).
  * [x] Code understanding: Click CLI ↔ `clouds.yaml` ↔ provider interfaces.
  * [ ] Feature completeness: implement all mentioned commands across the selected clouds.
  * [ ] Validation: shell script (`verify_vm.sh`) showing success/failure of each command.
  * [ ] Collaboration: GitHub issues, PRs, peer review, Piazza (PRs done).
  * [ ] Documentation: cloud-specific examples in the markdown docs.
  * [x] Self-assessment: tasks completed, not completed, not understood, already done (see Self-assessment under Week 6).

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


