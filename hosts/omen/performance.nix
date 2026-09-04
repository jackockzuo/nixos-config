# performance.nix —— 本机性能计算优化（HP OMEN 16 + 13900HX + 4060m）
# 职责：CPU 调度（scx）/中断均衡/功耗策略（TLP）/交换（zram）/进程资源上限
# 修改：调性能项 → 改这里；整组关闭 → options.omen.performance.enable = false
# ============================================================
{ config, lib, ... }:

let
  cfg = config.omen.performance;
in
{
  options.omen.performance.enable = lib.mkEnableOption "本机性能计算优化（13900HX + 4060m）";

  config = lib.mkIf cfg.enable {
    # 本机性能全家桶（整组关闭：options.omen.performance.enable = false）
    # - scx_lavd：交互负载 + 计算并行兼顾（13900HX P/E 核混合友好）
    # - irqbalance：13900HX 24 核，避免单个 P-Core 被网卡/磁盘中断占满
    # - TLP：AC = powersave governor + balance_performance EPP (REF:2026-08-25-omen-coil-whine)
    # - zram：内存 50% 压缩交换（抗 OOM）｜fd 上限 65536（并行编译/大数据）
    services = {
      scx = {
        enable = true;
        scheduler = "scx_lavd";
      };
      irqbalance.enable = true;
      tlp = {
        enable = true;
        settings = {
          # 修复线圈啸叫：performance → powersave (REF:2026-08-25-omen-coil-whine)
          CPU_SCALING_GOVERNOR_ON_AC = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
          # PL1/PL2 不在 TLP 设置：platform_profile=performance 时固件强制 PL1=130W (REF:2026-08-30-omen-ec-safety)
        };
      };
      power-profiles-daemon.enable = false;
    };

    # zram：计算任务占满内存时防死机
    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };

    # 进程资源：文件描述符上限（并行编译/大数据量计算需要大量 fd）
    security.pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "65536";
      }
    ];
  };
}
