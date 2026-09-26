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

      # 1. 待机/低负载区：保持绝对安静（低于 40 度风扇甚至可以考虑停转或极低转速）
      {
        temp = 35;
        speed = 10; # 约 960 RPM，无感静音
      }
      {
        temp = 45;
        speed = 15; # 约 1400 RPM
      }
      # 2. 轻度办公/网页区：温和起步，不让转速频繁波动引起噪音
      {
        temp = 50;
        speed = 20; # 约 1920 RPM
      }
      # 3. 中度负载/看视频/轻度游戏：开始积极散热
      {
        temp = 60;
        speed = 28; # 约 2680 RPM
      }
      {
        temp = 70;
        speed = 32; # 约 3840 RPM
      }
      # 4.重度游戏/编译/渲染区：提前强力压制，预留安全余量
      {
        temp = 78;
        speed = 40; # 约 5120 RPM
      }
      # 5. 极限保护区：温度逼近危险线前直接拉满风扇（100%）
      {
        temp = 85;
        speed = 64; # 64 即 6400 RPM（全速运行）
      }

    ];
  };

  # 主机专属 home 配置（fish perf-* 函数 / niri 输出段）
  home-manager.users.${my.username}.imports = [ ./hm.nix ];
}
