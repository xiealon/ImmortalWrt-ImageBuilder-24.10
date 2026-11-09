#!/bin/bash
# 【v.180.198】固件版本标记 —— 与 crowdsec-lxc-bootstrap.sh 的 SCRIPT_VER 同步，每次改脚本一起改


CUSTOM_PACKAGES="$CUSTOM_PACKAGES aria2 luci-app-aria2 luci-i18n-aria2-zh-cn"

# 【2026-11-02】banip 移除（用户定：用不到）。
# 25.12 真机实测：三包都在、init.d ENABLED，但 ban_enabled '0'、主程序从未启动、
# 无 pidfile、无 feed、nft 里无 banip 的 set —— 一件活都没干。
# 根因是这台机器没有 WAN（只有 br-lan 192.168.1.201/24），不承担转发，
# banip 拦的是经过本机的转发/入站流量，没 WAN 就一条都用不上。
# 同类功能已由 crowdsec 覆盖：nft 里 table ip crowdsec 的三个 set 在生效，
# 防爆破也走 crowdsec 的 ssh 场景。
# 24 线这里是三包全列，删整行即整组不进固件。

CUSTOM_PACKAGES="$CUSTOM_PACKAGES ca-certificates acme luci-app-acme luci-i18n-acme-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES clashoo luci-app-clashoo luci-i18n-clashoo-zh-cn geoview kmod-tun kmod-inet-diag kmod-nft-tproxy kmod-nft-socket luci-compat bash curl ip-full unzip"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES cloudflared luci-app-cloudflared luci-i18n-cloudflared-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES crowdsec-firewall-bouncer luci-app-crowdsec-firewall-bouncer luci-i18n-crowdsec-firewall-bouncer-zh-cn"

# nftables-json：/usr/sbin/nft 归这个包。crowdsec bouncer 的 deny_action=drop 走 nft
# JSON 接口，少了它 bouncer 起得来但一条拦截都下发不了。bootstrap 里 _rom_restore_tree
# 也认 nftables-json，所以构建期必须随固件进 /rom，否则那条恢复路径两边都空。
CUSTOM_PACKAGES="$CUSTOM_PACKAGES nftables-json"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES ddns-go luci-app-ddns-go luci-i18n-ddns-go-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES dockerd luci-app-dockerman luci-i18n-dockerman-zh-cn cgroup-tools kmod-veth"

# 【2026-11-02】easytier 整组移除（用户定：组网只留 tailscale）。
# easytier 是 P2P 组网工具，与 zerotier / tailscale 同属「把设备连成虚拟局域网」，
# 功能定位重复。这条只在 24 线清单里有（25 线从来不带），所以归并 7 个穿透工具
# 时漏掉了 —— 201 是 25 线构建的，`apk info | grep easytier` 为空，看不到它。
# 24 线新固件本来会把它带进去，等于刚去掉 zerotier 又留了个功能一样的替代品。
# 整行删掉即不进固件；imm.config 里没有对应的 CONFIG_PACKAGE_easytier 条目。

# 【2026-11-02】eoip 整组移除（用户定）。EoIP 是二层 GRE 隧道，要求两端都能直连
# 建立 GRE；本机是旁路由（uci get network.wan.device 为空、只有 br-lan），没有
# 公网 IP，这条路走不通。这一行一次带进 3 个包（eoip / luci-app-eoip / i18n），
# 整行删掉即不进固件；imm.config 里 CONFIG_PACKAGE_eoip / luci-app-eoip 本就是
# not set（第 6377 / 5312 行），不必动 config。

CUSTOM_PACKAGES="$CUSTOM_PACKAGES etherwake luci-app-timewol luci-i18n-timewol-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES geoview sing-box luci-compat kmod-tun kmod-inet-diag kmod-nft-tproxy kmod-nft-socket bash curl ip-full lua unzip"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES hd-idle luci-app-hd-idle luci-i18n-hd-idle-zh-cn"

