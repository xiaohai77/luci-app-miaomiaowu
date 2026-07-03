# OpenWrt-mmw

[妙妙屋 (miaomiaowu)](https://github.com/iluobei/miaomiaowu) 的 OpenWrt 软件包 & 软件源仓库。

miaomiaowu 本体是一个 Clash 配置订阅管理工具，支持节点管理、生成订阅、导入外部订阅节点、聚合流量、聚合订阅等功能。这个仓库不包含 miaomiaowu 的业务代码，只负责**把上游源码交叉编译成 OpenWrt 路由器能装的软件包，并托管成一个可以 `opkg`/`apk` 直接安装更新的软件源**。

- 软件源地址：`https://miaomiaowu-openwrt.445568.xyz`
- 上游项目：<https://github.com/iluobei/miaomiaowu>

## 特性

- **自动跟新**：每 6 小时检测一次上游 Release，有新版本自动交叉编译、打包、签名、部署，全程不用人工干预
- **新旧包管理器都支持**：同时产出传统 `opkg`（ipk）和新版 `apk`（OpenWrt 25.12+）两种包
- **全架构覆盖**：arm64 / armv7 / armv6 / armv5 / riscv64 / x86 / amd64，一次交叉编译覆盖对应的所有具体 opkg 架构型号
- **带 LuCI 管理界面**：`luci-app-miaomiaowu` 提供网页端配置入口
- **签名软件源**：ipk 用 `usign` 签名，apk 用 EC 私钥签名，一键安装脚本会自动装好对应公钥
- **一条命令安装**，自动识别 opkg / apk 环境和本机架构

## 安装

路由器上执行（自动识别 opkg 还是 apk，自动识别架构）：

```sh
wget -O - https://miaomiaowu-openwrt.445568.xyz/install.sh | ash
```

安装完成后访问 `http://路由器IP:8080` 使用，或在 LuCI 里找到"妙妙屋"菜单项进行网页配置。

### 手动安装

**opkg（OpenWrt 23.05 及更早）**

```sh
wget -O /tmp/mmw.pub https://miaomiaowu-openwrt.445568.xyz/miaomiaowu-ipk.pub
opkg-key add /tmp/mmw.pub
echo "src/gz miaomiaowu https://miaomiaowu-openwrt.445568.xyz/openwrt-ipk/<你的架构>" >> /etc/opkg/customfeeds.conf
opkg update
opkg install miaomiaowu luci-app-miaomiaowu
```

**apk（OpenWrt 25.12 及更新）**

```sh
mkdir -p /etc/apk/keys
wget -O /etc/apk/keys/miaomiaowu-apk.pem https://miaomiaowu-openwrt.445568.xyz/miaomiaowu-apk.pem
echo "https://miaomiaowu-openwrt.445568.xyz/openwrt-apk/<你的架构>/packages.adb" > /etc/apk/repositories.d/miaomiaowu.list
apk update
apk add miaomiaowu luci-app-miaomiaowu
```

> `<你的架构>` 是 opkg/apk 的具体 CPU 型号名（如 `aarch64_cortex-a53`），不是笼统的 `aarch64`/`x86_64`。不确定的话直接用上面的一键脚本，它会自己试出正确的架构目录。

### 卸载

```sh
opkg remove miaomiaowu luci-app-miaomiaowu   # 或 apk del miaomiaowu luci-app-miaomiaowu
```

数据不会自动清除，需要保留升级用；如果要彻底删干净，再手动删掉数据目录（默认 `/etc/mmw`）。

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

## 项目结构

```
miaomiaowu/files/          # ipk/apk 共用的 UCI 配置模板、procd 服务脚本、pre/postinst
luci-app-miaomiaowu/       # LuCI 前端插件包源码
scripts/
  arch-map.sh              # go-target ↔ opkg 具体架构名的映射表
  build-ipk.sh              # 手工拼装单个 ipk（debian-binary + control.tar.gz + data.tar.gz）
  build-apk.sh               # 手工拼装单个 apk（APKv3 格式，调用 apk mkpkg）
  build-ipk-repo.sh          # 把一批 ipk 按架构归类，生成签名过的 Packages 索引
  build-apk-index.sh         # 给单个架构目录生成签名过的 packages.adb 索引
  build-luci-ipk.sh / build-luci-apk.sh   # 打包 LuCI 插件（arch=all，两种格式各一份）
  install.sh                 # 部署到软件源根目录的一键安装脚本（自动识别 opkg/apk + 架构）
keys/                       # ipk 签名公钥
.github/workflows/
  check-upstream.yml         # 每 6 小时轮询上游 Release，触发下面两个打包 workflow
  build-ipk.yml               # 交叉编译 + 打 ipk，发布到 GitHub Release
  build-apk.yml               # 交叉编译 + 打 apk，发布到 GitHub Release
  deploy.yml                  # 从 Release 里拉包，生成软件源目录结构，部署到 Cloudflare Pages
```

## 打包流程是怎么跑起来的

1. `check-upstream.yml` 定时轮询 `iluobei/miaomiaowu` 的最新 Release，版本没变就跳过
2. 有新版本时，并发触发 `build-ipk.yml` 和 `build-apk.yml`：两者都是 checkout 上游源码 → `npm run build` 前端 → 按 `arch-map.sh` 的映射表交叉编译多个 Go target → 用对应的 `build-ipk.sh`/`build-apk.sh` 手工拼包 → 发布成 GitHub Release（tag 为上游版本号）
3. 两个打包 workflow 中只要有一个成功，就触发 `deploy.yml`：从 Release 下载所有 ipk/apk，按架构归类进 `site/openwrt-ipk/<arch>/` 和 `site/openwrt-apk/<arch>/`，分别生成签名索引（`Packages`/`packages.adb`），连同公钥、`install.sh`、目录浏览页一起部署到 Cloudflare Pages

也就是说**这个仓库本身不含 miaomiaowu 的业务源码**，每次都是实时拉上游最新代码现编的，保证发布的包和上游 Release 内容一致。

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
