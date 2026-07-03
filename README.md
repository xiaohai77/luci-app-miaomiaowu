妙妙屋（Miaomiaowu）OpenWrt

«为 OpenWrt / ImmortalWrt 提供原生的妙妙屋安装包与 LuCI 管理界面。»

📖 项目简介

妙妙屋（Miaomiaowu）是一款现代化的代理订阅管理工具，支持订阅解析、节点管理、规则管理以及配置生成，可与主流代理核心配合使用，为不同客户端提供统一、高效的订阅管理体验。

本项目将妙妙屋移植到 OpenWrt / ImmortalWrt 平台，并提供完整的软件包、LuCI Web 管理界面以及一键安装脚本，让路由器也能获得与桌面端相同的使用体验。

---

✨ 功能特性

- 📦 原生 OpenWrt / ImmortalWrt 软件包
- 🖥️ 集成 LuCI Web 管理界面
- 🚀 一键安装，自动识别设备架构
- 🔄 自动更新软件源
- 📦 同时支持 IPK（opkg） 与 APK（apk） 软件包格式
- 🌐 Cloudflare Pages 软件源，访问速度更快
- 🔐 软件包签名校验，安装更加安全
- ⚡ GitHub Actions 自动构建与发布

---

📥 一键安装

OpenWrt / ImmortalWrt（IPK）

wget -O - https://miaomiaowu-openwrt.445568.xyz/install.sh | ash

安装脚本将自动完成：

- 检测系统架构
- 配置妙妙屋软件源
- 更新软件包索引
- 安装妙妙屋及 LuCI 管理界面

---

📦 软件包

安装完成后可获得：

- "miaomiaowu"
- "luci-app-miaomiaowu"

---

🌍 软件源

https://miaomiaowu-openwrt.445568.xyz/

软件源会根据设备架构自动提供对应的软件包。

---

🔄 更新

更新软件源：

IPK

opkg update

APK

apk update

更新妙妙屋：

IPK

opkg upgrade miaomiaowu luci-app-miaomiaowu

APK

apk upgrade

---

🧩 支持平台

- OpenWrt
- ImmortalWrt

支持 OpenWrt 官方支持的大部分 CPU 架构，并会根据设备自动选择对应的软件包。

---

🤝 致谢

感谢妙妙屋原项目作者及所有贡献者。

本仓库仅负责 OpenWrt / ImmortalWrt 平台的软件包构建、软件源维护以及自动化发布，不修改项目原有功能。

---

📄 License

妙妙屋项目版权归原项目作者所有。

本仓库中的 OpenWrt 适配、构建脚本及自动发布流程遵循仓库所采用的开源许可证。
