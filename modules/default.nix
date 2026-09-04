# ============================================================
# modules/default.nix —— 系统配置聚合入口（定位地图，平台无关）
# 导入顺序：基础设施 → 服务 → 应用；每行带职责注释，新增在此加一行
# 机器专属（硬件/性能解锁/主机 home）→ hosts/<machine>/，禁止进入本文件
# ============================================================
{
  imports = [
    ./system.nix # 系统基础（stateVersion/unfree）
    ./boot.nix # 引导与内核（GRUB 双系统/内核参数）
    ./network.nix # 网络（NetworkManager/BBR；hostname/hostId 由 hosts 注入 my）
    ./users.nix # 用户与权限（ran/root/groups/shell）
    ./desktop.nix # 桌面会话（greetd + DMS + niri + portal）
    ./services.nix # 系统服务（pipewire/snapper/udisks/keyring/thermald）
    ./locale.nix # 语言/时区/输入法（fcitx5 + IM 变量单一来源）
    ./nix.nix # Nix daemon（镜像源/GC/缓存/chaotic + nix-ld/nix-index）
    ./packages.nix # 系统级二进制 + 系统字体（按用途分节）
    ./virtualisation.nix # 容器与虚拟化（podman/AppImage/FUSE）
    ./secrets.nix # sops-nix 秘密管理（GitHub token/密码，见 STANDARDS §6）
  ];
}
