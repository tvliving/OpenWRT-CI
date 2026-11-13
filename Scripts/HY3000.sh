#!/bin/bash
#飞利浦 HY3000（MT7981B + eMMC）设备支持注入
#VIKINGYFY/immortalwrt owrt 分支没有该设备，编译时从 tvliving/lede 移植：
#  1. DTS（已适配内核 6.18：显式启用 &wifi 并接 eMMC factory 分区 eeprom）
#  2. filogic.mk 机型块（sysupgrade.bin，eMMC 布局）
#  3. 02_network 网口配置（lan1-3 + wan）
#  4. platform.sh eMMC 升级路径
#WiFi 走 mt76（kmod-mt7915e）稳定方案，驱动/固件由 Config/HY3000.txt 全量选入，
#保证 LuCI「网络→无线」菜单正常出现。
#调用时机：WRT-CORE 的 Custom Packages 步骤（feeds 安装后、defconfig 前）。

set -e

LEDE_RAW="https://raw.githubusercontent.com/tvliving/lede/master"

echo "== HY3000: 注入设备支持 =="

#1) DTS
curl -sSLf --retry 3 "$LEDE_RAW/target/linux/mediatek/dts/mt7981b-philips-hy3000.dts" \
	-o target/linux/mediatek/dts/mt7981b-philips-hy3000.dts
test -s target/linux/mediatek/dts/mt7981b-philips-hy3000.dts \
	|| { echo "::error::HY3000 DTS 下载失败"; exit 1; }

#2) filogic.mk 机型块（文件尾为纯 device define 区，直接 append）
cat >> target/linux/mediatek/image/filogic.mk <<'EOF'

define Device/philips_hy3000
  DEVICE_VENDOR := Philips
  DEVICE_MODEL := HY3000
  DEVICE_DTS := mt7981b-philips-hy3000
  DEVICE_DTS_DIR := ../dts
  # mt76（kmod-mt7915e）稳定 WiFi 方案：固件自带驱动与固件，LuCI 才有无线菜单
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
	kmod-usb3 f2fsck mkf2fs
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  SUPPORTED_DEVICES += philips,hy3000
endef
TARGET_DEVICES += philips_hy3000
EOF

#3) 02_network：lan1-3 + wan（与 qihoo,360t7 同组，锚点唯一）
sed -i '/^\tqihoo,360t7|\\$/i\\tphilips,hy3000|\\' \
	target/linux/mediatek/filogic/base-files/etc/board.d/02_network

#4) platform.sh：eMMC 升级（仅插入第一处主 case 的兜底 *) 之前）
sed -i '0,/^\t\*)$/s//\tphilips,hy3000)\n\t\tCI_KERNPART="kernel"\n\t\tCI_ROOTPART="rootfs"\n\t\temmc_do_upgrade "$1"\n\t\t;;\n\t*)/' \
	target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh

#5) 校验注入结果
grep -q "philips_hy3000" target/linux/mediatek/image/filogic.mk || { echo "::error::filogic.mk 注入失败"; exit 1; }
grep -q "philips,hy3000" target/linux/mediatek/filogic/base-files/etc/board.d/02_network || { echo "::error::02_network 注入失败"; exit 1; }
grep -q "philips,hy3000" target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh || { echo "::error::platform.sh 注入失败"; exit 1; }

echo "== HY3000: 设备支持注入完成 =="
