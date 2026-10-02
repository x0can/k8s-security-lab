#!/usr/bin/env bash
# Statically scan every manifest in the repo. No cluster required.
#
# - kube-linter : security / best-practice findings
# - kubeconform : schema validation
#
# Expected result:
#   * vulnerable/ manifests -> kube-linter REPORTS findings (that's the point)
#   * hardened/   manifests -> kube-linter CLEAN
# The script's own exit code reflects the HARDENED manifests only, so it can be
# used as a CI gate on student submissions.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$ROOT/bin:$PATH"

command -v kube-linter >/dev/null || { echo "kube-linter not found — run scripts/install-tools.sh"; exit 1; }
command -v kubeconform >/dev/null || { echo "kubeconform not found — run scripts/install-tools.sh"; exit 1; }

echo "############################################"
echo "# Schema validation (kubeconform)          #"
echo "############################################"
find "$ROOT/exercises" "$ROOT/cluster" -name '*.yaml' -print0 \
  | xargs -0 kubeconform -strict -summary -ignore-missing-schemas

echo
echo "############################################"
echo "# Security lint — VULNERABLE (expect FAIL) #"
echo "############################################"
find "$ROOT/exercises" -path '*/vulnerable/*' -name '*.yaml' | while read -r f; do
  echo "--- $f"
  kube-linter lint "$f" 2>&1 | tail -n +1 || true
done

echo
echo "############################################"
echo "# Security lint — HARDENED (expect PASS)   #"
echo "############################################"
rc=0
find "$ROOT/exercises" -path '*/hardened/*' -name '*.yaml' | while read -r f; do
  echo "--- $f"
  if ! kube-linter lint "$f"; then
    echo "!! FINDINGS in hardened manifest: $f"
  fi
done

# Gate: fail if any hardened manifest has findings.
if find "$ROOT/exercises" -path '*/hardened/*' -name '*.yaml' -print0 \
    | xargs -0 kube-linter lint >/dev/null 2>&1; then
  echo
  echo "✅ All hardened manifests pass kube-linter."
  rc=0
else
  echo
  echo "❌ Some hardened manifests have findings."
  rc=1
fi
exit $rc
