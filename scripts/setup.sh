#!/usr/bin/env bash
# Create the kind lab cluster and lab namespaces.
#
#   ./scripts/setup.sh                # default kindnet CNI
#   ./scripts/setup.sh --with-calico  # Calico CNI (needed for Exercise 03)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="k8s-security-lab"
WITH_CALICO="false"
[ "${1:-}" = "--with-calico" ] && WITH_CALICO="true"

command -v kind >/dev/null    || { echo "kind not found — see README prerequisites"; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl not found — see README prerequisites"; exit 1; }

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "==> Cluster '$CLUSTER_NAME' already exists."
else
  if [ "$WITH_CALICO" = "true" ]; then
    echo "==> Creating cluster with default CNI disabled (for Calico)…"
    cat "$ROOT/cluster/kind-config.yaml" - <<'EOF' | kind create cluster --name "$CLUSTER_NAME" --config -
networking:
  disableDefaultCNI: true
  podSubnet: "192.168.0.0/16"
EOF
    echo "==> Installing Calico…"
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
    echo "==> Waiting for Calico to be ready…"
    kubectl -n kube-system rollout status ds/calico-node --timeout=180s || true
  else
    echo "==> Creating cluster with default CNI (kindnet)…"
    kind create cluster --name "$CLUSTER_NAME" --config "$ROOT/cluster/kind-config.yaml"
    echo "NOTE: NetworkPolicy (Exercise 03) is NOT enforced on kindnet."
    echo "      Re-run with --with-calico if you want to do Exercise 03 live."
  fi
fi

echo "==> Applying lab namespaces…"
kubectl apply -f "$ROOT/cluster/namespaces.yaml"

echo
echo "==> Ready. Namespaces:"
kubectl get ns | grep -E 'lab-|NAME'
echo
echo "Next: ./scripts/scan.sh   then   cd exercises/01-pod-security && cat README.md"
