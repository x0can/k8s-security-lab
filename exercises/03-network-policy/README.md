# Exercise 03 — Network segmentation with NetworkPolicy

**Goal:** go from flat, wide-open pod networking to default-deny with a single
least-privilege allow rule.

**Time:** ~40 min · **Difficulty:** ⭐⭐ intermediate

---

## Background

By default, **every pod can talk to every other pod**, in any namespace. That
means a compromised front-end can reach your database directly. `NetworkPolicy`
objects let you segment the network: deny everything, then allow only the flows
you actually need.

A good pattern per namespace:

1. A **default-deny** policy (empty `podSelector`, `policyTypes: [Ingress]`).
2. Narrow **allow** policies for the specific tier-to-tier flows.

> ⚠️ **CNI requirement:** NetworkPolicy is only enforced if your cluster's
> network plugin supports it. kind's default `kindnet` does **not**. Create the
> lab cluster with Calico so these rules take effect:
> ```bash
> ./scripts/setup.sh --with-calico
> ```
> Without a policy-aware CNI the objects are accepted but silently ignored —
> itself a great teaching point about controls that *look* applied but aren't.

---

## Tasks

1. **Deploy the app** (api + db, no policies yet):
   ```bash
   kubectl apply -f vulnerable/app.yaml
   ```

2. **Prove the network is flat.** Launch a throwaway pod that is *not* part of
   the app and show it can still reach the db:
   ```bash
   kubectl run probe -n lab-net --rm -it --restart=Never \
     --image=redis:7-alpine -- \
     redis-cli -h db -p 6379 ping
   ```
   A `PONG` means an unrelated pod reached your database. Bad.

3. **Apply default-deny + the allow rule:**
   ```bash
   kubectl apply -f hardened/networkpolicy.yaml
   ```

4. **Re-test.** The unrelated probe should now time out, while the api pod (which
   carries `tier: frontend`) still connects:
   ```bash
   # unrelated pod -> should FAIL / time out now
   kubectl run probe -n lab-net --rm -it --restart=Never \
     --image=redis:7-alpine -- \
     redis-cli -h db -p 6379 ping

   # from the api pod -> should still PONG
   kubectl exec -n lab-net deploy/api -- \
     sh -c "nc -zv db 6379 || echo blocked"
   ```

5. **Extend it:** write an egress policy so the db can make *no* outbound
   connections at all. Compare your approach with the discussion in
   [docs/INSTRUCTOR-NOTES.md](../../docs/INSTRUCTOR-NOTES.md).

---

## Checkpoint questions

- Why does an empty `podSelector: {}` select every pod in the namespace?
- The allow rule uses `podSelector` on `tier: frontend`. How would you allow
  traffic from pods in a *different* namespace instead?
- Why is default-deny safer than writing deny rules for known-bad traffic?

## Solution

See [`hardened/networkpolicy.yaml`](hardened/networkpolicy.yaml) — a
default-deny-ingress policy plus a scoped rule allowing only the frontend tier
to reach the db on 6379.
