#!/usr/bin/env bash
# Rebuild TomKing062/spreadtrum_flash spd_dump for this Mac (arm64 / x86_64).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
command -v brew >/dev/null || { echo "需要 Homebrew"; exit 1; }
brew list libusb >/dev/null 2>&1 || brew install libusb

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
git clone --depth 1 https://github.com/TomKing062/spreadtrum_flash.git "$WORKDIR/src"
cd "$WORKDIR/src"

LIBUSB_PREFIX="$(brew --prefix libusb)"
make LIBUSB=1 CC=clang \
  CFLAGS="-O2 -Wall -Wextra -std=c99 -pedantic -Wno-unused -DUSE_LIBUSB=1 -I${LIBUSB_PREFIX}/include" \
  LIBS="-lm -lpthread -L${LIBUSB_PREFIX}/lib -lusb-1.0"

cp -f "$WORKDIR/src/spd_dump" "$ROOT/bin/spd_dump"
chmod +x "$ROOT/bin/spd_dump"
echo "已安装: $ROOT/bin/spd_dump"
file "$ROOT/bin/spd_dump"
"$ROOT/bin/spd_dump" --help | head -3
