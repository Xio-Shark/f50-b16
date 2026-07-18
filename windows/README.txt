Windows 使用说明
1. 先安装本目录下的刷机驱动。
2. 运行对应的 .bat 完成 Root（镜像在 windows/bin）。
3. Magisk 与 UFI-TOOLS 安装包在上级目录 packages/，可用 adb 安装：
   adb install -r ..\packages\Magisk_28103.apk
   adb install -r ..\packages\UFI-TOOLS_WEB_V4.0.8_20260706_0234.apk

说明：为减小仓库体积，Windows 目录不再重复存放 Magisk APK；
Root 仍使用 windows/bin 内原有小文件与 spd_dump.exe。
若缺少 magisk.img，请从上级 bin/magisk.img 复制到 windows/bin/magisk.img 后再刷。
