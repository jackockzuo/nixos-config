# omencore.nix —— HP OMEN 控制中心 + 功耗墙解锁
# 一、omercore 应用（CLI + GUI）：
#   包 packages/omencore/package.nix（官方 release 二进制，经 overlay → pkgs.omencore）
#   用途：风扇档位/占空比、RGB、性能模式、监控（hp-wmi 通道，root 写 EC）
# 二、功耗墙解锁（事故：2026-08-23 满载锁 2.5GHz，见
#     docs/troubleshooting/2026-08-23-omen-ec-power-limit-2.5ghz-lock.md）(REF:2026-08-23-omen-ec)：
#   - 真根因：EC 默认低功耗档（~25W TDP），RAPL 寄存器只是"纸面数字"，
#     WMAA（\_SB.WMID.WMAA）固件假 PASS（内核日志 WMAA aborts）
#   - 唯一实证通道：ec_sys 直写 EC 寄存器 REG_THERMAL_POWER=0xBA（0-5，5=最高）
#     —— 参考 OmenCore LinuxEcController（src/OmenCore.Linux/Hardware/LinuxEcController.cs）
#   - 顺序：写 0xBA=5 → WMAA（尽力而为）→ RAPL（PL1=115W/PL2=157W）
# ============================================================
{ config, pkgs, ... }:

{
  # hp-wmi：omercore 的 EC 控制通道（平台 profile + hwmon 风扇/PWM）。
  # 内核通常按 ACPI/WMI 设备自动加载，这里显式声明保证开机必载。
  # acpi_call：WMAA 写 EC 需要 /proc/acpi/call，独立模块包需 extraModulePackages 打包进
  #   当前内核（cachyos）再加载；教训（2026-08-22）：只写 kernelModules 不生效 (REF:2026-08-22-acpi-call)
  # ec_sys：真正的 EC 功耗/性能寄存器通道（debugfs io），需 write_support=1 才能写。
  #   2026-08-23 关键修复：之前没加载 ec_sys → EC 一直按默认低功耗档（~25W）→ 满载锁 2.5GHz (REF:2026-08-23-omen-ec)
  # pkexec setuid wrapper：omencore-gui-root 依赖 pkexec 弹系统密码框以 root 运行 GUI。
  # 🔴 NixOS 26.x 起 polkit 模块默认不启用 pkexec wrapper（enablePkexecWrapper 默认 false）→
  #   不加此项 omencore 桌面项直接报 "pkexec must be setuid root"。
  security.polkit.enablePkexecWrapper = true;

  boot = {
    extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
    extraModprobeConfig = "options ec_sys write_support=1";
    kernelModules = [
      "hp-wmi"
      "acpi_call"
      "ec_sys"
    ];
  };

  environment.systemPackages = [
    pkgs.omencore
    # GUI root 启动器（桌面项 Exec 指向它）：pkexec 弹系统密码框 → 以 root 运行，
    # 保留会话环境（X/Wayland/DBus/渲染模式），让 GUI 全部硬件功能可用。
    # pkexec 走本机已在跑的 polkit-gnome 认证代理（niri spawn-at-startup），无需 sudoers
    (pkgs.writeShellScriptBin "omencore-gui-root" ''
      exec pkexec env \
        DISPLAY="$DISPLAY" \
        XAUTHORITY="$XAUTHORITY" \
        XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
        DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
        OMENCORE_GUI_RENDER_MODE="$OMENCORE_GUI_RENDER_MODE" \
        /run/current-system/sw/bin/omencore-gui "$@"
    '')
  ];

  # ============ systemd 服务（3 个，一领域一文件内聚合）============
  systemd.services = {
    # 🎯 [OMEN] 功耗墙解锁（开机自动；调瓦数改下面 PL1_W/PL2_W，调 EC 功耗档改 0xBA 值）
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
    #   - 提供 daemon 状态/配置自动应用；diagnose 里 unit 不再是 "not installed"
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
        #   服务自 32 次重启失败，EC 看门狗/风扇控制从未生效。
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

    # 硬件控制权限：让普通用户（wheel，本机 ran）能用 GUI 控制全部硬件功能。
    # 路径 = OmenCore Linux 后端（LinuxEcController/LinuxHwMonController）实际写的位置：
    #   ① hp-wmi hwmon pwm*（风扇档位/占空比）
    #   ② ACPI platform_profile（性能模式）
    #   ③ ec_sys debugfs EC io（功耗限制 0xBA / 性能模式寄存器 0x95）
    # ⚠️ 风险：EC io = 整个 EC RAM，wheel 可写任意寄存器；单机可接受（ran=wheel），他机勿照抄。
    #   键盘 RGB/电池阈值在 OmenCore Linux 版未实现（空 stub），无需开放。
    omen-hardware-perms = {
      description = "Open HP OMEN hardware controls to wheel group (fan/perf/power)";
      wantedBy = [ "multi-user.target" ];
      # 确保 ec_sys/hp-wmi 已由 systemd-modules-load 加载、路径已出现
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "omen-hardware-perms" ''
          set -eu
          # ① 风扇（hp-wmi hwmon）
          P=/sys/devices/platform/hp-wmi/hwmon
          chown root:wheel "$P"/hwmon*/pwm* "$P"/hwmon*/fan* 2>/dev/null || true
          chmod 0664 "$P"/hwmon*/pwm* "$P"/hwmon*/fan* 2>/dev/null || true
          # ② 性能模式（ACPI platform_profile）
          chown root:wheel /sys/firmware/acpi/platform_profile 2>/dev/null || true
          chmod 0664 /sys/firmware/acpi/platform_profile 2>/dev/null || true
          # ③ EC 寄存器（ec_sys debugfs）
          #    debugfs 父目录默认 root-only（0700）→ 根给 o+x（只遍历不可列目录），
          #    ec/ec0 收窄给 wheel（0750），io 0664 root:wheel
          chmod o+x /sys/kernel/debug 2>/dev/null || true
          chown root:wheel /sys/kernel/debug/ec /sys/kernel/debug/ec/ec0 2>/dev/null || true
          chmod 0750 /sys/kernel/debug/ec /sys/kernel/debug/ec/ec0 2>/dev/null || true
          chown root:wheel /sys/kernel/debug/ec/ec0/io 2>/dev/null || true
          chmod 0664 /sys/kernel/debug/ec/ec0/io 2>/dev/null || true
        '';
      };
      restartIfChanged = false;
    };
  };
}
