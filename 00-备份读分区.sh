#!/usr/bin/env bash
# Backup key partitions before Root.
# Usage:
#   ./00-备份读分区.sh           # 默认：直接插电 --kickto 2（先试这个）
#   ./00-备份读分区.sh kick0     # 直接插电备用 kickto 0
#   ./00-备份读分区.sh kick1     # 直接插电备用 kickto 1
#   ./00-备份读分区.sh short     # 短接 + exec_addr/FDL（上次失败时可改这个）
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
print_banner

MODE="${1:-kick2}"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$ROOT/backup_${STAMP}"
mkdir -p "$OUT"

cat <<EOF
将备份到: $OUT
模式: $MODE

【关键】必须先拔线 → 彻底关机 → 再运行本脚本 → 再插线。
开机插着跑几乎一定会出现 usb_* TIMEOUT，备份目录会是空的。

EOF

need_deps
cd "$ROOT"

set +e
case "$MODE" in
  kick2|direct|"")
    wait_hint_direct
    "$SPD" --wait 300 --kickto 2 --verbose 1 \
      exec path "$OUT" \
      partition_list "$OUT/partition_list.txt" \
      r boot r trustos r splloader \
      reset
    rc=$?
    ;;
  kick0)
    wait_hint_direct
    "$SPD" --wait 300 --kickto 0 --verbose 1 \
      exec path "$OUT" \
      partition_list "$OUT/partition_list.txt" \
      r boot r trustos r splloader \
      reset
    rc=$?
    ;;
  kick1)
    wait_hint_direct
    "$SPD" --wait 300 --kickto 1 --verbose 1 \
      exec path "$OUT" \
      partition_list "$OUT/partition_list.txt" \
      r boot r trustos r splloader \
      reset
    rc=$?
    ;;
  short)
    wait_hint_short
    "$SPD" --wait 300 --verbose 1 \
      exec_addr 0x65012f48 \
      fdl "$BIN/fdl1-dl.bin" 0x65000800 \
      fdl "$BIN/fdl2-dl.bin" 0xb4fffe00 \
      exec path "$OUT" \
      partition_list "$OUT/partition_list.txt" \
      r boot r trustos r splloader \
      reset
    rc=$?
    ;;
  *)
    die "未知模式: $MODE（可用: kick2 / kick0 / kick1 / short）"
    ;;
esac
set -e

echo
echo "退出码: $rc"
echo "备份目录: $OUT"
ls -lah "$OUT" || true
if [[ ! -s "$OUT/boot" && ! -s "$OUT/boot.bin" ]] && ! ls "$OUT"/boot* >/dev/null 2>&1; then
  cat <<'EOF'

>>> 备份失败（目录几乎是空的）常见原因：
1. 机器还在开机状态就插了线（最常见）
2. 没先开脚本再插线，或插线太晚
3. 直接插电 kick 不对 → 依次试: ./00-备份读分区.sh kick0
                              ./00-备份读分区.sh kick1
                              ./00-备份读分区.sh short
4. short 时：关机 + 短接调试点的同时插线，见进度再松手
5. 出现 kick/mode 报错：电源+音量上按 7–10 秒硬重启后再试

成功标志：备份目录里能看到 boot / trustos 等非 0 字节文件。
EOF
  exit 1
fi
exit "$rc"
