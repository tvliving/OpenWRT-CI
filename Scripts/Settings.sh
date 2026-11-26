#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#移除luci-app-attendedsysupgrade
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "/attendedsysupgrade/d" {} +
#修改默认主题
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" {} +
#移除原生默认主题 bootstrap（所有配置统一使用 WRT_THEME 指定的默认主题，当前全部为 vantage）
if [ "$WRT_THEME" != "bootstrap" ]; then
	rm -rf ./feeds/luci/themes/luci-theme-bootstrap
	echo "# CONFIG_PACKAGE_luci-theme-bootstrap is not set" >> ./.config
fi
#修改immortalwrt.lan关联IP
find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js" -exec sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" {} +
#添加编译日期标识
find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js" -exec sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" {} +

#修改默认WIFI账号密码
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
ROUTER_TOOL="./package/emortal/luci-app-router-tool/root/etc/config/router-tool"
for file in "$ROUTER_TOOL" "$WIFI_UC"; do
	[ -f "$file" ] && sed -i "s/ssid '.*'/ssid '$WRT_SSID'/g; s/key '.*'/key '$WRT_WORD'/g" "$file"
done

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#包管理器：强制 ipk（opkg）
#源码（owrt / 25.12 系）的 config/Config-build.in 里 CONFIG_USE_APK 默认 y，产出 .apk；
#统一关掉后整棵构建按 ipk 打包，主题包 luci-theme-* 也随之是 .ipk。
if grep -q 'config USE_APK' ./config/Config-build.in 2>/dev/null; then
	echo "# CONFIG_USE_APK is not set" >> ./.config
	echo "package manager: ipk (CONFIG_USE_APK disabled)"
fi

#iStore 软件中心（ipk 市场）：包源码由 Scripts/Packages.sh 从 linkease/istore 拉取
#依赖链：luci-app-store -> luci-lib-taskd -> luci-lib-xterm + taskd
echo "CONFIG_PACKAGE_luci-app-store=y" >> ./.config
echo "CONFIG_PACKAGE_luci-lib-taskd=y" >> ./.config
echo "CONFIG_PACKAGE_luci-lib-xterm=y" >> ./.config
echo "CONFIG_PACKAGE_taskd=y" >> ./.config

#中文：LuCI 简体中文包 + 强制默认 zh_cn（而不是 auto 跟随浏览器）
echo "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" >> ./.config
mkdir -p ./files/etc/uci-defaults
cat > ./files/etc/uci-defaults/99-zh-cn <<'EOF'
#!/bin/sh
#强制 LuCI 默认语言为简体中文（覆盖 auto 探测）
uci -q set luci.main.lang='zh_cn'
uci -q commit luci
exit 0
EOF
chmod 755 ./files/etc/uci-defaults/99-zh-cn

#引入私有扩展配置
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
	echo "Applying private configurations from PRIVATE.txt..."
	cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#内核 6.18 冲突：kmod-nft-bridge 的 FILES=$(NFT_BRIDGE-m) 会把
#net/bridge/netfilter/nf_conntrack_bridge.ko 也打进去，而内核 default install 强制装
#kmod-nf-conntrack-bridge（同一个 ko），firmware install 阶段 check_data_file_clashes 让
#package/install Error 255。kmod-nf-conntrack-bridge 是内核自动带入、.config 关不掉，
#所以改源码 netfilter.mk：在 nft-bridge 的 FILES/AUTOLOAD 里用 filter-out 把
#bridge/netfilter/nf_conntrack_bridge 从 $(NFT_BRIDGE-m) 去掉，其余 ko 与路径保持原样
#（不能硬编码 nft_bridge.ko 路径——该内核里它不在 net/bridge/netfilter/ 下）。
#该 ko 仍由 kmod-nf-conntrack-bridge 正常提供，bridge 表功能不受影响。
NFMK="./package/kernel/linux/modules/netfilter.mk"
if grep -q 'KernelPackage/nf-conntrack-bridge' "$NFMK" 2>/dev/null && grep -q 'define KernelPackage/nft-bridge' "$NFMK" 2>/dev/null; then
	python3 - "$NFMK" <<'PY'
import io, sys, re
p = sys.argv[1]
s = io.open(p, encoding='utf-8').read()
m = re.search(r'(define KernelPackage/nft-bridge\n.*?\nendef)', s, re.S)
if not m:
    print('kernel clash fix: nft-bridge define 未找到，跳过')
    sys.exit(0)
blk = m.group(1)
orig = blk
# 用 filter-out 剔除重复的 conntrack_bridge 模块，路径仍由 $(NFT_BRIDGE-m) 给出
blk = blk.replace('$(NFT_BRIDGE-m)',
                  '$(filter-out bridge/netfilter/nf_conntrack_bridge,$(NFT_BRIDGE-m))')
if blk != orig:
    s = s[:m.start()] + blk + s[m.end():]
    io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print('kernel clash fix: kmod-nft-bridge 用 filter-out 剔除重复 conntrack_bridge.ko')
else:
    print('kernel clash fix: 未匹配到 $(NFT_BRIDGE-m)，跳过')
PY
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#无WIFI配置调整Q6大小
	if [[ "$WRT_WIFI" == "WIFI-NO" ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi
