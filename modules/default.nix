# ============================================================
# modules/default.nix —— 系统配置聚合入口
# 原则：一目录一领域，一文件一关注点
#   新增配置 → 新建 <关注点>.nix，并在下方 imports 加一行
#   启用预留 → 把对应行取消注释
#   修改配置 → 只编辑对应文件，不跨文件散布
# ============================================================
{
  imports = [
    ./system.nix # 系统基础（stateVersion/unfree 放行）
    ./boot.nix # 引导与内核（GRUB 双系统/内核参数）
    ./hardware.nix # 硬件（NVIDIA 混合显卡/蓝牙/zram）
    ./hardware-detect.nix # 硬件检测（initrd 模块/microcode，原 hardware-configuration.nix 去 fileSystems）
    ./network.nix # 网络（hostname/NetworkManager）
    ./users.nix # 用户与权限（ran/root/groups/shell）
    ./desktop.nix # 桌面会话（greetd + DMS + niri + portal）
    ./services.nix # 系统服务（pipewire/snapper/udisks/tlp）
    ./locale.nix # 语言/时区/输入法（fcitx5）
    ./fonts.nix # 系统字体（Maple Mono NF CN + 中文回退）
    ./nix.nix # Nix daemon（镜像源/GC/experimental-features）
    ./packages.nix # 系统级全局二进制（按用途分节）
    ./virtualisation.nix # 容器与虚拟化（podman/AppImage）
    ./nix-addons/nix-ld.nix # nix-ld（nix 管理的非 NixOS 系统）
    ./nix-addons/nix-index.nix # nix-index（nix 管理的非 NixOS 系统）
    # ---- 🔮 预留模块（需要时取消注释）----
    # ./firewall.nix # 防火墙（nftables/ufw/firewalld）
    # ./vpn.nix # VPN（WireGuard/OpenVPN/Tailscale）
    # ./databases.nix # 数据库服务（PostgreSQL/MySQL/Redis）
    # ./media-server.nix # 媒体服务（Jellyfin/Plex）
    # ./syncthing.nix # 文件同步（Syncthing）
    # ./printing.nix # 打印扫描（CUPS/SANE）
    ./security.nix # 系统安全（fail2ban/auditd/sudo 代理环境保留）
    ./proxy.nix # 代理配置单一来源（options.proxy，全系统共用）
  ];
}
