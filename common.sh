#!/usr/bin/env bash
# Shared helpers for F50 B16 Root (macOS / libusb spd_dump)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$ROOT/bin"
SPD="$BIN/spd_dump"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

need_deps() {
  [[ -x "$SPD" ]] || die "找不到 spd_dump: $SPD"
  if ! otool -L "$SPD" 2>/dev/null | grep -q libusb; then
    die "spd_dump 未链接 libusb"
  fi
  if ! "$SPD" --help >/dev/null 2>&1; then
    echo "提示: 需要 Homebrew libusb。执行: brew install libusb" >&2
    die "spd_dump 无法运行（多半缺 libusb）"
  fi
}

print_banner() {
  cat <<EOF
========================================
 F50 B16 Root (macOS)
 系统版本必须与包名 B16 一致！
 刷前务必先备份分区（见 README）
========================================
EOF
}

wait_hint_direct() {
  cat <<EOF

【直接插电】
1. 先运行本脚本（它会等待设备）
2. 机器保持关机
3. 插入 USB 数据线
4. 若提示 kick reboot timeout → 改用「短接模式」脚本，不必拔线

EOF
}

wait_hint_short() {
  cat <<EOF

【短接模式】
1. 先运行本脚本（它会等待设备）
2. 机器关机，短接调试点的同时插入 USB
3. 进度条跑起来后即可松开调试点

EOF
}

# All scripts must run with cwd = package root so exec_addr finds
# custom_exec_no_verify_65012f48.bin next to this script.
run_spd() {
  need_deps
  cd "$ROOT"
  echo "命令: $SPD $*"
  echo
  exec "$SPD" "$@"
}
