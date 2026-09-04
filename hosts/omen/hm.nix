# hm.nix —— omen 主机专属 home 配置（2026-09-03 从共享层迁出，保证通用层可移植）
# 内容：fish perf-* 函数（依赖 omencore-cli / intel-rapl，仅 OMEN 有意义）
#       niri 输出段（eDP-1 关 / HDMI-A-1 主屏 —— 桌面形态，其他机器默认自动布局）
# ============================================================
_:

{
  programs.fish.functions = {
    # 性能诊断/切换（omencore-cli 体系）(REF:2026-08-23-omen-ec)

    # perf-status：查看性能状态（只读，无副作用）
    perf-status = ''
      set -l gov (cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
      set -l epp (cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)
      set -l pl1 (cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null)
      set -l pl2 (cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null)
      set -l status (omencore-cli status --json 2>/dev/null)
      set -l pp (echo $status | jq -r '.performance.mode // "unknown"')
      set -l ec (echo $status | jq -r '.performance.thermal_power_limit // "unknown"')
      set -l hold (echo $status | jq -r '.performance.hold_enabled // false')
      echo "── 性能状态 ──"
      echo "performance mode: $pp (performance=解锁)"
      echo "governor         : $gov"
      echo "EPP              : $epp"
      echo "── 功耗墙 ──"
      echo "RAPL PL1/PL2     : "(math $pl1 / 1000000)"W / "(math $pl2 / 1000000)"W"
      echo "thermal_power_limit (EC 0xBA): $ec (5=已解锁)"
      echo "hold enabled     : $hold"
      if test "$pp" = "performance"; and test "$ec" = "5"
          echo "✅ 性能已解锁 (满载应 ~3.4GHz，跑 perf-test 验证)"
      else
          echo "❌ 未解锁 → 跑 perf-unlock"
      end
    '';

    # perf-boost：临时拉满（只调 EPP，无啸叫风险；重负载睿频更激进）
    perf-boost = ''
      echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference >/dev/null
      echo "⚡ EPP → performance (需要时贴着顶跑；用 perf-economy 恢复)"
    '';

    # perf-economy：恢复平衡（日常推荐，轻载省电静音）
    perf-economy = ''
      echo balance_performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference >/dev/null
      echo "🌿 EPP → balance_performance (平衡模式)"
    '';

    # perf-test：32 核满载测频率（验证解锁是否生效）
    perf-test = ''
      echo "🏋️  32 核满载 6 秒采样..."
      for i in (seq 32)
          yes >/dev/null &
      end
      sleep 6
      awk -F: '/MHz/{s+=$2; n++} END{printf "满载平均: %.0f MHz (上限 5200)\n", s/n}' /proc/cpuinfo
      jobs -p | xargs -r kill 2>/dev/null
      echo "参考: 已解锁(固件 130W) → ~3400 MHz；未解锁(55W) → ~2000 MHz"
    '';

    # perf-unlock：用 omencore-cli 解锁性能（开机由 omen-power-unlock 自动做）
    perf-unlock = ''
      echo "🔓 用 OmenCore 官方接口解锁性能..."
      sudo omencore-cli perf --mode performance --power-limit 5
      set -l status (omencore-cli status --json 2>/dev/null)
      set -l pp (echo $status | jq -r '.performance.mode // "unknown"')
      set -l ec (echo $status | jq -r '.performance.thermal_power_limit // "unknown"')
      echo "performance mode = $pp (期望 performance)"
      echo "thermal_power_limit (EC 0xBA) = $ec (期望 5，只读确认)"
      perf-test
    '';
  };

  # 桌面形态输出段（原 home/modules/desktop/niri-rules.nix，2026-09-03 迁出）
  # 其他机器不 import 本文件 → niri 走默认自动布局，不会误关内屏
  wayland.windowManager.niri.settings._children = [
    # ================ 输出（原 output.kdl）================
    # eDP-1（笔记本内屏）：关闭（外接 HDMI 为主屏）
    {
      output = {
        _args = [ "eDP-1" ];
        off = { };
      };
    }
    # HDMI-A-1（主显示器）
    {
      output = {
        _args = [ "HDMI-A-1" ];
        mode = "1920x1080@144";
        scale = 1;
        position = {
          _props = {
            x = 0;
            y = 0;
          };
        };
        "focus-at-startup" = { };
      };
    }
  ];
}
