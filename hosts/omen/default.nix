# ============================================================
# hosts/omen/default.nix —— HP OMEN 16-wf0xxx 主机剖面（唯一入口）
# 职责：本机硬件（显卡/总线）、性能解锁（omen-rs）、性能调优、主机专属 home
# 可移植约定（STANDARDS §1）：共享层 modules/ 禁止机器专属内容；
#   新机器 = 复制本目录为 hosts/<machine>/ + flake.nix hosts 清单加一行
# ============================================================
{ my, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix # nixos-generate-config 产物（每机一份，勿手改）
    ./boot.nix # Limine 外观/品牌/分辨率/多系统/nvidia 内核参数（机器专属）
    ./hardware.nix # 硬件（NVIDIA 4060 混合显卡/蓝牙/VA-API，bus id 本机专属）
    inputs.omen-rs.nixosModules.default # 性能解锁（EC 0xBA=5 + omend 看门狗 + 温度曲线风扇）
    ./performance.nix # 性能调优全家桶（scx/irqbalance/TLP/zram/fd）
    ./proxy.nix # 透明代理（dae → fcclient 后端，国内直连；主机专属）
    ./multikernel.nix # Limine 多内核切换（latest/lts 备胎，Default=zen）
  ];

  # 本机性能调优总开关（整组关闭 → false）
  omen.performance.enable = true;

  # OMEN 控制（omen-rs module：内核模块 + omen-unlock + omend 全自动）
  services.omen = {
    enable = true;
    performance = "performance"; # EC 0xBA=5 解锁 ~130W（55W → 3.4GHz+）
    holdInterval = 30; # hold 看门狗周期（秒，对抗 EC 复位）
    batteryCare = true; # 电池养护（充电限 80%）
    logLevel = "info";
    fanCurve = [
      # 温度曲线（最高传感器温度线性插值；空 = BIOS 自动）
      {
        temp = 50;
        speed = 20;
      }
      {
        temp = 60;
        speed = 45;
      }
      {
        temp = 70;
        speed = 65;
      }
      {
        temp = 80;
        speed = 85;
      }
      {
        temp = 85;
        speed = 100;
      }
    ];
  };

  # 主机专属 home 配置（fish perf-* 函数 / niri 输出段）
  home-manager.users.${my.username}.imports = [ ./hm.nix ];
}
