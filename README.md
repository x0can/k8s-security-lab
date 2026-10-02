# Kubernetes Security Lab

A hands-on, self-contained lab for learning to **find and fix common Kubernetes
misconfigurations**. Built for classroom use — it runs on a free local
[kind](https://kind.sigs.k8s.io/) cluster on any laptop with Docker, and every
exercise maps to its **GKE** equivalent so the skills transfer to a real cloud
cluster.

This lab is **defensive**. Each exercise ships an intentionally weak manifest, a
set of tasks to identify *why* it is weak, and a hardened version to compare
against. You harden workloads; you do not attack other people's clusters.

> Author: Xocan (Alex Mwaura) · Built for the Moringa School cybersecurity curriculum.

---

## What you'll practice

| # | Exercise | Core concepts |
|---|----------|---------------|
| 01 | [Pod Security](exercises/01-pod-security/) | `securityContext`, root vs non-root, privilege escalation, capabilities, read-only root FS, Pod Security Standards (`restricted`) |
| 02 | [RBAC](exercises/02-rbac/) | Least privilege, `Role` vs `ClusterRole`, wildcard verbs, dangerous `escalate`/`bind`/`impersonate`, ServiceAccount hygiene |
| 03 | [Network Policy](exercises/03-network-policy/) | Default-deny, namespace isolation, ingress/egress rules, blast-radius reduction |
| 04 | [Secrets & Supply Chain](exercises/04-secrets-supply-chain/) | Secrets vs ConfigMaps, image tags vs digests, `imagePullPolicy`, no secrets in env/args, provenance |

Each folder contains: `README.md` (the lab steps), `vulnerable/` (what *not* to
ship), and `hardened/` (the fix).

---

## Prerequisites

- Docker (or Podman) running locally
- [`kind`](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) ≥ 0.24
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) ≥ 1.30
- Optional but recommended static scanners:
  - [`kube-linter`](https://github.com/stackrox/kube-linter) — catches insecure manifests
  - [`kubeconform`](https://github.com/yannh/kubeconform) — schema validation

A one-shot installer for the two scanners is in
[`scripts/install-tools.sh`](scripts/install-tools.sh).

---

## Quick start

```bash
# 1. Create the lab cluster (3 namespaces, Pod Security admission enabled)
./scripts/setup.sh

# 2. Statically scan every manifest before you even apply it
./scripts/scan.sh

# 3. Work through the exercises in order
cd exercises/01-pod-security && cat README.md

# 4. Tear everything down when done
./scripts/teardown.sh
```

No Docker? You can still do the **entire lab statically** — `./scripts/scan.sh`
runs `kube-linter` and `kubeconform` against the YAML without a cluster, which is
how most misconfigurations are caught in a real CI pipeline anyway.

---

## How to use this in a class

- **Self-paced:** read each exercise README, try the tasks, then diff your fix
  against `hardened/`.
- **Instructor-led:** apply the `vulnerable/` manifest live, run `kube-linter`,
  and walk the class through each finding before revealing the fix.
- **Assessment:** hand out only the `vulnerable/` manifests and the task list;
  students submit a hardened manifest that passes `./scripts/scan.sh`.

See [docs/INSTRUCTOR-NOTES.md](docs/INSTRUCTOR-NOTES.md) for timing, grading
rubric, and discussion prompts.

---

## Repository layout

```
k8s-security-lab/
├── cluster/                 # kind cluster config + Pod Security namespace labels
├── exercises/
│   ├── 01-pod-security/
│   ├── 02-rbac/
│   ├── 03-network-policy/
│   └── 04-secrets-supply-chain/
├── scripts/                 # setup / scan / teardown / install-tools
├── docs/                    # cheatsheet, instructor notes, GKE mapping
└── .github/workflows/       # CI that scans manifests on every push
```

---

## GKE mapping

Everything here runs locally, but the concepts are cloud-portable. See
[docs/GKE-MAPPING.md](docs/GKE-MAPPING.md) for how each exercise lines up with
GKE features (Workload Identity, GKE-native Network Policy, Binary
Authorization, Shielded Nodes, Autopilot's built-in restrictions).

---

## License

[MIT](LICENSE) — free to use and adapt for teaching.

## A note on scope

This repository contains only misconfigured-but-inert manifests for learning to
*harden* workloads. It contains no exploit code and no tooling for attacking
systems you don't own. Only run it against clusters you control.
