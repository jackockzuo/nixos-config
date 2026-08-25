# ============================================================
# omencore.nix —— HP OMEN 控制中心 + 功耗墙解锁（本机专属）
# 一、omercore 应用（CLI + GUI）：
#   包 packages/omencore/package.nix（官方 release 二进制，经 overlay → pkgs.omencore）
#   用途：风扇档位/占空比、RGB、性能模式、监控（hp-wmi 通道，root 写 EC）
# 二、功耗墙解锁（事故：2026-08-23 满载锁 2.5GHz，见
#     docs/troubleshooting/2026-08-23-omen-ec-power-limit-2.5ghz-lock.md）：
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
  #   当前内核（cachyos）再加载；🔴 教训（2026-08-22）：只写 kernelModules 不生效。
  # ec_sys：真正的 EC 功耗/性能寄存器通道（debugfs io），需 write_support=1 才能写。
  #   🔴 2026-08-23 关键修复：之前没加载 ec_sys → EC 一直按默认低功耗档（~25W）→ 满载锁 2.5GHz。
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
      # 🔴 2026-08-23 教训：曾加 after=["tlp.service"]，与 tlp 自身对 multi-user.target
      #    的排序冲突 → systemd 报 ordering cycle 并删除本服务启动任务（PL 停在 130W）。
      #    TLP 的 PL 配置本机写不进 rapl（无效摆设），无需排序保护，直接去掉。
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "omen-power-unlock" ''
          set -euo pipefail
          PL1_W=115   # PL1 长时全核功耗上限（W），13900HX 官方建议上限，本机散热实测有余量
          PL2_W=157   # PL2 短时睿频功耗上限（W）
          EC=/sys/kernel/debug/ec/ec0/io

          # ── 1. EC 寄存器直写（ec_sys，真正的 EC 功耗通道）──
          #    REG_THERMAL_POWER=0xBA（0-5，5=最高）。🔴 2026-08-23 实证：
          #    满载锁 2.5GHz 根因是 EC 默认低功耗档（~25W）；写 0xBA=5 后
          #    P 核 2.5→3.4GHz / E 核 2.2→2.8GHz（96°C 稳态，未降频）。
          #    （0x95 性能模式寄存器在本板 8BAB 未验证，先不写，避免副作用）
          if [ -w "$EC" ]; then
            printf '\x05' | dd of="$EC" bs=1 seek=$((0xBA)) conv=notrunc 2>/dev/null || echo "EC 0xBA 写入失败" >&2
          else
            echo "ec_sys 未加载或不可写，跳过 EC 寄存器（modprobe ec_sys write_support=1）" >&2
          fi

          # ── 2. EC 功耗限制：HP WMI WMAA 0x29（cmd_id=0x00020008, type=0x29）
          #    缓冲 = "SECU" + cmd_id(LE32) + type(1B) + 3 pad + size(LE32=4) + payload
          #    payload: PL1={FF,FF,FF,W}  PL2={W,W,FF,FF}（PL2 双字节同值，HP 固件习惯）
          #    成功判据：返回值含 0x50(P) 0x41(A) 0x53(S)。⚠️ 本机固件假 PASS（见事故档）
          send_wmaa() {
            local buf out
            buf="0x53, 0x45, 0x43, 0x55, 0x08, 0x00, 0x02, 0x00, 0x29, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, $1"
            printf '\\_SB.WMID.WMAA 0x00 0x02 {%s}' "$buf" > /proc/acpi/call 2>/dev/null || return 1
            out="$(cat /proc/acpi/call 2>/dev/null)"
            case "$out" in *0x50*) ;; *) return 1 ;; esac
            case "$out" in *0x41*) ;; *) return 1 ;; esac
            case "$out" in *0x53*) ;; *) return 1 ;; esac
            return 0
          }

          if [ -e /proc/acpi/call ]; then
            pl1_hex="$(printf '0x%02X' "$PL1_W")"
            pl2_hex="$(printf '0x%02X' "$PL2_W")"
            send_wmaa "0xFF, 0xFF, 0xFF, ''${pl1_hex}" || echo "WMAA PL1 失败（继续 rapl）" >&2
            send_wmaa "''${pl2_hex}, ''${pl2_hex}, 0xFF, 0xFF" || echo "WMAA PL2 失败（继续 rapl）" >&2
          else
            echo "/proc/acpi/call 不存在（acpi_call 未加载），跳过 WMAA" >&2
          fi

          # ── 3. RAPL（EC 允许后不再被钳回）
          R=/sys/class/powercap/intel-rapl:0
          if [ -w "$R/constraint_0_power_limit_uw" ]; then
            echo $((PL1_W * 1000000)) > "$R/constraint_0_power_limit_uw"
            echo $((PL2_W * 1000000)) > "$R/constraint_1_power_limit_uw"
          fi
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
        # 🔴 2026-08-25 修复 226/NAMESPACE 崩溃循环：
        #   旧配置 PrivateTmp=true + ReadWritePaths=/var/tmp/omencore + ExecStartPre mkdir。
        #   systemd 在 ExecStartPre 运行【之前】就要 bind-mount ReadWritePaths 的路径，
        #   而 /var/tmp/omencore 尚不存在 → "Failed to set up mount namespacing" → 226/NAMESPACE，
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
