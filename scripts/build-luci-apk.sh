#!/bin/bash
# 用法: build-luci-apk.sh <apk二进制路径> <version> <输出目录> <签名私钥pem路径>
set -euo pipefail

APK_BIN="$1"
VERSION="$2"
OUTDIR="$3"
SIGN_KEY="$4"
PKG_NAME="luci-app-miaomiaowu"
SRC="luci-app-miaomiaowu"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

ROOT="$WORK/root"
mkdir -p "$ROOT"
cp -r "$SRC/root/." "$ROOT/"
mkdir -p "$ROOT/www/luci-static"
cp -r "$SRC/htdocs/luci-static/." "$ROOT/www/luci-static/"
mkdir -p "$ROOT/lib/apk/packages"

# ---- 文件清单：必须最后生成，否则会把自己也列进去 ----
(cd "$ROOT" && find . -type f,l -printf '/%P\n') > "$ROOT/lib/apk/packages/${PKG_NAME}.list"

mkdir -p "$OUTDIR"
OUT="$OUTDIR/${PKG_NAME}_${VERSION}_all.apk"

fakeroot "$APK_BIN" mkpkg \
  --info "name:$PKG_NAME" \
  --info "version:$VERSION" \
  --info "description:LuCI support for 妙妙屋 (miaomiaowu)" \
  --info "arch:noarch" \
  --info "license:MIT" \
  --info "origin:$PKG_NAME" \
  --info "maintainer:第十六夜月" \
  --info "depends:luci-base miaomiaowu" \
  --files "$ROOT" \
  --output "$OUT" \
  --sign "$SIGN_KEY"

echo "生成: $OUT"
