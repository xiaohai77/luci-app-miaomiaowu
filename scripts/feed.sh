#!/bin/sh
# 妙妙屋 (miaomiaowu) 添加软件源（只加源，不装包）
# 用法: wget -O - https://miaomiaowu-openwrt.445568.xyz/feed.sh | ash
set -e
REPO_URL="https://miaomiaowu-openwrt.445568.xyz"

echo "=== 妙妙屋 (miaomiaowu) 添加软件源 ==="

if command -v opkg >/dev/null 2>&1; then
    echo "检测到 opkg（OpenWrt 23.05 及更早版本）"
    ARCH=$(opkg print-architecture | awk '$1=="arch" && $2!="all" && $2!="noarch" {print $3, $2}' | sort -n -r | head -n1 | awk '{print $2}')
    [ -z "$ARCH" ] && { echo "错误: 无法识别本机架构" >&2; exit 1; }
    echo "识别到架构: $ARCH"

    FEED_LINE="src/gz miaomiaowu $REPO_URL/openwrt-ipk/$ARCH"

    wget -q -O /tmp/mmw-ipk.pub "$REPO_URL/miaomiaowu-ipk.pub"
    opkg-key add /tmp/mmw-ipk.pub
    rm -f /tmp/mmw-ipk.pub

    mkdir -p /etc/opkg
    touch /etc/opkg/customfeeds.conf
    # 按包名做整行去重，重装/换架构时会把旧的一行替换掉，而不是无限累加
    sed -i '/^src\/gz miaomiaowu /d' /etc/opkg/customfeeds.conf
    echo "$FEED_LINE" >> /etc/opkg/customfeeds.conf

    opkg update

    echo "=== 软件源添加完成 ==="
    echo "现在可以执行: opkg install miaomiaowu luci-app-miaomiaowu"
    echo "也可以在 LuCI 的软件包菜单里搜 miaomiaowu 安装"

elif command -v apk >/dev/null 2>&1; then
    echo "检测到 apk（OpenWrt 25.12 及更新版本）"

    # 注意: 不能只信 `apk --print-arch`。
    # OpenWrt 的 apk 源用的是跟 opkg 一样的"精确到 CPU 型号"的架构名
    # （比如 aarch64_cortex-a53、aarch64_cortex-a72、aarch64_generic），
    # 而不是 aarch64/x86_64 这种笼统名字。但目前 OpenWrt 官方有一个已知 bug
    # （见 openwrt/openwrt#16953、#17035）：不少固件的 /etc/apk/arch 里
    # 要么只有笼统的架构名，要么内容干脆是错的，导致 apk --print-arch
    # 吐出来的值在软件源目录里根本找不到（就是你看到的
    # "packages.adb: file format is invalid or inconsistent"，
    # 本质是 wget 下载这个所谓架构目录下的 packages.adb 时 404 了）。
    # 这里改成：把 /etc/apk/arch 里列出的所有候选架构（一般是"具体型号 + all"两行）
    # 都试一遍，每个都真去下一次 packages.adb，下载成功（非空）才采用，
    # 而不是赌 apk --print-arch 给的第一个值一定存在对应目录。
    CANDIDATES=$( (cat /etc/apk/arch 2>/dev/null; apk --print-arch 2>/dev/null) \
        | tr ' ' '\n' | awk 'NF && !seen[$0]++ && $0!="all" && $0!="noarch"' )
    [ -z "$CANDIDATES" ] && { echo "错误: 无法识别本机架构（/etc/apk/arch 为空）" >&2; exit 1; }

    ARCH=""
    for CAND in $CANDIDATES; do
        echo "尝试架构: $CAND ..."
        if wget -q -O /tmp/mmw-test.adb "$REPO_URL/openwrt-apk/$CAND/packages.adb" && [ -s /tmp/mmw-test.adb ]; then
            ARCH="$CAND"
            rm -f /tmp/mmw-test.adb
            break
        fi
        rm -f /tmp/mmw-test.adb
    done

    if [ -z "$ARCH" ]; then
        echo "错误: 软件源里没有找到匹配的架构目录，已尝试: $CANDIDATES" >&2
        echo "请执行 'cat /etc/apk/arch' 确认本机架构，如果显示的是笼统名字（如 aarch64/x86_64）" >&2
        echo "而不是具体型号（如 aarch64_cortex-a53），这是 OpenWrt 官方已知问题，" >&2
        echo "可以手动把正确的具体架构名写进 /etc/apk/arch 后重试。" >&2
        exit 1
    fi
    echo "识别到架构: $ARCH"

    mkdir -p /etc/apk/keys
    wget -q -O /etc/apk/keys/miaomiaowu-apk.pem "$REPO_URL/miaomiaowu-apk.pem"

    mkdir -p /etc/apk/repositories.d
    echo "$REPO_URL/openwrt-apk/$ARCH/packages.adb" > /etc/apk/repositories.d/miaomiaowu.list

    apk update

    echo "=== 软件源添加完成 ==="
    echo "现在可以执行: apk add miaomiaowu luci-app-miaomiaowu"
    echo "也可以在 LuCI 的软件包菜单里搜 miaomiaowu 安装"

else
    echo "错误: 未检测到 opkg 或 apk" >&2
    exit 1
fi
