#!/usr/bin/env bash
# After TCP ADB is up: install Magisk 28103 + UFI-TOOLS full (WEB) APK.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
HOST="${F50_ADB_HOST:-192.168.0.1}"
PORT="${F50_ADB_PORT:-5555}"
MAGISK_APK="$ROOT/packages/Magisk_28103.apk"
UFI_APK="${UFI_APK:-$ROOT/packages/UFI-TOOLS_WEB_V4.0.8_20260706_0234.apk}"
UFI_PKG="${UFI_PKG:-com.minikano.f50_sms}"

need() { command -v "$1" >/dev/null || { echo "ERROR: need $1"; exit 1; }; }
need adb
need nc
[[ -f "$MAGISK_APK" ]] || { echo "ERROR: missing $MAGISK_APK"; exit 1; }
[[ -f "$UFI_APK" ]] || { echo "ERROR: missing UFI APK: $UFI_APK"; exit 1; }

install_apk() {
  local label="$1" apk="$2" remote="$3"
  echo "==> $label"
  if adb install -r -d -g "$apk"; then
    return 0
  fi
  echo "stream install failed, fallback: push + pm install"
  adb push "$apk" "$remote"
  adb shell pm install -r -d -g "$remote"
}

echo "Magisk: $MAGISK_APK"
echo "UFI:    $UFI_APK"
echo "Target: ${HOST}:${PORT}"

ping -c 1 -W 2000 "$HOST" >/dev/null 2>&1 || {
  echo "ERROR: $HOST 不通 — 先连 F50 的 Wi‑Fi"
  exit 1
}

echo "Waiting for TCP ${PORT}..."
ok=0
for _ in $(seq 1 60); do
  nc -z -w 1 "$HOST" "$PORT" 2>/dev/null && { ok=1; break; }
  sleep 2
done
[[ "$ok" -eq 1 ]] || {
  echo "ERROR: ${HOST}:${PORT} 未开放"
  exit 1
}

adb disconnect "${HOST}:${PORT}" >/dev/null 2>&1 || true
adb connect "${HOST}:${PORT}"
sleep 1
adb wait-for-device
adb devices

install_apk "Install Magisk 28103" "$MAGISK_APK" /data/local/tmp/Magisk.apk
install_apk "Install UFI-TOOLS full (WEB)" "$UFI_APK" /data/local/tmp/ufi.apk

echo "==> Launch UFI-TOOLS ($UFI_PKG)"
adb shell monkey -p "$UFI_PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
sleep 2

echo
echo "OK — packages:"
adb shell pm path com.topjohnwu.magisk || true
adb shell pm path "$UFI_PKG" || true
echo
echo "1. Magisk：打开 App 完成安装向导（不要换成别的版本）"
echo "2. UFI-TOOLS：浏览器打开 http://${HOST}:2333 （若打不开，再开一次 App 或重启设备）"
echo "3. 高级功能在 UFI-TOOLS 网页里开启"
