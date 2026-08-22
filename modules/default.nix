# ============================================================
# modules/default.nix —— 系统配置聚合入口（定位地图）
# 导入顺序：基础设施 → 服务 → 应用；每行带职责注释，新增在此加一行
# ============================================================
{
  imports = [
    ./system.nix # 系统基础（stateVersion/unfree）
    ./boot.nix # 引导与内核（GRUB 双系统/内核参数）
    ./hardware.nix # 硬件（NVIDIA 混合显卡/蓝牙/VA-API）
    ./network.nix # 网络（hostname/NetworkManager/BBR）
    ./users.nix # 用户与权限（ran/root/groups/shell）
    ./desktop.nix # 桌面会话（greetd + DMS + niri + portal）
    ./services.nix # 系统服务（pipewire/snapper/udisks/keyring/thermald）
    ./performance.nix # 🎯 本机性能计算优化（scx/irqbalance/TLP/zram/fd）
    ./locale.nix # 语言/时区/输入法（fcitx5 + IM 变量单一来源）
    ./nix.nix # Nix daemon（镜像源/GC/缓存/chaotic + nix-ld/nix-index）
    ./packages.nix # 系统级二进制 + 系统字体（按用途分节）
    ./virtualisation.nix # 容器与虚拟化（podman/AppImage/FUSE）
    ./proxy.nix # 代理配置单一来源（options.proxy + sudo env_keep）
    ./secrets.nix # sops-nix 秘密管理（GitHub token/密码，见 STANDARDS §6）
  ];

  # 🎯 [OMEN] 性能全家桶总开关：默认 false（options.omen.performance.enable）
  #    显式打开——scx/irqbalance/TLP(AC performance + PL 解除)/zram/fd 全部生效。
  #    2026-08-22：曾因默认 false 未打开 → 满载仅 2.5GHz（PL 墙未解除）+ 68°C。
  #    整组关闭/故障对比 → 改为 false（STANDARDS §2 🎯 标记）
  omen.performance.enable = true;
}
