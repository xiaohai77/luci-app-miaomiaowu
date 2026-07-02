#!/bin/bash
# 用法: build-ipk-repo.sh <所有ipk所在目录> <输出site目录> <ipkg-make-index.sh路径> <usign二进制路径> <私钥文件路径>
# 架构从 ipk 内部 control 文件读取，不从文件名猜（文件名里 arch 本身带下划线，猜不准）
set -euo pipefail

SRC_DIR="$1"
SITE_DIR="$2"
IPKG_MAKE_INDEX="$3"
USIGN_BIN="$4"
SIGN_KEY="$5"

get_arch() {
  local ipk="$1" tmp
  tmp=$(mktemp -d)
  tar -xzf "$ipk" -C "$tmp" control.tar.gz
  tar -xzf "$tmp/control.tar.gz" -C "$tmp"
  awk -F': ' '/^Architecture:/{print $2; exit}' "$tmp/control"
  rm -rf "$tmp"
}

LUCI_IPK=$(ls "$SRC_DIR"/luci-app-miaomiaowu_*_all.ipk | head -n1)
[ -z "$LUCI_IPK" ] && { echo "错误: 没找到 luci-app-miaomiaowu 的 ipk" >&2; exit 1; }

mkdir -p "$SITE_DIR/openwrt-ipk"

for BIN_IPK in "$SRC_DIR"/miaomiaowu_*.ipk; do
  ARCH=$(get_arch "$BIN_IPK")
  [ -z "$ARCH" ] && { echo "警告: 无法识别 $BIN_IPK 的架构，跳过" >&2; continue; }
  REPO_DIR="$SITE_DIR/openwrt-ipk/$ARCH"
  mkdir -p "$REPO_DIR"
  cp "$BIN_IPK" "$REPO_DIR/"
  cp "$LUCI_IPK" "$REPO_DIR/"
done

for REPO_DIR in "$SITE_DIR"/openwrt-ipk/*/; do
  (cd "$REPO_DIR" && "$IPKG_MAKE_INDEX" . > Packages)
  gzip -kf "$REPO_DIR/Packages"
  "$USIGN_BIN" -S -m "$REPO_DIR/Packages" -s "$SIGN_KEY" -x "$REPO_DIR/Packages.sig"
  echo "已生成软件源: $REPO_DIR"
done
