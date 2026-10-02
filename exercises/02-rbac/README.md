# Exercise 02 — RBAC least privilege

**Goal:** turn an over-permissioned ServiceAccount into one that can do exactly
its job and nothing more.

**Time:** ~30 min · **Difficulty:** ⭐⭐ intermediate

---

## Background

Every pod runs as a ServiceAccount. If that account can read all Secrets or
modify RBAC, then anyone who compromises the pod inherits that power. The
failure modes:

- **Wildcards** — `verbs: ["*"]`, `resources: ["*"]`, `apiGroups: ["*"]`.
- **ClusterRole where a Role would do** — cluster-wide instead of one namespace.
- **Privilege-escalation verbs** — `escalate`, `bind`, `impersonate`, and write
  access to `roles`/`rolebindings`. These let a subject grant itself more.
- **Secret read access** — `get`/`list` on `secrets` is effectively credential
  theft.
- **Auto-mounted tokens** on pods that never call the API server.

Least privilege: grant the **narrowest verbs**, on the **fewest resources**, in
the **smallest scope**.

---

## Tasks

1. **Inspect the bad manifest** and list every power it grants:
   ```bash
   cat vulnerable/rbac.yaml
   ```
   > Note: RBAC over-permissioning is a *policy* problem, not a workload-config
   > one, so `kube-linter`'s default checks won't flag it. This is exactly why
   > the live `kubectl auth can-i` test in the next step matters — some risks are
   > only visible by querying the running cluster.

2. **See it live.** Apply it, then use `kubectl auth can-i` *as the
   ServiceAccount* to prove it can do dangerous things:
   ```bash
   kubectl apply -f vulnerable/rbac.yaml
   kubectl auth can-i '*' '*' \
     --as=system:serviceaccount:lab-baseline:app
   kubectl auth can-i get secrets -A \
     --as=system:serviceaccount:lab-baseline:app
   ```
   Both return **yes** — that is the problem.

3. **The app's real need:** read ConfigMaps in its own namespace. Write a
   `Role` + `RoleBinding` that grants only `get`/`list`/`watch` on `configmaps`
   in `lab-baseline`.

4. **Verify least privilege.** After applying your fix (and removing the bad
   ClusterRoleBinding), the dangerous checks should now return **no**, and the
   intended one **yes**:
   ```bash
   kubectl auth can-i get secrets -A \
     --as=system:serviceaccount:lab-baseline:app        # -> no
   kubectl auth can-i get configmaps -n lab-baseline \
     --as=system:serviceaccount:lab-baseline:app        # -> yes
   ```

5. **Compare** with [`hardened/rbac.yaml`](hardened/rbac.yaml).

---

## Checkpoint questions

- Why is the `escalate` verb dangerous even without `*` on everything else?
- When is a `ClusterRole` actually appropriate?
- The hardened SA sets `automountServiceAccountToken: false`. What does that
  protect against if the pod is compromised?

## Solution

See [`hardened/rbac.yaml`](hardened/rbac.yaml) — a namespaced read-only Role on
ConfigMaps, bound to the app ServiceAccount with a RoleBinding.
