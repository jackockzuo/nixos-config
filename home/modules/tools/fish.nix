{ pkgs, my, ... }:

{
  # 1. Fish Shell 基础配置
  programs.fish = {
    enable = true;
    # 🌊 oh-my-fish 生态插件：声明式 fishPlugins 替代运行时 OMF
    # （OMF 已停止维护且与声明式配置冲突；nixpkgs 的 fishPlugins 由 Nix 构建、
    #   HM 生成 conf.d/plugin-*.fish 自动加载，插件随系统一起进入 store，完全声明式）
    # 插件名/源码均来自 pkgs.fishPlugins（nixpkgs 打包，已验证存在）
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
      # 🔍 环境侦测：是否处于容器内部
      set -l is_container (test -e /run/.containerenv; or test -n "$CONTAINER_ID")

      set fish_greeting ""

      # --- 🎨 基础配色 (无需二进制文件，容器内外通用) ---
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

      # --- 🛡️ 安全防御：仅在非容器环境（宿主机）加载的部分 ---
      if not set -q is_container[1]

          # ❄️ Fastfetch
          if type -q fastfetch
              if not set -q FASTFETCH_RUN_ONCE
                  set -gx FASTFETCH_RUN_ONCE 1
                  fastfetch
              end
          end

          # ⏱️ Done 插件
          set -g __done_min_cmd_duration 10000
          set -g __done_notify_sound 0

          # 🔗 宿主机专用别名 (通过 alias 命令动态定义)
          if type -q eza;      alias ls="eza --icons --git"; end
          if type -q bat;      alias cat="bat"; end
          if type -q lazygit;  alias lg="lazygit"; end
          if type -q nvim;     alias v="nvim"; end
          if type -q kitty;    alias ks="kitty --session work"; end

      else
          # --- 📦 容器内特殊配置 (可选) ---
          # 如果你想在容器里知道你在哪，可以改一下提示符颜色或添加提示
          # echo "📦 Inside Distrobox: (hostname)"

          # 在容器里，我们通常希望 ls 就是原生 ls，cat 就是原生 cat
          # 这里不需要写，因为我们跳过了上面的 alias 定义
      end
    '';

    # ⌨️ fish 缩写（输入短词后按空格/回车自动展开；已避开与别名/函数冲突的键）
    # 现代 HM 写法：shellAbbrs 类型为 attrsOf (either str abbrModule)，
    # 简单的 git 缩写直接用字符串值即可（即现代简化形式）；
    # 需要 position / setCursor 等高级特性时才写成 attrset
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

    # ⚙️ fish 自动加载函数（官方模块 programs.fish.functions → ~/.config/fish/functions/）
    # 注意：值 = 函数体（不含 `function <名> ... end` 外壳，HM 模块自动包裹）；
    # 布尔/字符串直接写，需要修饰符（description/wraps 等）时用 { body = ...; } 形式
    functions = {
      clean-system = ''
        echo "🧹 正在清理 Nix 废弃历史版本..."
        sudo nix-collect-garbage -d

        echo "🧹 正在清理 NixOS 旧系统代（保留最近 5 代）..."
        sudo nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system

        echo "✨ 系统保洁完成，恢复极致清爽！"
      '';

      # y (yazi 退出后 cd 回目录)：🔴 由 yazi.nix 模块的 fish 集成生成（默认开启，
      # 内容更现代：command yazi 写法）——此处不重复定义，避免同名函数体合并冲突

      # ============ 性能诊断/切换（13900HX 功耗墙体系）============
      # 原理速查：解锁链路 = omencore-cli perf（hp-wmi platform_profile 固件序列）
      #   → 固件强制 PL1≈130W → 满载 ~3.4GHz。governor/EPP 只影响轻载（8-25 啸叫修复）。

      # perf-status：查看性能状态（只读，无副作用）
      perf-status = ''
        set -l gov (cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
        set -l epp (cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)
        set -l pp (cat /sys/firmware/acpi/platform_profile 2>/dev/null)
        set -l pl1 (cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null)
        set -l pl2 (cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null)
        echo "── 性能状态 ──"
        echo "platform_profile : $pp (固件性能模式; performance=解锁)"
        echo "governor         : $gov"
        echo "EPP              : $epp"
        echo "── 功耗墙 ──"
        echo "RAPL PL1/PL2     : "(math $pl1 / 1000000)"W / "(math $pl2 / 1000000)"W (固件 performance 模式强制 ~130W)"
        echo "── EC 功耗档 0xBA (只读) ──"
        set -l ec_raw (sudo dd if=/sys/kernel/debug/ec/ec0/io bs=1 skip=186 count=1 2>/dev/null)
        set -l ec (echo $ec_raw | od -An -tu1 | string trim)
        echo "EC 0xBA          : $ec (5=已解锁)"
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

      # perf-unlock：用 OmenCore 官方接口解锁（零裸 hex 写，hp-wmi platform_profile + EC 0xBA）
      # 🔴 2026-08-30 优化：不再手动 dd 写 EC（安全性），一切走 omencore-cli；开机由 omen-power-unlock 自动做
      perf-unlock = ''
        echo "🔓 用 OmenCore 官方接口解锁性能..."
        sudo omencore-cli perf --mode performance --power-limit 5
        set -l pp (cat /sys/firmware/acpi/platform_profile 2>/dev/null)
        echo "platform_profile = $pp (期望 performance)"
        set -l ec_raw (sudo dd if=/sys/kernel/debug/ec/ec0/io bs=1 skip=186 count=1 2>/dev/null)
        set -l ec (echo $ec_raw | od -An -tu1 | string trim)
        echo "EC 0xBA = $ec (期望 5，只读确认)"
        perf-test
      '';
    };
  };
}
