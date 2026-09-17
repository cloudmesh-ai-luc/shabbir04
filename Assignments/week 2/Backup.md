# Week 2 Assignment: Backing Up the Computer

## a. Why Backing Up Matters

Coursework, personal projects, and configuration files represent hours of effort that live only on one machine unless a second copy exists somewhere else. A dropped laptop, a failed hard drive, a stray virus, or even an accidental "delete" on the wrong folder can erase that effort instantly, and none of those events give advance warning. For a computer science student juggling cloud computing labs, VM setups, and GitHub-based team projects, losing local files often means losing work that took multiple sessions to configure correctly, not just a single document. A backup acts like a reset button: instead of starting over from nothing, a recent copy makes it possible to restore the machine to a known-good state within minutes. Given how often assignments, VM images, and code repositories change week to week in this course, skipping backups isn't really saving time — it's just deferring a much bigger time cost to whatever week the drive happens to fail.

## b. Real-World Consequences (Personal)

1. Losing an in-progress VM configuration built for this exact course (Assignment W2.4) would mean redoing hours of hypervisor setup, installation, and testing right before a deadline.
2. A corrupted or wiped repository clone before changes get pushed to GitHub would erase uncommitted coursework with no way to recover it, since GitHub only holds what was actually pushed.
3. Recovering a failed drive through a data-recovery service can run into the hundreds of dollars, an expense that hits harder as a grad student already managing tuition and coursework costs.

## c. Chosen Backup Method

Time Machine — the backup tool built into macOS — is a practical choice here since it runs in the background with almost no ongoing maintenance once configured.

Setup steps:

1. Connect an external drive with enough free space (ideally at least 2-3x the size of the data being backed up) and format it as APFS or Mac OS Extended if it isn't already.
2. Open System Settings, go to General, then Time Machine.
3. Click "Add Backup Disk" and select the connected external drive.
4. Turn on "Back Up Automatically" so the system keeps hourly, daily, and weekly snapshots without manual intervention.
5. Optionally enable encryption on the backup disk for extra protection if the drive is ever lost or stolen.

## d. Weekly Backup Schedule

Every Sunday at 9:00 PM, a full Time Machine backup runs covering the entire system — documents, coursework folders, VM images, and local repository clones. On top of that, any code touched during the week gets pushed to GitHub daily, so the most recent work is never sitting only on the local machine between weekly backups.

## e. Real-World Consequences (Cloud Computing Incident)

A strong recent example comes from Nine PBS in St. Louis, which lost access to more than 50 terabytes of archival footage — spanning roughly 70 years of programming — after its cloud storage vendor, Open Source Storage, abruptly went out of business in 2026 ([Tom's Hardware](https://www.tomshardware.com/software/cloud-storage/nine-pbs-loses-access-to-70-years-of-data-after-contracted-cloud-storage-vendor-goes-defunct-public-tv-channel-sues-iron-mountain-data-center-which-hosts-archival-materials-to-ensure-preservation), [byteiota](https://byteiota.com/cloud-vendor-lock-in-erased-nine-pbss-70-year-archive/)). The station's contract lapsed, the vendor stopped responding, and access was cut off even though the underlying data still physically existed on servers at an Iron Mountain facility — the problem was custody, not corruption, since Nine PBS had no direct contract with the company actually holding the hardware ([Firevault](https://fire-vault.com/news/nine-pbs-archives-cloud-vendor-shutdown-2026)).

This incident could likely have been avoided by following the 3-2-1 backup rule with one added condition: keeping at least one copy fully outside the vendor's chain of custody, accessible without that vendor's cooperation. Analysts covering the story pointed out that backing up cloud data inside the same cloud environment produces extra copies, not real protection, since all of them can vanish together if the vendor relationship collapses ([byteiota](https://byteiota.com/cloud-vendor-lock-in-erased-nine-pbss-70-year-archive/)). A contract clause guaranteeing data portability and export rights before termination, paired with an independently held archive copy, would have given the station a way to retrieve its footage without depending on a vendor that had already gone dark.
