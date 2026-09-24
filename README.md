# shabbir04

*  Accounts: [Piazza account post](https://piazza.com/class/mt5rkdsycb31c3/post/24)

Note:
*  put files in `<repor>/assignments/week3/`

## Week 5

* [ ] Assignment W5.1: VMs via python (libcloud) (Due Oct 1, 2026, 9am)
  * [ ] Fork and clone <https://github.com/cloudmesh-ai/cloudmesh-ai-vm>, work on feature branches, submit PRs.
  * [ ] Cloud implementation: implement or improve commands for one or more providers (Local, OpenStack, or Hyperscalers).
  * [ ] Code understanding: Click CLI ↔ `clouds.yaml` ↔ provider interfaces.
  * [ ] Feature completeness: implement all mentioned commands across the selected clouds.
  * [ ] Validation: shell script (`verify_vm.sh`) showing success/failure of each command.
  * [ ] Collaboration: GitHub issues, PRs, peer review, Piazza.
  * [ ] Documentation: cloud-specific examples in the markdown docs.
  * [ ] Self-assessment: tasks completed, not completed, not understood, already done.

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
  * [v] Write a one‑paragraph explanation (4–6 sentences) on why backing up a computer is important. 
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


