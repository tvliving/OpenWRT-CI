#!/bin/bash
#私有扩展脚本：所有构建都会在 Packages.sh 末尾 source 本文件
#设备支持注入已统一收口到 Scripts/Device.sh（由 WRT-CORE 的 Custom Packages 步骤调用），
#这里不要再调用 HY3000.sh / TR3000-512M.sh，否则会重复注入 DTS 与 filogic.mk 设备块。
#需要私有插件或配置时，在本文件里追加即可。
