#!/usr/bin/env python3
"""Diagnose why F50 shows usb_port on but adb devices is empty on macOS.

Root cause check: does USB expose the standard ADB interface (ff/42/01)?
F50 B16 often exposes CDC ECM + MTP only, with iConfiguration string "adb"
but WITHOUT a real ADB function — host adb cannot invent that interface.
"""

from __future__ import annotations

import shutil
import subprocess
import sys


def main() -> int:
    try:
        import usb.core
        import usb.util
    except ImportError:
        print("[err] need pyusb: pip3 install --user pyusb")
        print("      and: brew install libusb")
        return 1

    print("=== F50 USB / ADB diagnosis ===\n")

    targets = list(usb.core.find(find_all=True, idVendor=0x19D2))
    targets += list(usb.core.find(find_all=True, idVendor=0x1782))
    # de-dup by bus/address
    seen = set()
    uniq = []
    for d in targets:
        key = (d.bus, d.address)
        if key not in seen:
            seen.add(key)
            uniq.append(d)

    if not uniq:
        print("[fail] No ZTE/Unisoc USB device (19d2/1782). Plug F50 into Mac first.")
        return 2

    has_adb_iface = False
    for d in uniq:
        try:
            m = usb.util.get_string(d, d.iManufacturer) if d.iManufacturer else ""
            p = usb.util.get_string(d, d.iProduct) if d.iProduct else ""
        except Exception:
            m, p = "?", "?"
        print(f"Device {d.idVendor:04x}:{d.idProduct:04x}  {m!r} {p!r}")
        try:
            cfg = d.get_active_configuration()
            try:
                cfg_name = usb.util.get_string(d, cfg.iConfiguration) if cfg.iConfiguration else ""
            except Exception:
                cfg_name = ""
            print(f"  active config iConfiguration={cfg_name!r}")
            for intf in cfg:
                cls, sub, proto = (
                    intf.bInterfaceClass,
                    intf.bInterfaceSubClass,
                    intf.bInterfaceProtocol,
                )
                tag = []
                if cls == 0xFF and sub == 0x42 and proto == 0x01:
                    tag.append("ADB")
                    has_adb_iface = True
                if cls == 0x02:
                    tag.append("CDC")
                if cls == 0x0A:
                    tag.append("CDC-DATA")
                if cls == 0x06:
                    tag.append("MTP/Image")
                if cls == 0x08:
                    tag.append("MSC")
                print(
                    f"  If{intf.bInterfaceNumber}.{intf.bAlternateSetting}: "
                    f"{cls:02x}/{sub:02x}/{proto:02x} {' '.join(tag)}"
                )
        except Exception as e:
            print(f"  [warn] cannot walk interfaces: {e}")
        print()

    adb = shutil.which("adb")
    if adb:
        subprocess.run([adb, "kill-server"], capture_output=True)
        out = subprocess.run([adb, "devices", "-l"], capture_output=True, text=True)
        print("adb devices:")
        print(out.stdout or out.stderr)
    else:
        print("[warn] adb not in PATH\n")

    if has_adb_iface:
        print(
            "[ok] Standard ADB USB interface (ff/42/01) IS present.\n"
            "     If adb still empty: try ADB_LIBUSB=0, ~/.android/adb_usb.ini=0x19D2,\n"
            "     unplug/replug, allow accessory prompt."
        )
        return 0

    print(
        "[fail] No standard ADB interface (class ff / subclass 42 / protocol 01).\n"
        "\n"
        "This is a DEVICE USB composition issue, not a Mac driver glitch.\n"
        "On your F50 B16 we typically see CDC Ethernet + MTP only.\n"
        "The config string may even say \"adb\", but adbd is not bound to USB.\n"
        "\n"
        "Host-side tweaks (adb_usb.ini / ADB_LIBUSB / goform toggle) cannot fix this\n"
        "until the phone exposes ADB or starts adbd on TCP (port 5555).\n"
        "\n"
        "Real fixes:\n"
        "  1) Flash Magisk boot, then inject a boot/Magisk service that runs:\n"
        "       setprop sys.usb.config mtp,adb\n"
        "       setprop service.adb.tcp.port 5555\n"
        "       stop adbd; start adbd\n"
        "     Then: adb connect 192.168.0.1:5555\n"
        "  2) Use a firmware build where USB composition includes real ADB\n"
        "     (community often cites older builds e.g. B09 — downgrade has risk).\n"
    )
    return 3


if __name__ == "__main__":
    sys.exit(main())
