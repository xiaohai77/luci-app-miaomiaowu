#!/bin/bash
# 用法: build-ipk.sh <binary_path> <opkg_arch> <version> <output_dir>
# 手工拼装标准 ipk 结构：debian-binary + control.tar.gz + data.tar.gz
set -euo pipefail

BINARY="$1"
ARCH="$2"
VERSION="$3"
OUTDIR="$4"
PKG_NAME="miaomiaowu"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ---- data.tar.gz: 实际文件内容 ----
DATA="$WORK/data"
mkdir -p "$DATA/usr/bin" "$DATA/etc/init.d" "$DATA/etc/config"
install -m 0755 "$BINARY" "$DATA/usr/bin/mmw"
install -m 0755 miaomiaowu/files/miaomiaowu.init "$DATA/etc/init.d/miaomiaowu"
install -m 0644 miaomiaowu/files/miaomiaowu.config "$DATA/etc/config/miaomiaowu"

tar --numeric-owner --owner=0 --group=0 -C "$DATA" -czf "$WORK/data.tar.gz" .

# ---- control.tar.gz: 包元信息 + 安装脚本 ----
CTRL="$WORK/control"
mkdir -p "$CTRL"
INSTALLED_SIZE=$(du -sb "$DATA" | cut -f1)

cat > "$CTRL/control" <<EOF
Package: $PKG_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: 第十六夜月
Section: net
Category: Network
Depends: libc
Source: https://github.com/iluobei/miaomiaowu
License: MIT
Installed-Size: $INSTALLED_SIZE
Description: Clash 配置订阅管理工具
EOF

install -m 0755 miaomiaowu/files/postinst "$CTRL/postinst"
install -m 0755 miaomiaowu/files/prerm "$CTRL/prerm"

# 标记配置文件，opkg 升级时不会覆盖用户已修改的内容
echo "/etc/config/miaomiaowu" > "$CTRL/conffiles"

tar --numeric-owner --owner=0 --group=0 -C "$CTRL" -czf "$WORK/control.tar.gz" .

# ---- debian-binary ----
echo "2.0" > "$WORK/debian-binary"

# ---- 最终 ipk = tar.gz 归档 ----
mkdir -p "$OUTDIR"
OUT="$OUTDIR/${PKG_NAME}_${VERSION}_${ARCH}.ipk"
(cd "$WORK" && tar --numeric-owner --owner=0 --group=0 -czf "$OUT" debian-binary control.tar.gz data.tar.gz)

echo "生成: $OUT"
