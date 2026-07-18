#!/usr/bin/env bash
# Equivalent to Windows: [短接模式]一键Root.bat
# Uses CVE-2022-38694 exec_addr + FDL1/FDL2 then write trustos+boot
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
print_banner
wait_hint_short
run_spd --wait 300 \
  exec_addr 0x65012f48 \
  fdl "$BIN/fdl1-dl.bin" 0x65000800 \
  fdl "$BIN/fdl2-dl.bin" 0xb4fffe00 \
  exec path "$BIN" \
  w trustos "$BIN/tos.bin" \
  w boot "$BIN/magisk.img" \
  reset
