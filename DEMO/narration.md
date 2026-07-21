# kpatch Security Demo — Narration Script

Full voiceover text. Read as written. Times are targets for pacing.

---

## Scene 0 — The Setup (~20s)

> "This Red Hat Enterprise Linux 9 server is running kernel version
> 5.14.0-570.39.1. Two published CVEs affect this kernel —
> CVE-2025-38052 and CVE-2025-38352. We're about to prove that we
> can patch both of them without stopping this system. No reboot.
> No change window. No downtime."

_[Show terminal: uname -r, uptime, kpatch not installed]_

---

## Act 1 — Compliance Scan, BEFORE (~45s)

> "Before we do anything, we run a compliance scan. We're using
> OpenSCAP with the official Red Hat OVAL definitions for this
> kernel's kpatch advisory. The scanner checks one thing: is the
> kpatch patch package installed? It isn't. So the result is fail."

_[AAP job '07 - OpenSCAP Scan' runs with scan_label=before]_
_[Pause on the job output — let it complete]_

> "Three CVEs. All failing. This system is exposed."

_[Open BEFORE report — hold on the red FAIL results]_

---

## Act 2 — Live Patch (~60s)

> "Now we apply the patch. Red Hat kpatch loads a kernel module
> that redirects the vulnerable code paths — in memory, in the
> kernel that's already running. Watch the uptime counter while this runs."

_[Show uptime in second pane — clock ticking up]_
_[AAP job '05 - Apply Live Kernel Patches' runs]_

> "The module is loading... and it's live."

_[Job completes — show kpatch list output]_

> "One kpatch module. Enabled. The kernel version hasn't changed.
> The uptime hasn't reset. This system never stopped."

---

## Act 3 — Verify (~30s)

> "Let's confirm the state of the system."

_[Run 06-kpatch-verify or manual commands]_

> "Same kernel. Continuous uptime. kpatch module enabled.
> And if SAP HANA is installed —"

_[Show HDB info output]_

> "— HANA is still running. Every process. No interruption."

---

## Act 4 — Compliance Scan, AFTER (~45s)

> "Same scanner. Same OVAL content. Same host. Let's run it again."

_[AAP job '07 - OpenSCAP Scan' runs with scan_label=after]_

> "The kpatch package is now installed. The OVAL definition sees it."

_[Open AFTER report]_

> "Three CVEs. All passing."

_[Put BEFORE and AFTER side by side — hold for 5 seconds]_

> "Red on the left — before. Green on the right — after.
> Same kernel version. Same uptime. No reboot required.
> The compliance scanner confirms: this system is no longer exposed."

---

## Total: ~2 minutes 20 seconds

---

## Recording Notes

**Layout:**
- Main terminal (left, large): AAP job output / live commands
- Top-right: kpatch list / uptime watch
- Bottom-right: OpenSCAP report (toggle before/after)

**Setup before recording:**
```bash
bash DEMO/setup-recording.sh
```

**Voice direction:**
- Confident. Not breathless. Let the terminal output breathe.
- Pause 2-3 seconds after each `PASS` or `FAIL` appears.
- The side-by-side at the end: say nothing for 3 seconds. Let the image land.
