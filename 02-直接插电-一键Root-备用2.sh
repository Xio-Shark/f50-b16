#!/usr/bin/env bash
# Equivalent to Windows: [直接插电]一键Root_备用2.bat  (--kickto 0)
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
print_banner
wait_hint_direct
run_spd --wait 300 --kickto 0 exec path "$BIN" \
  w trustos "$BIN/tos.bin" \
  w boot "$BIN/magisk.img" \
  reset
