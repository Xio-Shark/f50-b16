#!/usr/bin/env python3
"""Patch overlay.d TCP-ADB scripts inside bin/magisk.img (boot v4 + lz4_legacy).

Preserves original CPIO bytes for untouched entries so compressed size stays
<= original and the AVB/trailer offset is unchanged.
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

try:
    import lz4.block
except ImportError:
    print("ERROR: need python lz4 (`pip3 install lz4`)", file=sys.stderr)
    sys.exit(1)

LZ4_LEGACY_MAGIC = 0x184C2102
PAGE = 4096
CPIO_MAGIC = b"070701"
# Minimal patch: ONLY start_adbip.sh. Never rewrite adbip.rc (boot-risk).
TARGETS = {
    "overlay.d/sbin/start_adbip.sh": "start_adbip.sh",
}


def align(n: int, a: int = 4) -> int:
    return (n + a - 1) & ~(a - 1)


def page_align(n: int) -> int:
    return (n + PAGE - 1) // PAGE * PAGE


def decompress_lz4_legacy(buf: bytes) -> bytes:
    if struct.unpack_from("<I", buf, 0)[0] != LZ4_LEGACY_MAGIC:
        raise ValueError("not lz4_legacy")
    off = 4
    out = bytearray()
    while off + 4 <= len(buf):
        bs = struct.unpack_from("<I", buf, off)[0]
        off += 4
        if bs == 0:
            break
        out.extend(lz4.block.decompress(buf[off : off + bs], uncompressed_size=0x800000))
        off += bs
    return bytes(out)


def compress_lz4_legacy(data: bytes, block_uncomp: int = 0x800000) -> bytes:
    # Magisk boot ramdisk uses LZ4 HC (matches stock magisk.img size).
    out = bytearray(struct.pack("<I", LZ4_LEGACY_MAGIC))
    off = 0
    while off < len(data):
        chunk = data[off : off + block_uncomp]
        off += len(chunk)
        comp = lz4.block.compress(
            chunk, store_size=False, mode="high_compression", compression=12
        )
        out.extend(struct.pack("<I", len(comp)))
        out.extend(comp)
    return bytes(out)


def iter_cpio(data: bytes):
    off = 0
    while off + 110 <= len(data):
        if data[off : off + 6] != CPIO_MAGIC:
            raise ValueError(f"bad cpio at {off}")
        header = data[off : off + 110]
        fields = [int(header[i : i + 8], 16) for i in range(6, 110, 8)]
        mode, filesize, namesize = fields[1], fields[6], fields[11]
        name_off = off + 110
        name = data[name_off : name_off + namesize - 1].decode()
        data_off = align(name_off + namesize, 4)
        next_off = align(data_off + filesize, 4)
        yield {
            "name": name,
            "mode": mode,
            "filesize": filesize,
            "start": off,
            "data_off": data_off,
            "next_off": next_off,
            "payload": data[data_off : data_off + filesize],
            "raw": data[off:next_off],
        }
        off = next_off
        if name == "TRAILER!!!":
            break


def encode_entry(name: str, mode: int, payload: bytes, ino: int = 1) -> bytes:
    name_b = name.encode() + b"\0"
    namesize = len(name_b)
    filesize = 0 if name == "TRAILER!!!" else len(payload)
    hdr = (
        b"070701"
        + f"{ino:08x}".encode()
        + f"{mode:08x}".encode()
        + f"{0:08x}".encode()
        + f"{0:08x}".encode()
        + f"{1:08x}".encode()
        + f"{0:08x}".encode()
        + f"{filesize:08x}".encode()
        + f"{0:08x}".encode()
        + f"{0:08x}".encode()
        + f"{0:08x}".encode()
        + f"{0:08x}".encode()
        + f"{namesize:08x}".encode()
        + f"{0:08x}".encode()
    )
    out = bytearray(hdr + name_b)
    out.extend(b"\0" * (align(len(out), 4) - len(out)))
    if filesize:
        out.extend(payload)
        out.extend(b"\0" * (align(len(out), 4) - len(out)))
    return bytes(out)


def patch_cpio(cpio: bytes, replacements: dict[str, bytes]) -> bytes:
    out = bytearray()
    found = set()
    for ent in iter_cpio(cpio):
        name = ent["name"]
        if name in replacements:
            payload = replacements[name]
            # Prefer same filesize (pad with newlines) to keep stream stable
            if len(payload) < ent["filesize"]:
                payload = payload + b"\n" * (ent["filesize"] - len(payload))
            if len(payload) == ent["filesize"]:
                # in-place payload replace inside original raw entry
                raw = bytearray(ent["raw"])
                rel = ent["data_off"] - ent["start"]
                raw[rel : rel + ent["filesize"]] = payload
                out.extend(raw)
            else:
                out.extend(encode_entry(name, ent["mode"] or 0o100755, payload))
            found.add(name)
        else:
            out.extend(ent["raw"])
    missing = set(replacements) - found
    if missing:
        raise SystemExit(f"missing cpio entries: {missing}")
    return bytes(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--img", type=Path, default=None)
    ap.add_argument("--script-dir", type=Path, default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    here = Path(__file__).resolve().parent
    script_dir = args.script_dir or here
    img_path = args.img or (here.parent / "bin" / "magisk.img")

    replacements: dict[str, bytes] = {}
    for cpio_name, fname in TARGETS.items():
        p = script_dir / fname
        if not p.is_file():
            print(f"ERROR: missing {p}", file=sys.stderr)
            return 1
        data = p.read_bytes().replace(b"\r\n", b"\n")
        if not data.endswith(b"\n"):
            data += b"\n"
        replacements[cpio_name] = data
        print(f"{cpio_name}: {len(data)} bytes")

    # Always patch from pristine original if available
    pristine = img_path.with_suffix(img_path.suffix + ".pre_tcp_patch")
    orig_path = img_path.with_suffix(img_path.suffix + ".orig")
    src = pristine if pristine.exists() else (orig_path if orig_path.exists() else img_path)
    raw = bytearray(src.read_bytes())
    print(f"source image: {src}")

    ks, rs = struct.unpack_from("<2I", raw, 8)
    hv = struct.unpack_from("<I", raw, 40)[0]
    if raw[:8] != b"ANDROID!" or hv not in (3, 4):
        print(f"ERROR: bad boot header hv={hv}", file=sys.stderr)
        return 1

    koff = PAGE
    roff = PAGE + page_align(ks)
    old_rd = bytes(raw[roff : roff + rs])
    trailer_off = roff + page_align(rs)
    trailer = bytes(raw[trailer_off:])

    cpio = decompress_lz4_legacy(old_rd)
    new_cpio = patch_cpio(cpio, replacements)
    new_rd = compress_lz4_legacy(new_cpio)
    print(f"cpio {len(cpio)} -> {len(new_cpio)}")
    print(f"lz4  {len(old_rd)} -> {len(new_rd)}")

    if len(new_rd) <= rs:
        padded = new_rd + b"\0" * (rs - len(new_rd))
        new_rs = rs
        keep_trailer = True
        print("OK: padded to original rs; trailer preserved")
    else:
        padded = new_rd
        new_rs = len(new_rd)
        keep_trailer = False
        print("WARNING: larger ramdisk; trailer shifts")

    hdr = bytearray(raw[:PAGE])
    struct.pack_into("<I", hdr, 12, new_rs)
    rd_bytes = padded if keep_trailer else new_rd
    out = bytearray(hdr)
    out.extend(raw[koff : koff + ks])
    out.extend(b"\0" * (page_align(ks) - ks))
    out.extend(rd_bytes)
    out.extend(b"\0" * (page_align(new_rs) - len(rd_bytes)))
    if keep_trailer:
        out.extend(trailer)
    if len(out) < len(raw):
        out.extend(b"\0" * (len(raw) - len(out)))
    if len(out) > len(raw):
        print(f"ERROR: {len(out)} > {len(raw)}", file=sys.stderr)
        return 1

    if args.dry_run:
        dry = img_path.with_suffix(img_path.suffix + ".tcp_patched.dry")
        dry.write_bytes(out)
        print(f"dry-run -> {dry}")
        return 0

    if not pristine.exists():
        pristine.write_bytes(src.read_bytes() if src != img_path else bytes(raw))
    img_path.write_bytes(out)
    # verify trailer
    if keep_trailer:
        t2 = out[trailer_off : trailer_off + 4]
        print(f"trailer head: {bytes(t2)!r}")
    print(f"OK: wrote {img_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
