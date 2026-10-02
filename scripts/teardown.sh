#!/usr/bin/env bash
# Delete the kind lab cluster.
set -euo pipefail
CLUSTER_NAME="k8s-security-lab"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "==> Deleting cluster '$CLUSTER_NAME'…"
  kind delete cluster --name "$CLUSTER_NAME"
else
  echo "No cluster named '$CLUSTER_NAME' found. Nothing to do."
fi
