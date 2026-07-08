#!/bin/bash
set -euo pipefail

APK_BIN="$1"
BINARY="$2"
ARCH="$3"
VERSION="$4"
OUTDIR="$5"
SIGN_KEY="$6"
PKG_NAME="miaomiaowu"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

ROOT="$WORK/root"
mkdir -p "$ROOT/usr/bin" "$ROOT/etc/init.d" "$ROOT/etc/config" "$ROOT/lib/apk/packages"

install -m 0755 "$BINARY" "$ROOT/usr/bin/mmw"
install -m 0755 miaomiaowu/files/miaomiaowu.init "$ROOT/etc/init.d/miaomiaowu"
install -m 0644 miaomiaowu/files/miaomiaowu.config "$ROOT/etc/config/miaomiaowu"

echo "/etc/config/miaomiaowu" > "$ROOT/lib/apk/packages/${PKG_NAME}.conffiles"
: > "$ROOT/lib/apk/packages/${PKG_NAME}.conffiles_static"
while IFS= read -r F; do
  [ -z "$F" ] && continue
  CSUM=$(sha256sum "$ROOT$F" | cut -d' ' -f1)
  echo "$F $CSUM" >> "$ROOT/lib/apk/packages/${PKG_NAME}.conffiles_static"
done < "$ROOT/lib/apk/packages/${PKG_NAME}.conffiles"

SCRIPTS="$WORK/scripts"
mkdir -p "$SCRIPTS"

cat > "$SCRIPTS/post-install" <<'EOF'
#!/bin/sh
[ -x /etc/init.d/rpcd ] && /etc/init.d/rpcd reload >/dev/null 2>&1
/etc/init.d/miaomiaowu enable
/etc/init.d/miaomiaowu start
exit 0
EOF

cat > "$SCRIPTS/pre-deinstall" <<'EOF'
#!/bin/sh
/etc/init.d/miaomiaowu stop >/dev/null 2>&1
/etc/init.d/miaomiaowu disable >/dev/null 2>&1
exit 0
EOF

chmod 0755 "$SCRIPTS/post-install" "$SCRIPTS/pre-deinstall"

(cd "$ROOT" && find . -type f,l -printf '/%P\n') > "$ROOT/lib/apk/packages/${PKG_NAME}.list"

mkdir -p "$OUTDIR"
OUT="$OUTDIR/${PKG_NAME}_${VERSION}_${ARCH}.apk"

fakeroot "$APK_BIN" mkpkg \
  --info "name:$PKG_NAME" \
  --info "version:$VERSION" \
  --info "description:Clash 配置订阅管理工具" \
  --info "arch:$ARCH" \
  --info "license:MIT" \
  --info "origin:$PKG_NAME" \
  --info "url:https://github.com/iluobei/miaomiaowu" \
  --info "maintainer:第十六夜月" \
  --info "depends:libc" \
  --script "post-install:$SCRIPTS/post-install" \
  --script "pre-deinstall:$SCRIPTS/pre-deinstall" \
  --files "$ROOT" \
  --output "$OUT" \
  --sign "$SIGN_KEY"

echo "生成: $OUT"
