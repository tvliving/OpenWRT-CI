# 高质量<免费>交流群

[IPQ技术讨论群](https://qm.qq.com/q/v7nMhzB4oU)

# 高质量<付费>中转站

[Krill-Code](https://www.krill-code.com/register?invite=959NHQCZGT)

# 本地编译器

https://github.com/VIKINGYFY/OWRT-Tools.git

# 自用修改版插件

https://github.com/VIKINGYFY/packages.git

# OpenWRT-CI

官方版：

https://github.com/immortalwrt/immortalwrt.git

自用版：

https://github.com/VIKINGYFY/immortalwrt.git

# U-BOOT

高通版-沉心：

https://github.com/chenxin527/uboot-qsdk12.5-build.git

高通版-小猪：

https://github.com/1980490718/u-boot-2016.git

联发科-全新版：

https://github.com/VIKINGYFY/UBOOT-CI/releases

联发科-官方版：

https://drive.wrt.moe/uboot/mediatek

# 固件简要说明

固件每天早上5点自动编译。

固件信息里的时间为编译开始的时间，方便核对上游源码提交时间。

MEDIATEK系列、QUALCOMMAX系列、ROCKCHIP系列、X86系列。

# 目录简要说明

workflows——自定义CI配置

Scripts——自定义脚本

Config——自定义配置

# 本仓库定制（tvliving fork）

- **包管理器统一为 ipk/opkg**：源码（owrt/25.12 系）`CONFIG_USE_APK` 默认 `y`，产出 `.apk`；
  `Scripts/Settings.sh` 显式写入 `# CONFIG_USE_APK is not set`，整棵构建按 ipk 打包，
  主题包 `luci-theme-*`、iStore 等全部是 `.ipk`。
- **iStore 软件中心**：`Scripts/Packages.sh` 从 `linkease/istore` 拉取
  `taskd` / `luci-lib-taskd` / `luci-lib-xterm` / `luci-app-store` 并提到 `./package/` 根下，
  `Settings.sh` 一并选入（依赖链完整，装完即用）。
- **中文**：`luci-i18n-base-zh-cn` + `files/etc/uci-defaults/99-zh-cn` 强制默认语言 `zh_cn`。
- **主题**：入口 yml 的 `WRT_THEME`（默认 `vantage`）→ 编译出 `luci-theme-vantage.ipk` 并设为默认主题。
- **设备注入**：`Scripts/Device.sh` 按 `WRT_CONFIG` 分发到 `Scripts/<机型>.sh`，
  在 `defconfig` 前补 DTS + `filogic.mk` 设备块（目前：HY3000、TR3000-512M）。
- **新增机型 Cudy TR3000 512MB 硬改版**：`MTK-TR3000-512M.yml` + `Config/TR3000-512M-WIFI-YES.txt`
  + `Scripts/TR3000-512M.sh`；定时与 `MTK-HY3000` 一致（每周一、周四 04:00）。


## Star History

<a href="https://www.star-history.com/?repos=vikingyfy%2Fopenwrt-ci&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=vikingyfy/openwrt-ci&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=vikingyfy/openwrt-ci&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=vikingyfy/openwrt-ci&type=date&legend=top-left" />
 </picture>
</a>
