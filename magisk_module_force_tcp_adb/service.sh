#!/system/bin/sh
# Late start — force USB ADB composition + network adbd for hosts that only see CDC+MTP.
MODDIR=${0%/*}

# Prefer resetprop if Magisk provides it
if command -v resetprop >/dev/null 2>&1; then
  resetprop persist.sys.usb.config mtp,adb
  resetprop sys.usb.config mtp,adb
else
  setprop persist.sys.usb.config mtp,adb
  setprop sys.usb.config mtp,adb
fi

setprop persist.service.adb.enable 1
setprop service.adb.tcp.port 5555

# Restart adbd to pick up tcp port / usb config
stop adbd
start adbd

# Retry once after boot settles
sleep 5
setprop service.adb.tcp.port 5555
stop adbd
start adbd
