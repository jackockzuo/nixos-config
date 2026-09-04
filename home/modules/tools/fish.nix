{ pkgs, my, ... }:

{
  programs.fish = {
    enable = true;
    # oh-my-fish 生态插件：声明式 fishPlugins 替代运行时 OMF（OMF 已停止维护）
    plugins = [
      {
        name = "transient-fish";
        src = pkgs.fishPlugins.transient-fish;
      } # 命令执行后提示符自动变短
      {
        name = "done";
        src = pkgs.fishPlugins.done;
      } # 长命令完成提醒（替代原 notify-long-command 函数）
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair;
      } # 括号/引号自动配对
      {
        name = "sponge";
        src = pkgs.fishPlugins.sponge;
      } # 常用命令彩色输出
      {
        name = "bang-bang";
        src = pkgs.fishPlugins.bang-bang;
      } # !! 展开上条命令
      {
        name = "fish-you-should-use";
        src = pkgs.fishPlugins.fish-you-should-use;
      } # 存在别名时提示（学习型）
      {
        name = "bass";
        src = pkgs.fishPlugins.bass;
      } # fish 里执行 bash 命令/脚本
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit;
      } # fzf 加持的 git 操作
      {
        name = "git-abbr";
        src = pkgs.fishPlugins.git-abbr;
      } # git 命令缩写（60+ 个，带补全）
    ];
    # 将静态别名置空，改到 interactiveShellInit 中动态定义
    shellAliases = { };

    interactiveShellInit = ''
      # 容器侦测
      set -l is_container (test -e /run/.containerenv; or test -n "$CONTAINER_ID")

      set fish_greeting ""

      # 基础配色（catppuccin mocha fallback，matugen 生成覆盖优先）
      set fish_color_normal #cdd6f4
      set fish_color_command #89b4fa
      set fish_color_param #cdd6f4
      set fish_color_error #f38ba8
      set fish_color_quote #a6e3a1
      set fish_color_operator #94e2d5
      set fish_color_redirection #f9e2af
      set fish_color_autosuggestion #585b70
      set fish_color_selection --background=#585b70
      set fish_color_search_match --background=#585b70
      set fish_color_cwd #a6e3a1
      set fish_color_valid_path --underline
      set fish_color_option #f5c2e7

      if test -f ~/.config/fish/colors.matugen.fish
          source ~/.config/fish/colors.matugen.fish
      end

      # 宿主机专用（容器内跳过）
      if not set -q is_container[1]

          # Fastfetch
          if type -q fastfetch
              if not set -q FASTFETCH_RUN_ONCE
                  set -gx FASTFETCH_RUN_ONCE 1
                  fastfetch
              end
          end

          # Done 插件
          set -g __done_min_cmd_duration 10000
          set -g __done_notify_sound 0

          # 宿主机别名
          if type -q eza;      alias ls="eza --icons --git"; end
          if type -q bat;      alias cat="bat"; end
          if type -q lazygit;  alias lg="lazygit"; end
          if type -q nvim;     alias v="nvim"; end
          if type -q kitty;    alias ks="kitty --session work"; end

      else
          # 容器内：保持原生命令（跳过 alias 定义）
      end
    '';

    # fish 缩写（输入短词后按空格/回车自动展开）
    shellAbbrs = {
      # ── NixOS 高频 ──
      nr = "sudo snapper -c root create -t single -d nr && sudo snapper -c home create -t single -d nr && sudo nixos-rebuild switch --flake ~/nixos-config#${my.hostname}";
      tg = "topgrade"; # 一键更新链（flake update + 检查 + 预构建切换）

      # ── git 高频 ──
      gst = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gpl = "git pull";
      gl = "git log --oneline --graph";
      gd = "git diff";

      # ── 目录导航（极高频）──
      ".." = "cd ..";
      "..." = "cd ../..";

      # ── 终端高频 ──
      ll = "eza -l --icons=auto --git"; # 长格式列表（替代原 la 函数）
      clip = "wl-copy"; # 剪贴板（配合 cliphist）
    };

    # fish 自动加载函数（值 = 函数体，HM 自动包裹 function ... end）
    functions = {
      clean-system = ''
        echo "🧹 正在清理 Nix 废弃历史版本..."
        sudo nix-collect-garbage -d

        echo "🧹 正在清理 NixOS 旧系统代（保留最近 5 代）..."
        sudo nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system

        echo "✨ 系统保洁完成，恢复极致清爽！"
      '';

      # yazi 退出后 cd 回目录（由 yazi.nix 模块 fish 集成生成，不重复定义）

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
  };
}
