# ============================================================
# hosts/omen/default.nix —— HP OMEN 16-wf0xxx 主机剖面（唯一入口）
# 职责：本机硬件（显卡/总线）、性能解锁（omencore）、性能调优、主机专属 home
# 可移植约定（STANDARDS §1）：共享层 modules/ 禁止机器专属内容；
#   新机器 = 复制本目录为 hosts/<machine>/ + flake.nix hosts 清单加一行
# ============================================================
{ my, ... }:

{
  imports = [
    ./hardware-configuration.nix # nixos-generate-config 产物（每机一份，勿手改）
    ./hardware.nix # 硬件（NVIDIA 4060 混合显卡/蓝牙/VA-API，bus id 本机专属）
    ./omencore.nix # 性能解锁 CLI-only（功耗墙 0xBA=5 + daemon 看门狗）
    ./performance.nix # 性能调优全家桶（scx/irqbalance/TLP/zram/fd）
    ./proxy.nix # 透明代理（dae → fcclient 后端，国内直连；主机专属）
    ./refind.nix # 引导：rEFInd + Minimalist 主题（GRUB 停用保留回退）
  ];

  # 本机性能调优总开关（整组关闭 → false）
  omen.performance.enable = true;

  # 主机专属 home 配置（fish perf-* 函数 / niri 输出段）
  home-manager.users.${my.username}.imports = [ ./hm.nix ];
}
