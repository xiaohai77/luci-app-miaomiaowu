include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-miaomiaowu
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=第十六夜月
PKG_LICENSE:=MIT

LUCI_TITLE:=LuCI support for miaomiaowu (妙妙屋)
LUCI_DEPENDS:=+miaomiaowu

# luci.mk 会自动把这个 Makefile 同级目录下的 ./root 和 ./htdocs
# 原样装进最终 ipk，不用写 Build/Prepare、不用下载、不用写 Package/install。
# 这正好对应你仓库里已有的 luci-app-miaomiaowu/root 和 luci-app-miaomiaowu/htdocs。
include $(TOPDIR)/feeds/luci/luci.mk

$(eval $(call BuildPackage,luci-app-miaomiaowu))
