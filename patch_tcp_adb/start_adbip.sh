#!/system/bin/sh
# Minimal TCP ADB only. Do NOT touch USB composition (breaks F50 boot/WiFi).
# Mac: adb connect 192.168.0.1:5555
LOG=/data/local/tmp/adbip.log
LOCK=/data/local/tmp/adbip.lock
mkdir -p /data/local/tmp
if [ -f "$LOCK" ]; then
  o=$(cat "$LOCK" 2>/dev/null); n=$(date +%s)
  [ -n "$o" ] && [ $((n - o)) -lt 120 ] && exit 0
fi
date +%s >"$LOCK"
echo "[ADBIP-min] $(date)" >"$LOG"
log(){ echo "[$(date '+%F %T')] $*" >>"$LOG"; }

# wait boot a bit (network late on F50)
i=0
while [ "$i" -le 60 ]; do
  [ "$(getprop sys.boot_completed)" = "1" ] && break
  sleep 1; i=$((i+1))
done
log "boot_completed=$(getprop sys.boot_completed) i=$i"

# TCP only — no sys.usb.config / persist.sys.usb.config
setprop service.adb.tcp.port 5555
setprop persist.adb.tcp.port 5555
setprop persist.service.adb.enable 1

radbd(){ stop adbd 2>/dev/null; sleep 1; start adbd 2>/dev/null; }
radbd
log "tcp=$(getprop service.adb.tcp.port)"

i=1
while [ "$i" -le 18 ]; do
  sleep 5
  setprop service.adb.tcp.port 5555
  setprop persist.adb.tcp.port 5555
  radbd
  log "retry $i tcp=$(getprop service.adb.tcp.port)"
  i=$((i+1))
done

# FOTA best-effort (after ADB); ignore errors
pm disable com.zte.zdm 2>/dev/null
pm uninstall -k --user 0 com.zte.zdm 2>/dev/null
am force-stop com.zte.zdm 2>/dev/null
sync
log done
chmod 666 "$LOG" 2>/dev/null
exit 0
