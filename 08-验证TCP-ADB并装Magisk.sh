#!/usr/bin/env bash
# After patched boot is up: connect TCP ADB and install Magisk APK.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APK="$ROOT/packages/Magisk_28103.apk"
HOST="${F50_ADB_HOST:-192.168.0.1}"
PORT="${F50_ADB_PORT:-5555}"

need() { command -v "$1" >/dev/null || { echo "ERROR: need $1 (brew install android-platform-tools)"; exit 1; }; }
need adb
need nc
[[ -f "$APK" ]] || { echo "ERROR: missing $APK"; exit 1; }

echo "Target ${HOST}:${PORT}"
if ! ping -c 1 -W 2000 "$HOST" >/dev/null 2>&1; then
  echo "ERROR: $HOST 不通 — 请先连上 F50 的 Wi‑Fi"
  exit 1
fi

echo "Waiting for TCP ${PORT} (up to ~120s)..."
ok=0
for i in $(seq 1 60); do
  if nc -z -w 1 "$HOST" "$PORT" 2>/dev/null; then
    ok=1
    break
  fi
  sleep 2
done
if [[ "$ok" -ne 1 ]]; then
  echo "ERROR: ${HOST}:${PORT} 仍未开放"
  echo "可能: 还没刷 TCP 版 boot / 机器未起完 / 需要从备份还原后重试"
  exit 1
fi

adb disconnect "${HOST}:${PORT}" >/dev/null 2>&1 || true
adb connect "${HOST}:${PORT}"
sleep 1
adb devices
adb wait-for-device
echo "Installing Magisk APK..."
adb install -r "$APK"
echo "OK. 打开 Magisk App 完成安装向导即可。"
