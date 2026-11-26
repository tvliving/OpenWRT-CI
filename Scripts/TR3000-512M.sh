#!/bin/bash
#Cudy TR3000 512MB 硬改版（MT7981 + 512MB NAND）设备支持注入
#VIKINGYFY/immortalwrt 的 owrt 分支只有 128MB（cudy_tr3000-v1）与 256MB 变体，
#没有 512MB 扩容机型，编译前补两样东西：
#  1. DTS：与官方 256MB 变体同构，include 官方 dtsi，只覆盖 model/compatible 与
#     ubi 分区大小（0x1FA40000 ≈ 506MiB；官方 128MB 是 0x4000000，256MB 是 0xe600000）
#  2. filogic.mk 设备块：cudy_tr3000-512mb-v1（IMAGE_SIZE 520000k，KERNEL_IN_UBI）
#02_network / platform.sh 不用改：compatible 仍是 cudy,tr3000-v1，走官方同一套网口与 ubi 升级路径。
#调用时机：WRT-CORE 的 Custom Packages 步骤（feeds 安装后、defconfig 前）。

set -e

DTS_FILE="target/linux/mediatek/dts/mt7981b-cudy-tr3000-512mb-v1.dts"
BASE_DTSI="target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1.dtsi"
FILOGIC_MK="target/linux/mediatek/image/filogic.mk"

echo "== TR3000-512M: 注入设备支持 =="

#0) 官方 dtsi 必须在，512MB DTS 是它的 include + ubi 分区覆盖
test -f "$BASE_DTSI" || { echo "::error::源码缺少 $BASE_DTSI，无法派生 512MB DTS"; exit 1; }

#1) DTS（与官方 256MB 变体同构：include dtsi + 只覆盖 ubi 分区大小）
cat > "$DTS_FILE" <<'EOF'
// SPDX-License-Identifier: (GPL-2.0 OR MIT)

#include "mt7981b-cudy-tr3000-v1.dtsi"

/ {
	model = "Cudy TR3000 512MB v1";
	compatible = "cudy,tr3000-v1", "mediatek,mt7981";
};

&spi_nand {
	spi-cal-enable;
	spi-cal-mode = "read-data";
	spi-cal-datalen = <7>;
	spi-cal-data = /bits/ 8 <0x53 0x50 0x49 0x4E 0x41 0x4E 0x44>;
	spi-cal-addrlen = <5>;
	spi-cal-addr = /bits/ 32 <0x0 0x0 0x0 0x0 0x0>;

	mediatek,nmbm;
	mediatek,bmt-max-ratio = <1>;
	mediatek,bmt-max-reserved-blocks = <64>;
};

&ubi {
	reg = <0x5c0000 0x1FA40000>;
};
EOF

#2) filogic.mk 设备块（末尾追加，幂等）
if ! grep -q 'Device/cudy_tr3000-512mb-v1' "$FILOGIC_MK"; then
	cat >> "$FILOGIC_MK" <<'EOF'

define Device/cudy_tr3000-512mb-v1
  DEVICE_VENDOR := Cudy
  DEVICE_MODEL := TR3000
  DEVICE_VARIANT := v1 (512M)
  DEVICE_DTS := mt7981b-cudy-tr3000-512mb-v1
  DEVICE_DTS_DIR := ../dts
  SUPPORTED_DEVICES += R47
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 520000k
  KERNEL_IN_UBI := 1
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount
endef
TARGET_DEVICES += cudy_tr3000-512mb-v1
EOF
fi

#3) 校验注入结果
test -s "$DTS_FILE" || { echo "::error::DTS 注入失败"; exit 1; }
grep -q 'Device/cudy_tr3000-512mb-v1' "$FILOGIC_MK" || { echo "::error::filogic.mk 注入失败"; exit 1; }
grep -q 'TARGET_DEVICES += cudy_tr3000-512mb-v1' "$FILOGIC_MK" || { echo "::error::TARGET_DEVICES 未追加"; exit 1; }

echo "== TR3000-512M: 设备支持注入完成（DTS + filogic.mk） =="
