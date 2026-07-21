# kpatch + OpenSCAP Demo — Design Record

Every decision that shaped this demo is documented here.
Future contributors: read this before changing anything.

---

## The Story We're Telling

> A published CVE affects this RHEL kernel. We patch it live — no reboot,
> no change window, no downtime. A compliance scanner confirms it before
> and after. SAP HANA (if installed) never stops running.

Two minutes. One box. The security and operations story in a single demo.

---

## Architecture Decisions

### Decision 1: Single-box demo

**What:** The demo runs on one RHEL 9 host. SAP HANA is optional.

**Why:** The original design used two HANA nodes + one S/4HANA node from the
RHDP CNV environment. This caused weeks of instability:
- OpenShift Virtualization (CNV/KubeVirt) is not SAP-certified for production
- CNV-specific kernel behavior caused hana-sdmhr1 to crash-loop on kernel 5.14.0-570.39.1
- Satellite mTLS was broken in the demo environment (Katello CA vs CDN CA mismatch)
- Environment auto-stop cycles reset VM state mid-playbook

A single RHEL 9 box on any SAP-supported substrate (EC2, bare metal, Azure VM)
is stable, customer-realistic, and easier to reset between demo runs.

The HANA process check in 06-kpatch-verify.yml is conditional — the core
kpatch story does not depend on HANA being installed.

### Decision 2: Kernel 5.14.0-570.39.1.el9_6

**What:** Target kernel for the demo, not the RHDP-provisioned default.

**Why:** The RHDP CNV environment provisions RHEL 9.6 with kernel
5.14.0-570.123.1.el9_6. As of the demo build date, Red Hat has not published
kpatch-patch RPMs for that kernel. The kpatch-patch-5_14_0-570_39_1 package
exists and provides live patches for the 570.39.1 kernel.

When RHDP publishes kpatch-patch RPMs for 570.123+, this constraint goes away
and the demo can run on whatever kernel the environment provisions.

Track: https://access.redhat.com/security/updates/kernel (filter RHEL 9)

### Decision 3: CDN subscription, not demo Satellite

**What:** All hosts are pointed at Red Hat CDN for content, not the demo
Satellite (demosat-ha.infra.demo.redhat.com).

**Why:** The demo Satellite's mTLS is broken in the RHDP CNV environment.
After subscription-manager refresh, redhat.repo carries sslcacert pointing
to katello-server-ca.pem, which is self-signed and cannot validate cdn.redhat.com.
Additionally, the subscription-manager DNF plugin performs OCSP verification
on entitlement certs using the Satellite as the OCSP responder — which fails
when the baseurl points to CDN.

Fix applied in 98-reset-and-prep-kpatch-demo.yml:
- `subscription-manager config --server.hostname=subscription.rhsm.redhat.com`
- `--setopt=sslverify=0 --disableplugin=subscription-manager` on kernel install

Long-term fix: RHIS image with CDN baked in (see project_rhis_imagebuilder.md).

### Decision 4: oscap-oval eval, not full SCAP profile

**What:** OpenSCAP scans use targeted OVAL content for the specific kpatch RHSA,
not a full CIS/PCI-DSS profile scan.

**Why:**
- Full profile scans take 5-10 minutes; OVAL eval on a single RHSA takes seconds
- The demo story is specific: "this CVE, this patch, this proof"
- Targeted OVAL produces one clear FAIL → PASS transition
- Full profile scans produce hundreds of findings — noise drowns the signal

The kpatch-patch RPM is the installable artifact for the advisory. The OVAL
definition checks whether that RPM is installed. Before kpatch: FAIL.
After kpatch install (no reboot): PASS. That's the proof.

kpatch patches are cumulative per kernel slot — each new kpatch-patch build
for a slot includes all prior patches. Install once, all CVEs in the slot
are covered.

The RHEL 9.6 EUS OVAL file is ~1MB compressed (verified 2026-07-21).
Download time is negligible on any cloud VM.

### Decision 5: Modular playbook structure

**What:** Each capability is an independent, parameterized playbook.
Demos are compositions of modules via AAP workflows.

**Why:** Avoid duplicating kpatch logic in every demo that uses it.
OpenSCAP scanning is useful beyond the kpatch demo — it applies to
the OpenSCAP standalone demo, the compliance story, the JLR breach narrative.

Module contract:
- Each playbook is self-contained (installs what it needs)
- Standard variable names across all modules (see vars/ below)
- Idempotent: safe to run multiple times
- Fails loudly on real errors, skips gracefully on missing-but-expected state

---

## Module Inventory

| Playbook | Role | Inputs | Outputs |
|---|---|---|---|
| 98-reset-and-prep-kpatch-demo.yml | Get right kernel on box | kpatch_target_kernel | Host rebooted into target kernel |
| 05-kpatch-livepatch.yml | Apply live patches | target_group, kpatch_fail_if_none_loaded | kpatch modules loaded |
| 06-kpatch-verify.yml | Verify patches + optional HANA | hana_sid, hana_instance | Assert pass/fail |
| 07-oscap-scan.yml | Run OpenSCAP OVAL scan | scan_label, oval_url, target_group | HTML report fetched to controller |
| 08-reset-kpatch.yml | Remove kpatch packages | target_group | Host in pre-kpatch state |

---

## Standard Variable Names

```yaml
target_group: hanas          # Inventory group to target (all modules)
kpatch_target_kernel: "5.14.0-570.39.1.el9_6"
kpatch_oval_url: ""          # RHSA OVAL XML URL — set per-demo
scan_label: before           # Label for report files (before | after)
demo_report_dir: /tmp/oscap  # Where reports land on host
sap_hana_sid: RHE
sap_hana_instance_number: "00"
```

---

## Demo Flows

### Flow A: kpatch-only (no HANA, ~90 seconds)
1. `07-oscap-scan.yml -e scan_label=before` → FAIL
2. `05-kpatch-livepatch.yml`
3. `07-oscap-scan.yml -e scan_label=after` → PASS
4. Side-by-side: same kernel, no reboot, CVE gone

### Flow B: kpatch + HANA (full story, ~3 minutes)
Flow A + `HDB info` running throughout step 2.

### Flow C: OpenSCAP standalone
`07-oscap-scan.yml` with a full profile (e.g., stig, cis) — separate OVAL.

### Reset between runs
`08-reset-kpatch.yml` — removes kpatch packages, no reboot needed.

---

## Infrastructure Notes

- **RHDP catalog item:** openshift-cnv.sap-e2e-demo-rhel9-cnv.prod (sdmhr GUID)
- **Preferred target:** single EC2/Azure RHEL 9 instance (SAP-certified)
- **AAP project:** JimDemos/demo.sap_install (ID 22 in sdmhr AAP)
- **Lifespan:** RHDP environments expire — re-runnable IaC is the whole point
- **SAP + OCP Virt:** Not production-certified. CNV is a demo convenience only.
  Do NOT imply to customers that this is a supported production topology.
