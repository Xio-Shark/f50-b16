@echo off
setlocal enabledelayedexpansion
title Flash ROOT Mode

echo waitting for device
.\bin\spd_dump.exe --wait 300 --kickto 0 exec path .\bin  w trustos .\bin\tos.bin  w boot .\bin\magisk.img reset
pause
