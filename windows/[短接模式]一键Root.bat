@echo off
setlocal enabledelayedexpansion
title Flash ROOT Mode

echo waitting for device
.\bin\spd_dump.exe --wait 300 exec_addr 0x65012f48 fdl .\bin\fdl1-dl.bin 0x65000800 fdl .\bin\fdl2-dl.bin 0xb4fffe00 exec path .\bin  w trustos .\bin\tos.bin  w boot .\bin\magisk.img reset
pause
