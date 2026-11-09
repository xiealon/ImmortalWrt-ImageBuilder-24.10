# ImmortalWrt-ImageBuilder-24.10

ImmortalWrt **24.10.x** x86-64 固件构建线：官方 ImageBuilder 直接出固件，带 CrowdSec LXC。

eBPF 代理用 **新版 daed 三件套**（`daed` / `luci-app-daede` / `vmlinux-btf`），来自 kenzok8/openwrt-daede 的 Release，由 `build24.sh` 下进 `packages/` 当本地包安装；本线**不装 honk**。

## 四条线的差异

| | 25.12 | 25.12-honk | 25.12-daed | 24.10 |
|---|---|---|---|---|
| 用途 | **主线，官方源 + daed** | **纯 honk** | **honk（+ 预留 daed）** | 老版本线，官方源 + daed |
| workflow | 28,506 B / 496 行 | 37,645 B / 644 行 | 37,419 B / 641 行 | 27,853 B / 494 行 |
| `runs-on` | ubuntu-22.04 | **ubuntu-24.04** | **ubuntu-24.04** | ubuntu-22.04 |
| ImageBuilder | 官方 docker `x86-64-openwrt-25.12.0/1/2` | **自建 IB**，`v25.12.2-ib-x86-64-r2` | **自建 IB**，同左 | 官方 docker `24.10.0 ~ 24.10.6` |
| apk 来源 | 官方源 | **自建 pkg**，`v25.12.2-pkg-x86-64-r2` | **自建 pkg**，同左 | 官方源 |
| 版本下拉 | 3 档（25.12.0 / .1 / .2） | **1 档（25.12.2），不可切** | **1 档（25.12.2），不可切** | 7 档（24.10.0 ~ .6） |
| 主 config | `imm25.config` 303,823 B / 8,272 行 | 同左 | 同左 | `imm.config` 284,106 B / 7,705 行 |
| `=y` / `=m`（全部） | 999 / 1,227 | 999 / 1,227 | **1,002 / 1,224** | 952 / 1,005 |
| `=y` / `=m`（kmod） | 133 / 1,060 | 133 / 1,060 | **136 / 1,057** | — |
| 构建脚本 | `build25.sh` **71,078 B / 1,288 行** | `build25.sh` **67,702 B / 1,226 行** | `build25.sh` **70,544 B / 1,265 行** | `build24.sh` **54,538 B / 1,039 行** |
| 自定义包清单 | `apk-custom-packages.sh` **12,372 B** | 11,410 B | 11,287 B | `custom-packages.sh` 12,231 B |
| 内核 | **官方镜像自带** | **自建**，五项 + BTF 写死并断言，hash `26ed6bc1` | **自建**，同左 | **官方镜像自带** |
| honk 组 apk | 无 | **2 个**（`honk` + `luci-app-honk`） | **2 个，同左** | 无 |
| daed 组 apk | **3 个**（kenzok8 Release） | 无 | 无 | **3 个**，ipk，同上来源 |
| `sha256/` 目录 | 有 | 有 | 有 | 无 |
| 恢复探针 | `_pa_repair` 缺包走 `--tree`、缺文件走 `--force` | 同左 | 同左 | **同左**（2026-11-09 对齐） |
| CrowdSec LXC / rootfs-skel / 网络校验 | 有 | 有 | 有 | 有 |

> **25.12 自建线（honk / daed）现在都只装 honk 两件套**：daed 线保留了 config 里那 3 个 `=y`（总 `=y` 1,002），包清单里跑的是 honk；要装 daed 就把 `apk-custom-packages.sh` 换成 `daed luci-app-daede vmlinux-btf`，`build25.sh` 里的 honk 取包段换成 25.12 主线那份 daed 段即可。
>
> **两条官方线（25.12 / 24.10）和两条自建线的本质差别**：内核来源。自建线把 eBPF 依赖的 `CONFIG_DYNAMIC_FTRACE` 五项 + `CONFIG_DEBUG_INFO_BTF` 写死在自建内核里，构建期逐项断言，实测挂载成功（`eBPF loaded and attached`、6 个 cgroup 程序、`dae0` 建链）；两条官方线用官方镜像自带内核、不编译内核，只能靠 `vmlinux-btf` 包补 BTF，`CONFIG_DYNAMIC_FTRACE` 那几项随官方镜像走、本仓不做断言。

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

所以 7 个版本档都能用。没有 `IB_URL`、没有 `PKG_URL`、没有 sha256 固定 —— 这是与两条自建线最大的区别：那两条线的两个包都在仓库外，内核 hash 一改全部作废。

唯一从仓库外取的是 daed 三件套（`build24.sh` 的 daed 段，从 kenzok8/openwrt-daede 的 Release 下 ipk）：

| 包 | 文件 | 大小 | 说明 |
|---|---|---|---|
| `daed` | `daed_2026.11.09-r1_x86_64.ipk` | 26,107,190 B | 主程序，内嵌 Web UI |
| `luci-app-daede` | `luci-app-daede_1.15-r13_all.ipk` | 99,510 B | LuCI 界面，自带中文 |
| `vmlinux-btf` | `vmlinux-btf_6.6.151-r1_x86_64.ipk` | 1,541,735 B | BTF 包，必须与 24.10 内核（6.6.151）同版 |

`vmlinux-btf` 的版本在构建期用 `include/kernel-version.mk` 的 `LINUX_VERSION-6.6` 校验，不一致直接 `::error::` + `exit 1` —— 装错版本 daed 的 CO-RE eBPF 校验过不去。取包段会先删掉 store 的 `24-luci-app-dead_1.28-x86-64.run` 解出来的旧 `daed_1.28` ipk，避免同名不同版共存被 opkg 挑错。

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
