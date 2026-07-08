#!/bin/sh
set -e

echo "=== 妙妙屋 (miaomiaowu) 卸载 ==="

if command -v opkg >/dev/null 2>&1; then
    echo "检测到 opkg（OpenWrt 23.05 及更早版本）"
    opkg remove luci-app-miaomiaowu 2>/dev/null || true
    opkg remove miaomiaowu 2>/dev/null || true

elif command -v apk >/dev/null 2>&1; then
    echo "检测到 apk（OpenWrt 25.12 及更新版本）"
    apk del luci-app-miaomiaowu 2>/dev/null || true
    apk del miaomiaowu 2>/dev/null || true

else
    echo "错误: 未检测到 opkg 或 apk" >&2
    exit 1
fi

echo "删除数据目录 /etc/mmw"
rm -rf /etc/mmw

echo "=== 卸载完成 ==="
