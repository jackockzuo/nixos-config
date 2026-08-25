# ============================================================
# performance.nix —— 本机性能计算优化（🎯 本机专属，HP OMEN 16 + 13900HX + 4060m）
# 职责：CPU 调度（scx）/中断均衡/功耗策略（TLP）/交换（zram）/进程资源上限
# 修改：调性能项 → 改这里；整组关闭 → options.omen.performance.enable = false
# 关联：boot.nix（cachyos 内核 + scx 内核支持）、network.nix（BBR）、hardware.nix（VA-API/挂载）
# ============================================================
{ config, lib, ... }:

let
  cfg = config.omen.performance;
in
{
  # 🎯 [OMEN] 本机独有性能计算总开关（一键启用/关闭整组优化，便于对比与故障隔离）
  options.omen.performance.enable = lib.mkEnableOption "本机性能计算优化（13900HX + 4060m）";

  config = lib.mkIf cfg.enable {
    # ============ 本机性能全家桶（🎯 [OMEN]，整组关闭：options.omen.performance.enable = false）============
    # - scx_lavd：交互负载 + 计算并行兼顾（13900HX P/E 核混合友好），与 cachyos BORE 互为补充
    #   （scx 运行在 BPF 层覆盖全局调度）；🔴 若 scx.service 启动失败不影响登录（内核自动回退 CFS）
    # - irqbalance：13900HX 24 核，避免单个 P-Core 被网卡/磁盘中断占满
    # - TLP：AC = powersave governor + balance_performance EPP（🔴 2026-08-25 修复：
    #   performance governor 让 CPU 持续高频率 → VRM 线圈啸叫（登录桌面后"嗞嗞"声），
    #   powersave 允许空闲降到 800MHz，实测声音消失；负载时 HWP 仍会睿频到全速，
    #   性能无损失，PL1/PL2 解锁照常生效），电池 = powersave；
    #   TLP 与 power-profiles-daemon 互斥（NixOS 断言），必须显式关后者
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
          # 🔴 2026-08-25 修复线圈啸叫：performance → powersave（用户实测验证）
          CPU_SCALING_GOVERNOR_ON_AC = "powersave";
          # 配套：EPP 从 performance（TLP 默认）降到 balance_performance，
          # 轻负载时不再顶高频（防残留啸叫），重负载睿频不受影响
          CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
          # 🔴 解除 AC 插电功耗墙（13900HX 缩缸防护确认：满载仅 68°C，
          #    余量 30°C，解除安全）。PL1=115W（长时全核）/ PL2=157W（短时睿频）
          #    为 13900HX 官方建议上限；电池模式不设 PL（TLP 默认保守省电）。
          # 🎯 [OMEN] 本机散热验证过的值——他机复制需先实测满载温度
          PL1_LIMIT_AC = "115";
          PL2_LIMIT_AC = "157";
        };
      };
      power-profiles-daemon.enable = false;
    };

    # ============ 内存交换：zram（压缩内存 swap）============
    # 计算任务占满内存时防死机；比 SSD 交换快一个数量级
    # 🎯 memoryPercent = 50（物理内存一半）：比常规 1/4 更抗 OOM，代价是压缩 CPU 开销
    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };

    # ============ 进程资源：文件描述符上限 ============
    # 并行编译/大数据量计算需要大量 fd（默认 1024 不够）
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
