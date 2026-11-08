# ImmortalWrt-ImageBuilder-24.10

ImmortalWrt **24.10.x** x86-64 固件构建线：官方 ImageBuilder 直接出固件，带 CrowdSec LXC。

## 四条线的差异

| | 25.12 | 25.12-honk | 25.12-daed | 24.10 |
|---|---|---|---|---|
| 用途 | **主线，官方源 + honk** | **纯 honk** | **honk + daed** | 老版本线，维护用 |
| workflow | 28,506 B / 496 行 | 37,645 B / 644 行 | 37,419 B / 641 行 | 27,853 B / 494 行 |
| `runs-on` | ubuntu-22.04 | **ubuntu-24.04** | **ubuntu-24.04** | ubuntu-22.04 |
| ImageBuilder | 官方 docker `x86-64-openwrt-25.12.0/1/2` | **自建 IB**，`v25.12.2-ib-x86-64-r2` | **自建 IB**，同左 | 官方 docker `24.10.0 ~ 24.10.6` |
| apk 来源 | 官方源 | **自建 pkg**，`v25.12.2-pkg-x86-64-r2` | **自建 pkg**，同左 | 官方源 |
| 版本下拉 | 3 档（25.12.0 / .1 / .2） | **1 档（25.12.2），不可切** | **1 档（25.12.2），不可切** | 7 档（24.10.0 ~ .6） |
| 主 config | `imm25.config` 303,823 B / 8,272 行 | 同左 | 同左 | `imm.config` 284,106 B / 7,705 行 |
| `=y` / `=m`（全部） | 999 / 1,227 | 999 / 1,227 | **1,002 / 1,224** | 952 / 1,005 |
| `=y` / `=m`（kmod） | 133 / 1,060 | 133 / 1,060 | **136 / 1,057** | — |
| 构建脚本 | `build25.sh` **68,177 B / 1,234 行** | `build25.sh` **67,172 B / 1,218 行** | `build25.sh` **70,667 B / 1,264 行** | `build24.sh` **50,349 B / 950 行** |
| 自定义包清单 | `apk-custom-packages.sh` **12,089 B** | 11,356 B | 11,356 B | `custom-packages.sh` 11,263 B |
| 内核 | **官方**，无 `DYNAMIC_FTRACE` | **自建**，ftrace 五项 + BTF，hash `26ed6bc1` | **自建**，同左 | 官方 |
| honk 组 apk | **默认装**（5 个，从 `honk-apk` Release 取） | **5 个，从 `honk-apk` Release 取** | **5 个** | 无 |
| daed 组 apk | 随包清单进固件 | 无 | **6 个** | 无 |
| `sha256/` 目录 | 有 | 有 | 有 | 无 |
| CrowdSec LXC / rootfs-skel / 网络校验 | 有 | 有 | 有 | 有 |

> **两条 25.12 自建线（honk / daed）的差别**：daed 线多 `daed` / `daed-geoip` / `daed-geosite` / `luci-app-daed` / `luci-i18n-daed-zh-cn` / `kmod-xdp-sockets-diag` 六个包，config 里对应 3 个 `=y`（总 `=y` 从 999 到 1,002）。
>
> **主线（25.12）和两条自建线的本质差别**：内核。自建内核开了 `CONFIG_DYNAMIC_FTRACE` 五项 + `CONFIG_DEBUG_INFO_BTF`，honk 才能把 eBPF 程序挂到内核函数上；官方镜像的内核没开这些，honk 装得上、LuCI 里能点，就是起不来。

**完整的 CrowdSec LXC 运行期逻辑、网络与防火墙校验、`rootfs-skel` 契约 → [CROWDSEC.md](https://github.com/xiealon/ImmortalWrt-ImageBuilder-25.12/blob/master/CROWDSEC.md)；v.103 起的改动记录 → [CHANGELOG.md](https://github.com/xiealon/ImmortalWrt-ImageBuilder-25.12/blob/master/CHANGELOG.md)**

---

## 这个仓库是什么

给 x86-64 软路由出一份带 CrowdSec LXC 的 ImmortalWrt 固件。固件内容由三样东西决定：

- 官方 ImageBuilder 镜像 `immortalwrt/imagebuilder:x86-64-openwrt-24.10.x`
- `x86-64/imm.config` 里勾选的包
- `x86-64/build24.sh` 里写的后处理

三样都与 25.12 线**结构相同、内容不同**。没有自建 IB 包，没有自建 apk 全集，没有内核 hash 约束。

本仓库只在你明确要留在 24.10 内核线时才有意义。

---

## 构建输入

不需要下载任何自建包。workflow 直接用 Docker Hub 上的官方镜像，tag 跟着下拉框走：

```
immortalwrt/imagebuilder:x86-64-openwrt-${luci_version}
```

所以 7 个版本档都能用。没有 `IB_URL`、没有 `PKG_URL`、没有 sha256 固定 —— 这是与 honk 线最大的区别：那条线两个包都在仓库外，内核 hash 一改全部作废。

---

## 版本档位

Profile 按**硬盘标称容量**选，rootfs 已扣掉标称换算损耗（10^9 → GiB 乘 0.9313）和 swap：

| 选 | rootfs |
|---|---|
| 8G盘 | 4G（4096） |
| 16G盘 | 10G（10240） |
| 32G盘 | 22G（22528） |
| 64G盘 | 50G（51200） |
| 128G盘 | 108G（110592） |
| 256G盘 | 224G（229376） |

超出这张表的 profile 直接 `::error::` + `exit 1`，不会静默回落到默认值。改档位时下拉框、白名单、这份 case 映射三处必须一起改，只改一处就是埋雷。

分区大小和固件大小是两件事：img 里未使用的空间全是零，gzip 压完仍然只有几百 MB，224G 分区的固件也能正常刷写。

---

## 怎么构建

1. Actions → **Build 24.10.x x86-64** → Run workflow
2. `Luci Version` 选 24.10.0 ~ 24.10.6 之一，**选哪个就拉哪个 tag**
3. `Profile` 按硬盘大小选
4. 填 `Router IP`（仅对多网口路由器有效），其余留空即用默认

产物在 run 的 artifact 与 Release 里，文件名带版本与档位后缀。

---

## 改动这个仓库前要知道的两件事

1. **`build24.sh` 与 `build25.sh` 不是同一份文件，但逻辑要同步**。CrowdSec 后处理改一边时，回看另一条线是否也该改；改完两边都要能跑。
2. **这里的 `=y` 只表示装进固件**（`CONFIG_PACKAGE_*=y`），和 25.12 线同义。它不改 ImageBuilder 自带的官方内核。

---

## 许可

- 本仓库代码：**GPL-3.0**（见 [LICENSE](LICENSE)）
- 构建产出的固件：继承 ImmortalWrt 的 **GPL-2.0**

GPL-2.0 与 GPL-3.0 不兼容，边界必须分清：**脚本是 3.0，固件是 2.0**。

上游 ImageBuilder 工作流出自 [wukongdaily/AutoBuildImmortalWrt](https://github.com/wukongdaily/AutoBuildImmortalWrt)，其说明文字版权归原作者所有，本仓库不再复制原文。