# 【2026-11-02】keepalived 移除（用户定：旁路由用不到）。
# keepalived 是 VRRP 主备漂移，要至少两台机器跑同一 VRRP 组、共享一个漂移 VIP。
# 当日 25.12 真机实测：4 个包都在，init.d ENABLED，但 UCI option enabled '0'、
# 进程未起、无漂移 VIP；/etc/keepalived/keepalived.conf 与 /rom 出厂逐字节一致
# （cmp 通过），里面的 vrrp_instance VI_1 是包自带示例，不是配置。
# 24 线这里是三包全列（keepalived + luci-app + i18n），删整行即整组不进固件。

CUSTOM_PACKAGES="$CUSTOM_PACKAGES kmod-fs-cifs cifsmount luci-app-cifs-mount luci-i18n-cifs-mount-zh-cn"

# 【v.180.165】ssrp 整组移除（用户 2026-10-29 定：daed 已可用，ssr-plus 的依赖
# 太长、探针每轮都要逐个核对，收益不值）。移除的是 ssrp 专属的：
#   界面     luci-app-ssr-plus / luci-i18n-ssr-plus-zh-cn
#   内核插件 xray-core / xray-plugin / v2ray-plugin
#   协议端   shadowsocks-rust-sslocal / ssserver、shadowsocksr-libev-ssr-redir/local/server
#   协议插件 trojan-plus / tuic-client / shadow-tls / naiveproxy / simple-obfs-client
# 刻意保留下面这些，删了会连带别处：
#   v2ray-geoip / v2ray-geosite —— mosdns 的规则来源。装，但不纳入探针保护：
#                                  上游一直更新，锁死会把人拽回旧版
#   microsocks / dns2socks / ipt2socks / chinadns-ng —— 通用 DNS 与 socks 工具
#   tcping / libopenssl3 —— 通用件
CUSTOM_PACKAGES="$CUSTOM_PACKAGES kmod-nft-tproxy kmod-nft-socket v2ray-geoip v2ray-geosite microsocks dns2socks ipt2socks chinadns-ng tcping libopenssl3"

# 【2026-11-02】usb_printer 移除，USB 打印共享只留 p910nd（下面 p910nd 那行）。
# 两者是同一件事的两个界面：/etc/init.d/usb_printer 唯一动作是 killall p910nd。
# 25.12 真机实测：/etc/config/usb_printer 是 0 字节、9100 端口没监听、无进程；
# p910nd 配置有内容。kmod-usb-printer 由下面 p910nd 那条继续带着，这里不重复列。

CUSTOM_PACKAGES="$CUSTOM_PACKAGES ksmbd-server kmod-fs-ksmbd kmod-fs-smbfs-common luci-app-ksmbd luci-i18n-ksmbd-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES liblxc lxc lxc-common lxc-templates lxc-attach lxc-auto lxc-autostart lxc-cgroup lxc-checkconfig lxc-config lxc-configs lxc-console lxc-copy lxc-create lxc-destroy lxc-device lxc-execute lxc-freeze lxc-hooks lxc-info lxc-init lxc-ls lxc-monitor lxc-monitord lxc-snapshot lxc-start lxc-stop lxc-top lxc-unfreeze lxc-unprivileged lxc-unshare lxc-user-nic lxc-usernsexec lxc-wait luci-app-lxc rpcd-mod-lxc luci-i18n-lxc-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-3ginfo-lite luci-i18n-3ginfo-lite-zh-cn usb-modeswitch usbutils"

# 【2026-11-02】luci-app-acl 移除（用户定）。
# 它是 LuCI 的「系统 → 管理权」ACL 图形编辑页（改 /etc/config/rpcd 的 ACL 段）。
# 25 线已把这块并进 luci-base 自理，不再有独立包；201 是 25 线构建的，45 个
# luci-app 里本来就没有它 —— 所以这条只影响 24 线固件。
# 删了只丢图形编辑界面，rpcd 的 ACL 仍可用 uci / 直接编辑 /etc/config/rpcd 配。
# 24 线这里是 luci-app-acl + i18n 两包，删整行即整组不进固件。

