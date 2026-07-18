# F50 B16 Root 与 UFI-TOOLS 安装包

给 **中兴 F50 / U30 Air（系统版本 B16）** 用的工具包，主要做两件事：

1. **Root**：写入带 Magisk 的启动分区，并带上禁用系统自动更新相关处理  
2. **安装 UFI-TOOLS**：在电脑上通过网络 ADB，把完整版管理工具装进设备

> 只适用于 **B16**。其它版本不要用这个包，否则可能把 Wi‑Fi 弄坏（例如 Wi‑Fi 5 变成 Wi‑Fi 4）。

仓库地址：<https://github.com/Xio-Shark/f50-b16>

---

## 你需要准备什么

### Mac（推荐按本仓库根目录脚本操作）

```bash
brew install libusb android-platform-tools
```

当前自带的 `bin/spd_dump` 面向 **Apple Silicon（M 系列）**。若是 Intel Mac，先在本机执行：

```bash
./rebuild_spd_dump.sh
```

### Windows

1. 安装 `windows/刷机驱动_SPD_Driver_R4.20.4201` 里的驱动  
2. 使用 `windows` 目录下的 `.bat` 脚本

### 下载刷机镜像和安装包（必做）

为方便上传，较大的镜像和 APK 放在 GitHub Release，不直接放进 Git。克隆仓库后先执行：

```bash
cd /path/to/f50-b16
chmod +x ./*.sh ./bin/spd_dump
./download_assets.sh
```

会下载：

- `bin/magisk.img`（Root 用）
- `bin/magisk.img.tcp_min`（打开网络 ADB 用）
- `packages/Magisk_28103.apk`
- `packages/UFI-TOOLS_WEB_V4.0.8_20260706_0234.apk`

---

## 强烈建议先备份

刷任何东西之前先备份。设备先 **拔线并彻底关机**，再运行备份脚本，最后按提示插线。

Mac：

```bash
./00-备份读分区.sh
```

失败时再依次试：

```bash
./00-备份读分区.sh kick0
./00-备份读分区.sh kick1
./00-备份读分区.sh short
```

成功标志：生成的 `backup_时间戳` 目录里有体积正常的 `boot` / `trustos` 等文件。

出问题立刻还原：

```bash
./06-从备份还原.sh
```

---

## 推荐流程（Mac）：Root → 开网络 ADB → 装 UFI-TOOLS

也可以运行菜单，按提示选：

```bash
./菜单.sh
```

### 第 1 步：Root

设备关机 → **先运行脚本** → 再插数据线：

```bash
./01-直接插电-一键Root.sh
```

如果提示超时或模式不对，再试：

- `./02-直接插电-一键Root-备用2.sh`
- `./03-直接插电-一键Root-备用3.sh`
- 或 `./04-短接模式-一键Root.sh`（关机后短接调试点的同时插线，看到进度再松手）

Root 成功后，先确认手机热点 / 设备 Wi‑Fi 功能正常。

### 第 2 步：刷「可网络连接」的启动分区

这一步只改启动分区，用来打开设备上的网络调试端口（`192.168.0.1:5555`）。  
**不会**靠 USB 线在 Mac 上出现传统的 `adb devices` 设备列表——这款机器在 Mac 上通常要用网络连接。

```bash
./07-只刷boot-TCP-ADB.sh
```

不行再试短接：

```bash
./07b-短接-只刷boot-TCP-ADB.sh
```

### 第 3 步：电脑连上 F50 的 Wi‑Fi，安装 Magisk 和 UFI-TOOLS

```bash
./09-安装完整版UFI-TOOLS.sh
```

脚本会安装：

- `packages/Magisk_28103.apk`
- `packages/UFI-TOOLS_WEB_V4.0.8_20260706_0234.apk`

然后：

1. 在设备上打开 Magisk，按提示完成安装（**不要换成其它 Magisk 版本**）  
2. 浏览器访问：`http://192.168.0.1:2333` 打开 UFI-TOOLS  
3. 需要的高级功能在 UFI-TOOLS 页面里开启

如果只想先装 Magisk、不装 UFI-TOOLS：

```bash
./08-验证TCP-ADB并装Magisk.sh
```

---

## 目录说明

| 路径 | 作用 |
|------|------|
| `00`～`09`、`菜单.sh` | Mac 一键脚本 |
| `bin/` | 刷机程序与镜像（含 Root 用 `magisk.img`、网络 ADB 用 `magisk.img.tcp_min`） |
| `packages/` | Magisk 28103 与 UFI-TOOLS 完整版安装包 |
| `patch_tcp_adb/` | 如需重新生成网络 ADB 镜像时使用 |
| `windows/` | Windows 原版脚本、驱动与镜像 |
| `注意事项.txt` | 刷机安全说明 |

---

## 常见问题

**Mac 上 `adb devices` 是空的？**  
正常。这款设备在 Mac 上常见情况是没有可用的 USB ADB 接口。Root 并刷完第 2 步后，请：

```bash
adb connect 192.168.0.1:5555
```

**提示 `kick reboot timeout`？**  
改用短接模式脚本；一般不用拔线、也不用关掉当前脚本。

**提示 `wrong command or wrong mode detected`？**  
电源键 + 音量上键按 7–10 秒强制重启，再试短接或备用脚本。

**刷完 Wi‑Fi 变差了？**  
多半刷错了系统版本。本包只给 B16 用。尽快用备份还原。

**F50 插上 Type‑C 就自己开机？**  
这是正常现象，它靠 Type‑C 供电时经常会自动开机，不像手机那样必须长按电源。

---

## 风险说明

- 写启动分区有变砖风险，请务必先备份  
- 版本不匹配可能影响无线功能  
- 第三方软件版权归原作者：  
  - Magisk：<https://github.com/topjohnwu/Magisk>  
  - UFI-TOOLS：<https://github.com/kanoqwq/UFI-TOOLS>  
  - 刷写工具基于 [spreadtrum_flash](https://github.com/TomKing062/spreadtrum_flash)

本仓库仅整理便于 B16 设备使用的脚本与安装包，使用前请自行评估风险。
