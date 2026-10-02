# Kubernetes security cheatsheet

## A "restricted"-passing container securityContext

```yaml
securityContext:            # pod-level
  runAsNonRoot: true
  runAsUser: 10001
  fsGroup: 10001
  seccompProfile:
    type: RuntimeDefault
# container-level
securityContext:
  allowPrivilegeEscalation: false
  privileged: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  capabilities:
    drop: ["ALL"]
resources:
  requests: { cpu: "50m", memory: "64Mi" }
  limits:   { cpu: "250m", memory: "128Mi" }
```

## Inspect & test

```bash
# Static scans (no cluster)
kube-linter lint path/to/manifest.yaml
kubeconform -strict -summary path/to/manifest.yaml

# RBAC — ask "can this SA do X?"
kubectl auth can-i VERB RESOURCE \
  --as=system:serviceaccount:NAMESPACE:SA_NAME [-n NS | -A]

# What does a role actually grant?
kubectl describe clusterrole NAME
kubectl get rolebindings,clusterrolebindings -A -o wide | grep SA_NAME

# Pod Security — why was a pod rejected?
kubectl apply -n lab-restricted -f pod.yaml   # read the admission error

# NetworkPolicy — list and describe
kubectl get netpol -A
kubectl describe netpol NAME -n NS
```

## Red flags in a manifest

| Pattern | Risk |
|---------|------|
| `image: ...:latest` | mutable / unverifiable image |
| `privileged: true` | full node access |
| `hostNetwork/hostPID/hostIPC: true` | breaks isolation |
| `runAsUser: 0` / no `runAsNonRoot` | runs as root |
| `capabilities.add: [SYS_ADMIN,...]` | near-root power |
| `verbs: ["*"]` / `resources: ["*"]` | RBAC over-grant |
| verbs `escalate`/`bind`/`impersonate` | privilege escalation |
| `get`/`list` on `secrets` | credential theft |
| no `NetworkPolicy` | flat, wide-open network |
| secret in `env.value` / `args` | leaked credentials |
| no `resources.limits` | DoS / noisy neighbour |

## The four controls, in one line each

1. **Pod Security** — least-privileged containers (non-root, drop caps, no escalation).
2. **RBAC** — least-privileged identities (narrow verbs, smallest scope).
3. **NetworkPolicy** — least-privileged network (default-deny + scoped allows).
4. **Secrets/supply chain** — never inline secrets; pin & verify images.
