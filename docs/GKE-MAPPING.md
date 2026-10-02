# From this lab to GKE

Everything here runs on a free local kind cluster, but the controls map directly
onto Google Kubernetes Engine. This is how each exercise translates.

| Lab exercise | Local (kind) | GKE equivalent |
|--------------|--------------|----------------|
| 01 Pod Security | Pod Security admission, `restricted` namespace labels | Same Pod Security admission; **Autopilot** enforces much of `restricted` by default and blocks privileged pods |
| 02 RBAC | Kubernetes RBAC + `kubectl auth can-i` | Same RBAC, **plus** IAM. Use **Workload Identity** so pods get Google service-account access without node-wide keys |
| 03 NetworkPolicy | needs Calico CNI (`--with-calico`) | **GKE Dataplane V2** (eBPF) enforces NetworkPolicy natively — no add-on needed |
| 04 Secrets & supply chain | base64 Secret; pinned image | **Secrets encrypted at rest with Cloud KMS**; **Secret Manager** via Workload Identity; **Binary Authorization** to require signed images |

## Extra GKE hardening worth mentioning in class

- **Shielded GKE Nodes** — secure boot + integrity monitoring on nodes.
- **Node auto-upgrade & Container-Optimized OS** — patched, minimal node image.
- **Private clusters** — no public node IPs; control-plane access restricted.
- **Autopilot** — Google manages nodes and blocks a long list of risky pod
  settings for you (a managed version of Exercise 01).
- **GKE Security Posture dashboard** — flags workload misconfigurations, the same
  class of findings `kube-linter` produces here.

## If you want to run the GKE version (costs money)

The concepts don't require it, but to try on real GKE:

```bash
# Dataplane V2 gives you native NetworkPolicy enforcement
gcloud container clusters create seclab \
  --enable-dataplane-v2 \
  --workload-pool=PROJECT_ID.svc.id.goog \
  --enable-shielded-nodes \
  --release-channel=regular \
  --num-nodes=1

gcloud container clusters get-credentials seclab
# then apply the same exercise manifests
```

Remember to `gcloud container clusters delete seclab` afterwards to avoid charges.
