#!/usr/bin/env bash
# Compatibility wrapper — short mode of 07.
# Prefer: ./07-只刷boot-TCP-ADB.sh   (kickto, same path as successful Root)
exec "$(cd "$(dirname "$0")" && pwd)/07-只刷boot-TCP-ADB.sh" short
