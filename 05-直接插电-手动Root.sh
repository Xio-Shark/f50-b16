#!/usr/bin/env bash
# Equivalent to Windows: [直接插电]手动Root.bat
# Enters interactive FDL2 after kick to dl_diag. When you see "FDL2 >", type:
#   path <bin目录绝对路径>
#   w trustos <bin>/tos.bin
#   w boot <bin>/magisk.img
#   reset
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
print_banner
wait_hint_direct
cat <<EOF
进入交互后，看到 FDL2 > 时逐行输入（可复制）:

path $BIN
w trustos $BIN/tos.bin
w boot $BIN/magisk.img
reset

EOF
# Windows bat 写的是 `--kick dl_diag`；`--kick` 本身已走 dl_diag 路径，
# 多余的 dl_diag 会被当成未知命令。这里只保留 --kick。
run_spd --wait 300 --kick
