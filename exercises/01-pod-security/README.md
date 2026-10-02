# Exercise 01 — Pod Security

**Goal:** recognise the container-level settings that give a workload more power
than it needs, and harden a pod until it passes the Pod Security Standards
`restricted` profile.

**Time:** ~30 min · **Difficulty:** ⭐ beginner

---

## Background

A container is just a process on the node with some isolation. Weak settings
remove that isolation, so a single app bug can become node or cluster
compromise. The levers that matter most:

| Setting | Weak | Hardened |
|---------|------|----------|
| `runAsNonRoot` / `runAsUser` | root (0) | non-root (e.g. 10001) |
| `privileged` | `true` | `false` |
| `allowPrivilegeEscalation` | `true` | `false` |
| `readOnlyRootFilesystem` | `false` | `true` |
| `capabilities` | adds `SYS_ADMIN`, etc. | `drop: ["ALL"]` |
| `hostNetwork` / `hostPID` / `hostIPC` | `true` | `false` |
| `resources.limits` | missing | set |
| `seccompProfile` | unset | `RuntimeDefault` |

Kubernetes can enforce these automatically with **Pod Security admission**. The
lab's `lab-restricted` namespace is labelled to enforce the `restricted` profile,
so insecure pods are rejected at `kubectl apply` time.

---

## Tasks

1. **Scan the bad manifest statically** (no cluster needed):
   ```bash
   kube-linter lint vulnerable/deployment.yaml
   ```
   Read every finding. For each, name the attack it enables.

2. **Try to apply the bad manifest into the restricted namespace** and watch it
   get rejected:
   ```bash
   kubectl apply -n lab-restricted -f vulnerable/deployment.yaml
   ```
   Read the admission error — it lists each violated control.

3. **Harden it yourself.** Copy the vulnerable file and fix the findings one at a
   time. Re-run `kube-linter` after each change.

4. **Compare** with the reference fix:
   ```bash
   diff vulnerable/deployment.yaml hardened/deployment.yaml
   ```

5. **Apply the hardened manifest** and confirm it is accepted and the pod runs:
   ```bash
   kubectl apply -f hardened/deployment.yaml
   kubectl get pods -n lab-restricted -l app=web
   ```

---

## Checkpoint questions

- Why is `allowPrivilegeEscalation: false` important even when the container
  already runs as non-root?
- `readOnlyRootFilesystem: true` broke nginx until we mounted `emptyDir`
  volumes. Which directories did it need, and why is a writable `/var/cache`
  not a security hole the way a writable `/` is?
- What is the difference between the `baseline` and `restricted` Pod Security
  profiles? Name one thing `baseline` allows that `restricted` forbids.

## Solution

See [`hardened/deployment.yaml`](hardened/deployment.yaml). It drops all
capabilities, runs as UID 10001, forbids escalation, mounts a read-only root
filesystem, sets resource limits, and applies the `RuntimeDefault` seccomp
profile — a clean pass of the `restricted` profile.
