# omencore.nix —— HP OMEN 性能解锁（CLI-only，主机专属）
# 2026-09-03 瘦身（feat/portability-cleanup）：移除 GUI/桌面项/pkexec/omen-hardware-perms——
#   GUI 面板只服务手动风扇/RGB 交互，且需向 wheel 开放整片 EC RAM（高风险）；
#   性能解锁全在 CLI 路径（实测 omencore-cli 单文件独立运行，无需 Skia 等 GUI 原生库）。
# 保留项 = 开机功耗墙解锁 + daemon 看门狗（EC 若重置功耗档自动重刷，REF:2026-08-30-omen-ec-safety）。
# 仅限 OMEN 主机 import；其他机器在 flake.nix hosts 清单无此目录/不 import。
# 功耗墙解锁事故链见 docs/troubleshooting/2026-08-23-omen-ec-power-limit-2.5ghz-lock.md
#   (REF:2026-08-23-omen-ec)
# ============================================================
{ config, pkgs, ... }:

{
  # hp-wmi：omercore 的 EC 控制通道（平台 profile + hwmon 风扇/PWM）。
  # 内核通常按 ACPI/WMI 设备自动加载，这里显式声明保证开机必载。
  # acpi_call：WMAA 写 EC 需要 /proc/acpi/call，独立模块包需 extraModulePackages 打包进
  #   当前内核（cachyos）再加载；教训（2026-08-22）：只写 kernelModules 不生效 (REF:2026-08-22-acpi-call)
  # ec_sys：真正的 EC 功耗/性能寄存器通道（debugfs io），需 write_support=1 才能写。
  #   2026-08-23 关键修复：之前没加载 ec_sys → EC 一直按默认低功耗档（~25W）→ 满载锁 2.5GHz (REF:2026-08-23-omen-ec)
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
    extraModprobeConfig = "options ec_sys write_support=1";
    kernelModules = [
      "hp-wmi"
      "acpi_call"
      "ec_sys"
    ];
  };

  # CLI 进全局 PATH（fish perf-* 函数、手动诊断用）
  environment.systemPackages = [ pkgs.omencore ];

  # ============ systemd 服务（2 个，一领域一文件内聚合）============
  systemd.services = {
    # 🎯 [OMEN] 功耗墙解锁（开机自动；调 EC 功耗档改 0xBA 值/瓦数改 PL1_W/PL2_W）
    omen-power-unlock = {
      description = "Unlock HP OMEN EC power limits (0xBA=5 + WMAA + RAPL) — 13900HX";
      wantedBy = [ "multi-user.target" ];
      # 2026-08-23 教训：曾加 after=["tlp.service"]，与 tlp 自身对 multi-user.target
      #    的排序冲突 → systemd 报 ordering cycle 并删除本服务启动任务 (REF:2026-08-23-omen-tlp-cycle)
      # 2026-08-30 架构优化：零裸 hex 写 EC（安全性），一切走厂商官方接口 (REF:2026-08-30-omen-ec-safety)
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "omen-power-unlock" ''
          set -euo pipefail

          # ══ 核心：OmenCore 官方接口（内部封装 hp-wmi / EC，含读回验证）══
          #   perf --mode performance  → ACPI platform_profile（固件完整性能序列）+ EC 0x95
          #   perf --power-limit 5     → EC 0xBA（热功耗倍率，OmenCore 内部验证）
          # 实测（2026-08-30）：此组合 = 满载 3.44GHz / 84°C
          ${pkgs.omencore}/bin/omencore-cli perf --mode performance --power-limit 5

          # ══ 只读确认（omencore-cli status，无副作用，仅诊断日志）══
          status=$(${pkgs.omencore}/bin/omencore-cli status --json 2>/dev/null)
          pp=$(echo "$status" | ${pkgs.jq}/bin/jq -r '.access.has_acpi_platform_profile_path // false')
          tl=$(echo "$status" | ${pkgs.jq}/bin/jq -r '.performance.thermal_power_limit // "unknown"')
          mode=$(echo "$status" | ${pkgs.jq}/bin/jq -r '.performance.mode // "unknown"')
          [ "$mode" = "performance" ] \
            || echo "⚠️ performance mode 非 performance（当前: $mode），性能解锁可能未生效" >&2
          [ "$tl" = "5" ] || echo "⚠️ thermal_power_limit=$tl（期望 5），功耗档未生效" >&2
        '';
      };
      restartIfChanged = false;
    };

    # omencore 后台守护（上游 unit 模板 + 加固）：
    #   - 维持 --hold 请求：EC 看门狗（若 EC 把功耗/性能档重置回去，daemon 自动重刷）
    omencore = {
      description = "OmenCore HP OMEN Laptop Control Daemon";
      documentation = [ "https://github.com/theantipopau/omencore" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.omencore}/bin/omencore-cli daemon --run";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        RestartSec = "5";
        User = "root";
        Environment = [
          "HOME=/root"
          "DOTNET_BUNDLE_EXTRACT_BASE_DIR=/var/lib/omencore"
        ];
        # Security hardening（上游模板）
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        # 2026-08-25 修复 226/NAMESPACE 崩溃循环：
        #   旧配置 PrivateTmp=true + ReadWritePaths=/var/tmp/omencore + ExecStartPre mkdir。
        #   systemd 在 ExecStartPre 运行【之前】就要 bind-mount ReadWritePaths 的路径，
        #   而 /var/tmp/omencore 尚不存在 → "Failed to set up mount namespacing" → 226/NAMESPACE (REF:2026-08-25-omen-namespace)
        #   改为 StateDirectory=omencore：systemd 在命名空间搭建前自动创建
        #   /var/lib/omencore（root 所有、namespace 内可写），无需手工 mkdir，也不依赖 PrivateTmp。
        StateDirectory = "omencore";
        ReadWritePaths = [
          "/var/run"
          "/var/log"
          "/sys/kernel/debug/ec"
        ];
        NoNewPrivileges = false;
      };
    };
  };
}
