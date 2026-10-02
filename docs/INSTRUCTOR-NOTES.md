# Instructor notes

## Suggested timing (one 3-hour session)

| Block | Activity |
|-------|----------|
| 0:00–0:20 | Setup: `./scripts/setup.sh`, verify `kubectl get ns` |
| 0:20–0:50 | Ex 01 Pod Security — live-apply the vulnerable pod, read the admission rejection together |
| 0:50–1:25 | Ex 02 RBAC — `kubectl auth can-i` demo is the highlight |
| 1:25–1:35 | Break |
| 1:35–2:15 | Ex 03 NetworkPolicy — needs the `--with-calico` cluster |
| 2:15–2:45 | Ex 04 Secrets & supply chain |
| 2:45–3:00 | Wrap: run `./scripts/scan.sh` on everyone's hardened fixes |

## Running it as an assessment

Give students only the `vulnerable/` manifests and the task lists. Acceptance
criterion: their hardened manifest passes `./scripts/scan.sh` with zero
kube-linter findings **and** applies cleanly into `lab-restricted` (for ex 01).

### Suggested rubric (100 pts)

| Criterion | Pts |
|-----------|-----|
| Ex 01 passes `restricted` admission | 25 |
| Ex 02 — `auth can-i secrets` returns `no`, configmaps `yes` | 25 |
| Ex 03 — unrelated probe blocked, api→db allowed | 25 |
| Ex 04 — no plaintext secrets in workload, image pinned | 15 |
| Explanation quality (checkpoint answers) | 10 |

## Discussion prompts

- "Which of these four would a static CI scan catch, and which need a running
  cluster to prove?" (Answer: 01/02/04 are largely static; 03 needs runtime +
  a policy-aware CNI.)
- "The NetworkPolicy was accepted but did nothing on kindnet. How many real-world
  controls are like this — configured but not enforced?"
- "Base64 Secret vs encrypted Secret vs external store — where does each stop an
  attacker?"

## Egress answer (Ex 03 task 5)

A db that needs no outbound traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-deny-egress
  namespace: lab-net
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
    - Egress
  egress: []        # empty list = deny all egress
```

(You will usually still allow DNS egress to kube-dns on UDP/TCP 53.)

## Common student mistakes

- Forgetting `emptyDir` mounts after setting `readOnlyRootFilesystem: true`
  (nginx crashloops) — intended; it teaches *why* read-only roots need planning.
- Deleting the bad `ClusterRoleBinding` but leaving the `ClusterRole` (harmless
  but untidy) — good moment to discuss orphaned RBAC.
- Expecting NetworkPolicy to work on the default kind CNI.
