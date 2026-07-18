#!/usr/bin/env bash
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
print_banner
need_deps

cat <<'EOF'
请选择操作:

  0) 备份分区（强烈推荐先做）
  1) [直接插电] 一键 Root          (--kickto 2)
  2) [直接插电] 一键 Root 备用2    (--kickto 0)
  3) [直接插电] 一键 Root 备用3    (--kickto 1)
  4) [短接模式] 一键 Root
  5) [直接插电] 手动 Root（交互）
  6) 从备份还原
  7) 只刷 boot（极简 TCP ADB → magisk.img.tcp_min）
  7b) 只刷 boot（短接）
  8) 验证 TCP ADB 并安装 Magisk APK
  9) 安装完整版 UFI-TOOLS（需 5555 已通）
  q) 退出

完整版流程: 1 Root → 确认热点 → 7 极简TCP → 9 装 UFI
刷机前必须拔线+关机。Mac 无 USB ADB，用 adb connect 192.168.0.1:5555

EOF
read -r -p "输入序号: " choice
case "$choice" in
  0) exec "$ROOT/00-备份读分区.sh" ;;
  1) exec "$ROOT/01-直接插电-一键Root.sh" ;;
  2) exec "$ROOT/02-直接插电-一键Root-备用2.sh" ;;
  3) exec "$ROOT/03-直接插电-一键Root-备用3.sh" ;;
  4) exec "$ROOT/04-短接模式-一键Root.sh" ;;
  5) exec "$ROOT/05-直接插电-手动Root.sh" ;;
  6) exec "$ROOT/06-从备份还原.sh" ;;
  7) exec "$ROOT/07-只刷boot-TCP-ADB.sh" ;;
  7b|7B) exec "$ROOT/07b-短接-只刷boot-TCP-ADB.sh" ;;
  8) exec "$ROOT/08-验证TCP-ADB并装Magisk.sh" ;;
  9) exec "$ROOT/09-安装完整版UFI-TOOLS.sh" ;;
  q|Q) exit 0 ;;
  *) die "无效选项: $choice" ;;
esac

