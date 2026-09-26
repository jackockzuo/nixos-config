# hm.nix —— omen 主机专属 home 配置（2026-09-03 从共享层迁出，保证通用层可移植）
# 内容：fish perf-* 函数（依赖 omen-rs / intel-rapl，仅 OMEN 有意义）
#       fish proxy 会话变量 fcproxy_port（fcclient 后端端口，仅 OMEN 有意义）
#       niri 输出段（eDP-1 关 / HDMI-A-1 主屏 —— 桌面形态，其他机器默认自动布局）
#       noctalia 锁屏组件布局（绑定 HDMI-A-1/1080p，2026-09-26 自 GUI 覆盖层提升迁入）
#       clash-verge-rev（代理客户端 GUI；§0.5 第三方红线 → 主机剖面）
# ============================================================
{ pkgs, ... }:

{
  # n 卡双显卡：GTK 应用启动缓慢的修复（GSK 渲染器用 GL；AMD/Intel 无需，故放主机剖面）
  wayland.windowManager.niri.settings.environment.GSK_RENDERER = "gl";

  # 代理客户端 GUI：mixed-port 7892（= dae fc_backend 指向的 socks5 口），订阅/节点由 GUI 自管
  home.packages = with pkgs; [
    clash-verge-rev
  ];

  # fcclient 后端 socks 端口（hosts/omen/proxy.nix 用 7892；外部 fish proxy 函数从此变量读取）
  # 2026-09-09 声明式接管（原 fish_variables 通用变量残留）(REF:2026-09-09-fish-abbr-universal-residue)
  home.sessionVariables.fcproxy_port = "7892";

  programs.fish.functions = {
    # 性能诊断/切换（omen-rs 体系）(REF:2026-08-23-omen-ec)

    # perf-status：查看性能状态（只读，经 omend socket 免 root）
    perf-status = ''
      set -l gov (cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
      set -l epp (cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)
      set -l pl1 (cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null)
      set -l pl2 (cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null)
      echo "── EC 性能状态（omen remote perf）──"
      omen remote perf
      echo "── CPU ──"
      echo "governor         : $gov"
      echo "EPP              : $epp"
      echo "── 功耗墙 ──"
      echo "RAPL PL1/PL2     : "(math $pl1 / 1000000)"W / "(math $pl2 / 1000000)"W"
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

    # perf-unlock：用 omen-rs 解锁性能（开机由 omen-unlock.service 自动做）
    perf-unlock = ''
      echo "🔓 用 omen-rs 解锁性能..."
      sudo omen unlock
      omen remote perf
      perf-test
    '';
  };

  # Noctalia 锁屏组件布局（2026-09-26 自 GUI 覆盖层提升）
  # 绑定 HDMI-A-1 / 1920x1080 → 机器形态，故按 §0.5 放主机剖面（共享层禁机器痕迹）。
  # 设计：login box + 音频可视化 + 数字时钟 + RAM/CPU graph + 网络收发 graph。
  # ⚠️ 换显示器/分辨率后：GUI 锁屏编辑器重排 → 把新布局摘回此处（widget_order +
  #    各 widget 的 cx/cy/placement_*，参考 noctalia.nix 顶部提升工作流）。
  programs.noctalia.settings.lockscreen_widgets = {
    enabled = true;
    schema_version = 2;
    widget_order = [
      "lockscreen-login-box@HDMI-A-1"
      "lockscreen-widget-0000000000000001"
      "lockscreen-widget-0000000000000003"
      "lockscreen-widget-0000000000000004"
      "lockscreen-widget-0000000000000005"
    ];

    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };

    widget = {
      "lockscreen-login-box@HDMI-A-1" = {
        box_height = 196.0;
        box_width = 810.0;
        cx = 960.0;
        cy = 898.0;
        output = "HDMI-A-1";
        placement_height = 1080.0;
        placement_width = 1920.0;
        rotation = 0.0;
        type = "login_box";
        settings = {
          background_color = "surface_variant";
          background_opacity = 0.88;
          background_radius = 12.0;
          center_password_text = false;
          input_opacity = 1.0;
          input_radius = 6.0;
          layout = "regular";
          show_caps_lock = true;
          show_keyboard_layout = true;
          show_login_button = true;
          show_media = true;
          show_session_buttons = true;
          show_unlock_hint = true;
          show_weather = true;
        };
      };

      "lockscreen-widget-0000000000000001" = {
        box_height = 352.0;
        box_width = 368.0;
        cx = 688.0;
        cy = 412.0;
        output = "HDMI-A-1";
        placement_height = 1080.0;
        placement_width = 1920.0;
        rotation = 0.0;
        type = "fancy_audio_visualizer";
        settings = {
          background = false;
        };
      };

      "lockscreen-widget-0000000000000003" = {
        box_height = 224.0;
        box_width = 416.0;
        cx = 944.0;
        cy = 412.0;
        output = "HDMI-A-1";
        placement_height = 1080.0;
        placement_width = 1920.0;
        rotation = 0.0;
        type = "clock";
        settings = {
          background_opacity = 0.0;
          clock_style = "digital";
        };
      };

      "lockscreen-widget-0000000000000004" = {
        box_height = 160.0;
        box_width = 352.0;
        cx = 752.0;
        cy = 636.0;
        output = "HDMI-A-1";
        placement_height = 1080.0;
        placement_width = 1920.0;
        rotation = 0.0;
        type = "sysmon";
        settings = {
          background_color = "outline";
          background_opacity = 0.0;
          display = "graph";
          stat = "ram_pct";
          stat2 = "cpu_usage";
        };
      };

      "lockscreen-widget-0000000000000005" = {
        box_height = 160.0;
        box_width = 352.0;
        cx = 1184.0;
        cy = 652.0;
        output = "HDMI-A-1";
        placement_height = 1080.0;
        placement_width = 1920.0;
        rotation = 0.0;
        type = "sysmon";
        settings = {
          background_color = "outline";
          background_opacity = 0.0;
          color = "on_primary";
          color2 = "on_secondary";
          display = "graph";
          stat = "net_tx";
          stat2 = "net_rx";
        };
      };
    };
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
