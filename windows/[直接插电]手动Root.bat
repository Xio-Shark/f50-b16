@echo off
setlocal enabledelayedexpansion
title Flash ROOT Mode

echo waitting for device
.\bin\spd_dump.exe --wait 300 --kick dl_diag
pause