# 【2026-11-02】adblock（用户当日定：先留着，也保护起来）。
# 这条链是 i18n → luci-app-adblock → adblock，写一行三个全装；
# imm.config 里 CONFIG_PACKAGE_adblock / CONFIG_PACKAGE_luci-app-adblock 都是 not set，
# 所以固件里有没有这套全看这一行。加了它必须同步进 pkg-restore-apps.sh 的
# _PA_ADBLOCK 与 build24.sh 的 _PC_WANT，否则「装上了但被 remove 掉没人管」。
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-adblock-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-openvpn luci-i18n-openvpn-zh-cn openvpn-openssl"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-partexp luci-i18n-partexp-zh-cn e2fsprogs tune2fs blkid kmod-fs-ext4 kmod-fs-vfat"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-rtp2httpd luci-i18n-rtp2httpd-zh-cn"

# 【2026-11-02】strongswan 整组移除（用户定：用不到）。
# 原来这一行一次带进 52 个包：luci-app-strongswan-swanctl / strongswan-swanctl /
# strongswan-charon / 30 个 strongswan-mod-* / swanmon davici crconf libjson-c5 glib2 /
# kmod-ipsec{,4,6} / 9 个 kmod-crypto-* / kmod-lib-zlib-{inflate,deflate}。
# imm.config 里 CONFIG_PACKAGE_strongswan 本来就是 not set，固件里能有这套
# 全靠这一行；删了它整组不进固件，不必动 config。
# 若 glib2 / libjson-c5 / kmod-lib-zlib-* 确实被别的包依赖，opkg 解析时会自己拉，
# 不写在这儿也进得去 —— 这也是删整行而不逐个剔除的原因。

CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-taskplan luci-i18n-taskplan-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-wechatpush luci-i18n-wechatpush-zh-cn"

# daed（eBPF 代理）：改用新版 daed 三件套，来自 kenzok8/openwrt-daede。
# 【2026-11-10】用户定：官方 24.10 线改用新版 daed（本线本来就没有 honk）。
# 原来这里只有 luci-i18n-daed-zh-cn 一条 —— 光有中文语言包，没有本体和界面，
# 靠 store 的 24-luci-app-dead_1.28-x86-64.run 解出来的旧 ipk 凑数（1.28，很旧，
# 且和语言包版本对不上）。现在改成 build24.sh 直接从 Release 下这三件：
#   daed_2026.11.09-r1_x86_64.ipk          26,107,190 B  主程序，内嵌 Web UI
#   luci-app-daede_1.15-r13_all.ipk            99,510 B  LuCI 界面（含中文）
#   vmlinux-btf_6.6.151-r1_x86_64.ipk       1,541,735 B  BTF 包，与 24.10 内核同版
# vmlinux-btf 必须列：daed 的 Makefile 有 +DAED_USE_VMLINUX_BTF:vmlinux-btf，
# 缺了 make image 直接报找不到；版本还必须等于内核（6.6.151），否则 daed 的
# CO-RE eBPF 校验过不去。
CUSTOM_PACKAGES="$CUSTOM_PACKAGES daed luci-app-daede vmlinux-btf"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-proto-wireguard kmod-wireguard wireguard-tools"

# 【2026-11-02】lucky 移除（用户定：只去纯重复的，一个功能留一个）。
# lucky 是全能型（DDNS + 反向代理 + 端口转发 + Web 服务 + SSL 证书），
# 每一项在固件里都已有专用工具：DDNS → ddns-go，证书 → acme，穿透 → 其它。
# 25.12 真机实测 /etc/lucky 是空目录、enabled '0'，装了从未配置。
# 注意本行还有 yq / kmod-dummy / ca-bundle 三个通用件，只摘掉 lucky 两个包。
CUSTOM_PACKAGES="$CUSTOM_PACKAGES yq kmod-dummy ca-bundle"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES miniupnpd-nftables luci-app-upnp luci-i18n-upnp-zh-cn"

