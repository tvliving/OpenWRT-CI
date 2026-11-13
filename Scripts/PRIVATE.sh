#!/bin/bash
#私有扩展脚本：所有构建都会在 Packages.sh 末尾 source 本文件
#HY3000：设备支持不在 VIKINGYFY/immortalwrt owrt 分支里，按需注入
if [ "$WRT_CONFIG" = "HY3000" ]; then
	bash "$GITHUB_WORKSPACE/Scripts/HY3000.sh"
fi
