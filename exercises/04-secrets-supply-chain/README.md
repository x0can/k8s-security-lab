# Exercise 04 — Secrets & supply chain

**Goal:** stop leaking credentials in manifests and stop trusting mutable
images.

**Time:** ~30 min · **Difficulty:** ⭐⭐ intermediate

---

## Background

Two common, high-impact mistakes:

**Secret handling**
- Credentials hard-coded as `env.value` or `args` end up in git, in
  `kubectl get -o yaml`, in backups, and in node process listings.
- Fix: put them in a `Secret` and reference it with `envFrom.secretRef` or
  `valueFrom.secretKeyRef`.
- ⚠️ A Kubernetes `Secret` is only **base64-encoded**, not encrypted. For real
  systems use encryption at rest + an external store (see below).

**Supply chain**
- `:latest` (or any mutable tag) means the image running today may not be the
  one you reviewed. Pin a specific tag, ideally by **digest** (`@sha256:...`).
- Set `imagePullPolicy` deliberately.

---

## Tasks

1. **Find the leaks:**
   ```bash
   kube-linter lint vulnerable/deployment.yaml
   grep -nE "value:|--token" vulnerable/deployment.yaml
   ```
   List every secret exposed and every supply-chain weakness.

2. **Create a Secret** instead of inlining values, and switch the workload to
   `envFrom`. Replace `:latest` with a pinned tag.

3. **Verify the raw values are gone** from the workload:
   ```bash
   kubectl apply -f hardened/deployment.yaml
   kubectl get deploy payments -n lab-baseline -o yaml | grep -i password
   # -> no plaintext password in the Deployment
   ```

4. **Compare** with [`hardened/deployment.yaml`](hardened/deployment.yaml).

---

## Going further (production)

- **Encrypt Secrets at rest** with a KMS provider (GKE does this by default with
  Cloud KMS).
- **External secret stores:** External Secrets Operator, HashiCorp Vault, or GKE
  + Secret Manager via Workload Identity — the cluster never stores the raw
  secret.
- **Sealed Secrets** so encrypted secrets can live safely in git.
- **Image provenance:** sign images (cosign) and enforce signatures with Binary
  Authorization (GKE) or a policy controller (Kyverno/Gatekeeper).

---

## Checkpoint questions

- Why is base64 in a `Secret` not a security control?
- Why is pinning by digest stronger than pinning by tag?
- Where else, besides the manifest, could the hard-coded password have leaked?

## Solution

See [`hardened/deployment.yaml`](hardened/deployment.yaml) — credentials moved to
a `Secret` and referenced via `envFrom`, image pinned, non-root, read-only root
filesystem.