# 【2026-11-02】mosdns 移除（用户定：DNS 只留 smartdns + adblock 这条链）。
# DNS 层已有两层：smartdns 做加速/分流/缓存，adblock 生成广告黑名单喂给它
# （adblock 的 adb_dns 可设 smartdns，smartdns 的 conf_files 指向 adb 规则）。
# 再加 mosdns 是第三个分流器，默认 5335 且 redirect 会抢 53，与 smartdns 冲突。
# v2ray-geoip / v2ray-geosite 保留 —— 这两个是通用 geo 数据，geoview 与
# daed 都要用，不跟 mosdns 绑定。
# _PA_MOSDNS 保护组保留不动（新固件不带 P:mosdns，_pa_should 自动跳过）。
CUSTOM_PACKAGES="$CUSTOM_PACKAGES v2ray-geoip v2ray-geosite"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES msmtp luci-app-email luci-i18n-email-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES nfs-kernel-server nfs-utils kmod-fs-nfs kmod-fs-nfsd luci-app-nfs luci-i18n-nfs-zh-cn"

# 【2026-11-02】ngrokc 整组移除（用户定）。ngrok 反向隧道与 cloudflared 同一场景，
# 但 cloudflared 不需要公网 IP、自带证书、免费不限速，ngrokc 免费版随机域名+限速。
# 当日实测 ngrokc 服务在跑但唯一隧道 option enabled '0'，纯空转。
# 整行删掉即不进固件；imm.config 第 5354 / 6483 行本就是 not set。

CUSTOM_PACKAGES="$CUSTOM_PACKAGES nps luci-app-nps luci-i18n-nps-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES openssh-sftp-server udp2raw"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES p910nd kmod-usb-printer luci-app-p910nd luci-i18n-p910nd-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES smartdns luci-app-smartdns luci-i18n-smartdns-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES sqm-scripts luci-app-sqm luci-i18n-sqm-zh-cn"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES tailscale luci-app-tailscale-community luci-i18n-tailscale-community-zh-cn kmod-tun"

CUSTOM_PACKAGES="$CUSTOM_PACKAGES uhttpd luci-app-uhttpd luci-i18n-uhttpd-zh-cn"

# 【2026-11-02】xfrpc 整组移除（用户定）。frp 客户端必须自己有公网 VPS，
# 与 nps/npc 同类（都属「自建中转」），二选一留 nps（带 Web 管理面板 + SOCKS5）。
# 整行删掉即不进固件；imm.config 第 5462 / 6527 行本就是 not set。

CUSTOM_PACKAGES="$CUSTOM_PACKAGES xz tar liblzma gnupg getopt cgroup-tools ip-full kmod-ikconfig kmod-veth kmod-br-netfilter"
# 【2026-11-10.0420】coreutils-timeout：用户定「随固件进，并纳入 /rom 与探针保护」。
# 缺它的后果：rc.local 6 个调用点 + bootstrap 的 run/run_svc/run_tar/ct 全部退化成
# 看门狗模式（_run_capped 能兜，但每次多 fork 一个子 shell + 每秒轮询），
# /etc/init.d/crowdsec-lxc-probe 第 30 行的 `timeout 60 "$_g" quiet` 直接 not found。
# 体积：25.12.2 packages/*.apk 里 coreutils-timeout-9.9-r2.apk = 18,916 B（18.5 KB）；
#       24.10 packages/*.ipk 里 coreutils-timeout_9.7-r1_x86_64.ipk，包名同为 coreutils-timeout。
# 保护（两处，各防一种）：
#   ① pkg-restore.sh 的 _DEPS_PKGS —— 探针 _kmods_watch 每轮 --deps --check，
#      文件被删/清空时连续 PROBE_STALL_ROUNDS 轮后自动 --deps --repair 从 /rom 拷回；
#   ② bootstrap 的 _preflight —— 每次引导开头 command -v timeout，缺了就
#      _rom_restore_pkg coreutils-timeout 1（PCR_FORCE=1 强制重装，记账一起同步）。
CUSTOM_PACKAGES="$CUSTOM_PACKAGES coreutils-timeout"
