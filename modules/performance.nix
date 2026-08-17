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
    # ============ CPU 调度：sched-ext 用户态调度器 ============
    # scx_lavd：交互负载 + 计算并行兼顾（13900HX P/E 核混合架构友好），
    # 与 cachyos BORE 调度互为补充（scx 运行在 BPF 层覆盖全局调度）。
    # 🔴 若 scx.service 启动失败不影响登录（内核自动回退 CFS），验证：systemctl status scx
    services.scx = {
      enable = true;
      scheduler = "scx_lavd";
    };

    # ============ 中断均衡：多核分摊硬件中断 ============
    # 13900HX 24 核，避免单个 P-Core 被网卡/磁盘中断占满
    services.irqbalance.enable = true;

    # ============ 功耗策略：TLP（电池管理 + AC 性能 governor）============
    # TLP 与 power-profiles-daemon 互斥（NixOS 断言），必须显式关后者（DMS 默认 mkDefault true）
    services.tlp = {
      enable = true;
      settings = {
        # 🔴 性能计算需求：AC 电源下 performance governor（最高频）
        #    scx_lavd 叠加；电池保持 TLP 默认 powersave 省电；
        #    ⚠️ AC 恒频发热上升，thermald（services.nix）兜底散热。
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
      };
    };
    services.power-profiles-daemon.enable = false;

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
