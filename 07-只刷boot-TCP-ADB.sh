#!/usr/bin/env bash
# Flash ONLY boot with minimal TCP-ADB image (magisk.img.tcp_min).
# Prerequisite: already rooted with ORIGINAL magisk.img + WiFi OK.
#
# Usage:
#   ./07-只刷boot-TCP-ADB.sh           # kickto 2
#   ./07-只刷boot-TCP-ADB.sh kick0|kick1|short
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
print_banner

MODE="${1:-kick2}"
IMG="$BIN/magisk.img.tcp_min"
[[ -f "$IMG" ]] || die "缺少 $IMG — 先运行: python3 patch_tcp_adb/rebuild_magisk_img.py"

cat <<EOF

【只刷 boot / 极简 TCP ADB → 为装 UFI-TOOLS 完整版】
镜像: $IMG
- 只改 start_adbip.sh（开 5555），不改 USB、不改 adbip.rc
- 不写 trustos
- 异常立刻: ./06-从备份还原.sh

【关键】拔线 → 关机 → 先跑脚本 → 再插线
EOF

need_deps
cd "$ROOT"
set +e
case "$MODE" in
  kick2|direct|"")
    wait_hint_direct
    "$SPD" --wait 300 --kickto 2 --verbose 1 \
      exec path "$BIN" \
      w boot "$IMG" \
      reset
    rc=$?
    ;;
  kick0)
    wait_hint_direct
    "$SPD" --wait 300 --kickto 0 --verbose 1 \
      exec path "$BIN" \
      w boot "$IMG" \
      reset
    rc=$?
    ;;
  kick1)
    wait_hint_direct
    "$SPD" --wait 300 --kickto 1 --verbose 1 \
      exec path "$BIN" \
      w boot "$IMG" \
      reset
    rc=$?
    ;;
  short)
    wait_hint_short
    "$SPD" --wait 300 --verbose 1 \
      exec_addr 0x65012f48 \
      fdl "$BIN/fdl1-dl.bin" 0x65000800 \
      fdl "$BIN/fdl2-dl.bin" 0xb4fffe00 \
      exec path "$BIN" \
      w boot "$IMG" \
      reset
    rc=$?
    ;;
  *)
    die "未知模式: $MODE"
    ;;
esac
set -e
echo "退出码: $rc"
[[ "$rc" -eq 0 ]] || echo "失败则试 kick0 / kick1；起不来立刻 06 还原"
exit "$rc"
