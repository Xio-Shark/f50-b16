#!/usr/bin/env bash
# Download large images/APKs from the GitHub Release into this repo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO="${F50_B16_REPO:-Xio-Shark/f50-b16}"
TAG="${F50_B16_TAG:-v1.0.0}"
BASE="https://github.com/${REPO}/releases/download/${TAG}"

need() { command -v "$1" >/dev/null || { echo "ERROR: need $1"; exit 1; }; }
need curl
mkdir -p "$ROOT/bin" "$ROOT/packages" "$ROOT/windows/bin"

fetch() {
  local url="$1" out="$2"
  if [[ -f "$out" && -s "$out" ]]; then
    echo "skip (exists): $out"
    return 0
  fi
  echo "download: $url"
  curl -fL --retry 5 --retry-delay 2 -o "$out.partial" "$url"
  mv "$out.partial" "$out"
}

fetch "$BASE/magisk.img" "$ROOT/bin/magisk.img"
fetch "$BASE/magisk.img.tcp_min" "$ROOT/bin/magisk.img.tcp_min"
fetch "$BASE/Magisk_28103.apk" "$ROOT/packages/Magisk_28103.apk"
fetch "$BASE/UFI-TOOLS_WEB_V4.0.8_20260706_0234.apk" "$ROOT/packages/UFI-TOOLS_WEB_V4.0.8_20260706_0234.apk"

# Windows Root scripts expect windows/bin/magisk.img
if [[ ! -f "$ROOT/windows/bin/magisk.img" ]]; then
  cp "$ROOT/bin/magisk.img" "$ROOT/windows/bin/magisk.img"
fi

echo "OK — assets ready. Next: ./菜单.sh  or  ./01-直接插电-一键Root.sh"
