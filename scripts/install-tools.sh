#!/usr/bin/env bash
# Install the lab's CLI tools into ./bin:
#   - kube-linter, kubeconform   (static scanners — needed for scan.sh)
#   - kind, kubectl              (needed for setup.sh / a live cluster)
# Works on Linux, macOS, and Windows (Git Bash / MSYS2 / Cygwin).
# Safe to re-run.
#
# NOTE: a live cluster (setup.sh) ALSO needs Docker Desktop (Windows/macOS) or
# the Docker engine (Linux) running. That is a separate app install — see the
# message printed at the end.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/bin"
mkdir -p "$BIN"

KUBE_LINTER_VERSION="v0.6.8"
KUBECONFORM_VERSION="v0.6.7"
KIND_VERSION="v0.24.0"
KUBECTL_VERSION="v1.31.0"

# --- detect OS ---
os="linux"
case "$(uname -s)" in
  Linux*)                 os="linux" ;;
  Darwin*)                os="darwin" ;;
  MINGW*|MSYS*|CYGWIN*)   os="windows" ;;
esac

# --- detect arch ---
arch="amd64"
case "$(uname -m)" in
  arm64|aarch64) arch="arm64" ;;
esac

# Need a zip extractor on Windows.
if [ "$os" = "windows" ] && ! command -v unzip >/dev/null; then
  echo "ERROR: 'unzip' not found. In Git Bash install it, or use the manual"
  echo "download links printed below."
  echo "  kube-linter: https://github.com/stackrox/kube-linter/releases/tag/${KUBE_LINTER_VERSION}"
  echo "  kubeconform: https://github.com/yannh/kubeconform/releases/tag/${KUBECONFORM_VERSION}"
  exit 1
fi

echo "==> Detected OS=${os} ARCH=${arch}"

echo "==> Installing kube-linter ${KUBE_LINTER_VERSION}"
if [ "$os" = "windows" ]; then
  tmp="$(mktemp -d)"
  curl -sSL -o "$tmp/kl.zip" \
    "https://github.com/stackrox/kube-linter/releases/download/${KUBE_LINTER_VERSION}/kube-linter-windows.zip"
  unzip -oq "$tmp/kl.zip" -d "$BIN"      # -> kube-linter.exe
  rm -rf "$tmp"
else
  curl -sSL "https://github.com/stackrox/kube-linter/releases/download/${KUBE_LINTER_VERSION}/kube-linter-${os}.tar.gz" \
    | tar xz -C "$BIN" kube-linter
  chmod +x "$BIN/kube-linter"
fi

echo "==> Installing kubeconform ${KUBECONFORM_VERSION}"
if [ "$os" = "windows" ]; then
  tmp="$(mktemp -d)"
  curl -sSL -o "$tmp/kc.zip" \
    "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-windows-${arch}.zip"
  unzip -oq "$tmp/kc.zip" -d "$BIN"      # -> kubeconform.exe
  rm -rf "$tmp"
else
  curl -sSL "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-${os}-${arch}.tar.gz" \
    | tar xz -C "$BIN" kubeconform
  chmod +x "$BIN/kubeconform"
fi

# kind and kubectl are single raw binaries — just download and mark executable.
ext=""
[ "$os" = "windows" ] && ext=".exe"

echo "==> Installing kind ${KIND_VERSION}"
curl -sSL -o "$BIN/kind${ext}" \
  "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-${os}-${arch}"
chmod +x "$BIN/kind${ext}"

echo "==> Installing kubectl ${KUBECTL_VERSION}"
curl -sSL -o "$BIN/kubectl${ext}" \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${os}/${arch}/kubectl${ext}"
chmod +x "$BIN/kubectl${ext}"

echo
echo "Done. Installed into: $BIN"
ls -1 "$BIN"
echo
echo "Add to your PATH for this session:"
echo "  export PATH=\"$BIN:\$PATH\""
echo
echo "To create a live cluster (setup.sh) you ALSO need Docker running:"
echo "  Windows/macOS : install & start Docker Desktop -> https://www.docker.com/products/docker-desktop/"
echo "  Linux         : install docker engine and ensure the daemon is running"
echo "Static scanning (scan.sh) needs none of that."
