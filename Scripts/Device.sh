#!/bin/bash
# SPDX-License-Identifier: MIT
#设备支持注入分发：源码树里没有的机型在这里补 DTS + filogic.mk 设备块
#调用时机：WRT-CORE 的 Custom Packages 步骤（feeds 安装后、defconfig 前）
#新增机型时：写 Scripts/<机型>.sh，再在这里加一条 case 分支。

set -e

echo "== Device: WRT_CONFIG=$WRT_CONFIG =="

case "$WRT_CONFIG" in
	HY3000)
		bash "$GITHUB_WORKSPACE/Scripts/HY3000.sh"
		;;
	TR3000-512M*)
		bash "$GITHUB_WORKSPACE/Scripts/TR3000-512M.sh"
		;;
	*)
		echo "no device injection needed for $WRT_CONFIG"
		;;
esac
