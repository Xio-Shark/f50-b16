#!/usr/bin/env bash
# Restore boot + trustos (+ optional splloader) from a backup_* directory.
# Usage:
#   ./06-从备份还原.sh                              # 用最新 backup_*
#   ./06-从备份还原.sh backup_20260719_020347       # 指定目录名或绝对路径
#   ./06-从备份还原.sh backup_xxx kick0|kick1|short # 指定进下载模式
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
print_banner

ARG1="${1:-}"
MODE="${2:-kick2}"

if [[ -n "$ARG1" && -d "$ARG1" ]]; then
  BK="$ARG1"
elif [[ -n "$ARG1" && -d "$ROOT/$ARG1" ]]; then
  BK="$ROOT/$ARG1"
elif [[ -n "$ARG1" && "$ARG1" =~ ^(kick|short) ]]; then
  MODE="$ARG1"
  BK="$(ls -1d "$ROOT"/backup_* 2>/dev/null | sort | tail -1 || true)"
else
  BK="$(ls -1d "$ROOT"/backup_* 2>/dev/null | sort | tail -1 || true)"
fi

[[ -n "$BK" && -d "$BK" ]] || die "找不到 backup_* 目录"
[[ -f "$BK/boot.bin" ]] || die "缺少 $BK/boot.bin"
[[ -f "$BK/trustos.bin" ]] || die "缺少 $BK/trustos.bin"

cat <<EOF
将从备份还原:
  $BK
  boot.bin     -> boot
  trustos.bin  -> trustos
  splloader.bin-> splloader（若存在）
进下载模式: $MODE

【操作】拔线 → 关机 → 运行本脚本 → 再按提示插线/短接
EOF

need_deps
cd "$ROOT"

COMMON_CMDS=(
  exec path "$BK"
  w boot "$BK/boot.bin"
  w trustos "$BK/trustos.bin"
)
if [[ -f "$BK/splloader.bin" ]]; then
  COMMON_CMDS+=(w splloader "$BK/splloader.bin")
fi
COMMON_CMDS+=(reset)

set +e
case "$MODE" in
  kick2|direct|"")
    wait_hint_direct
    "$SPD" --wait 300 --kickto 2 --verbose 1 "${COMMON_CMDS[@]}"
    rc=$?
    ;;
  kick0)
    wait_hint_direct
    "$SPD" --wait 300 --kickto 0 --verbose 1 "${COMMON_CMDS[@]}"
    rc=$?
    ;;
  kick1)
    wait_hint_direct
    "$SPD" --wait 300 --kickto 1 --verbose 1 "${COMMON_CMDS[@]}"
    rc=$?
    ;;
  short)
    wait_hint_short
    "$SPD" --wait 300 --verbose 1 \
      exec_addr 0x65012f48 \
      fdl "$BIN/fdl1-dl.bin" 0x65000800 \
      fdl "$BIN/fdl2-dl.bin" 0xb4fffe00 \
      "${COMMON_CMDS[@]}"
    rc=$?
    ;;
  *)
    die "未知模式: $MODE"
    ;;
esac
set -e
echo "退出码: $rc"
exit "$rc"
