# OpenWrt-妙妙屋

[妙妙屋 (miaomiaowu)](https://github.com/iluobei/miaomiaowu) 的 OpenWrt 软件包 & 软件源仓库。

miaomiaowu 本体是一个 Clash 配置订阅管理工具，支持节点管理、生成订阅、导入外部订阅节点、聚合流量、聚合订阅等功能。这个仓库不包含 miaomiaowu 的业务代码，只负责**把上游源码交叉编译成 OpenWrt 路由器能装的软件包，并托管成一个可以 `opkg`/`apk` 直接安装更新的软件源**。

- 上游项目：`https://github.com/iluobei/miaomiaowu`
- 软件源地址：<https://miaomiaowu-openwrt.445568.xyz>

## 前置要求

- OpenWrt 23.05 及更早 → 使用 `opkg`
- OpenWrt 25.12 及更新 → 使用 `apk`

两种包管理器都支持，脚本会自动识别，不用自己判断。

## 特性

- **新旧包管理器都支持**：同时产出传统 `opkg`（ipk）和新版 `apk`（OpenWrt 25.12+）两种包
- **全架构覆盖**：arm64 / armv7 / armv6 / armv5 / riscv64 / x86 / amd64，一次交叉编译覆盖对应的所有具体 opkg 架构型号
- **带 LuCI 管理界面**：`luci-app-miaomiaowu` 提供网页端配置入口
- **签名软件源**：ipk 用 `usign` 签名，apk 用 EC 私钥签名，脚本会自动装好对应公钥

## 安装 & 更新

### A. 一键安装（推荐）

```sh
wget -O - https://miaomiaowu-openwrt.445568.xyz/install.sh | ash
```

自动识别 opkg 还是 apk、自动识别本机架构、装源、装包一步到位。

安装完成后访问 `http://路由器IP:8080` 使用，或在 LuCI 里找到"妙妙屋"菜单项进行网页配置。

### B. 添加软件源

1. 添加软件源

```sh
# 只需要执行一次
wget -O - https://miaomiaowu-openwrt.445568.xyz/feed.sh | ash
```

2. 安装

```sh
# 也可以在 LuCI 的“软件包”菜单里搜 miaomiaowu 安装
# opkg
opkg install miaomiaowu
opkg install luci-app-miaomiaowu
# apk
apk add miaomiaowu
apk add luci-app-miaomiaowu
```

日后有新版本，正常走 `opkg update && opkg upgrade miaomiaowu`（或 `apk update && apk upgrade`）就行，不用重新跑脚本。

## 卸载

```sh
wget -O - https://miaomiaowu-openwrt.445568.xyz/uninstall.sh | ash
```

会卸载 `miaomiaowu`、`luci-app-miaomiaowu` 两个包，并删除数据目录

## 配置

服务由 `/etc/config/miaomiaowu` 驱动，procd 管理：

```
config miaomiaowu 'miaomiaowu'
	option enabled '1'
	option port '8080'
	option database_path '/etc/mmw/traffic.db'
	option log_level 'info'
```

改完执行 `/etc/init.d/miaomiaowu restart` 生效，或者直接在 LuCI 网页里改。

## 免责声明

本仓库只做打包分发，不对 miaomiaowu 本体的功能、安全性做背书，问题请优先到[上游仓库](https://github.com/iluobei/miaomiaowu)反馈；打包/软件源相关的问题（装不上、签名校验失败、架构识别错误等）欢迎在本仓库提 issue。

## License

MIT

## 手动本地打包（调试用）

```sh
# 以 arm64 为例，编译前需要自己 checkout 好上游源码并 npm run build 前端
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o mmw-bin ./cmd/server
./scripts/build-ipk.sh mmw-bin aarch64_cortex-a53 1.0.0 ./dist
```

## 免责声明

本仓库只做打包分发，不对 miaomiaowu 本体的功能、安全性做背书，问题请优先到[上游仓库](https://github.com/iluobei/miaomiaowu)反馈；打包/软件源相关的问题（装不上、签名校验失败、架构识别错误等）欢迎在本仓库提 issue。

## License

MIT
