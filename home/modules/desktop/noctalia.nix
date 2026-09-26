{
  lib,
  ...
}:

{
  # ============================================================
  # noctalia.nix —— Noctalia v5 桌面壳（原生 C++/Wayland shell，TOML 配置）
  #
  # 配置分层模型（2026-09-26 DMS→Noctalia 迁移，替代原 dms.nix 的写回 hack）：
  # - Nix 层（此处 settings）→ ~/.config/noctalia/config.toml（构建期 checkConfig 校验）
  # - GUI 修改 → ~/.local/state/noctalia/settings.toml（加载最后，覆盖 Nix 层同名键）
  #   ⚠️ 若某 Nix 设置"不生效"，先查 GUI 覆盖层是否已有该键（GUI 改动会赢）
  # - 通知/剪贴板历史/锁屏/壁纸/启动器/电源菜单/OSD/polkit agent 均为 shell 内置，
  #   已相应移除 swaync/cliphist/polkit-gnome/hyprlock（锁屏 2026-09-26 切 Noctalia 内置）
  # - NixOS 侧模块（programs.noctalia.enable）见 modules/desktop.nix
  #
  # GUI 覆盖层 → Nix 层提升工作流（自定义 bar/dock/启动器/锁屏组件等时）：
  #   1. GUI 里调一次 → ~/.local/state/noctalia/settings.toml 记录精确键名与合法取值
  #   2. 把该键提升进下方 settings（checkConfig 构建期校验，试错成本为零）
  #   3. 删除覆盖层中对应键（声明式接管后不留隐性运行时状态）
  #      ⚠️ 时序：bar.default 与 lockscreen_widgets 是 shell 的一等运行时状态
  #      （config_service 监听 state 目录，外部改写后会把自己的内存值重新落盘），
  #      运行中的 shell 会把删掉的这两段原样写回。必须先 `nr` 切换 + 重启会话
  #      （新 base 已含提升值），再删这两段；此后如被重写也是同值，无害。
  # 已提升（2026-09-26）：theme / bar.default / notification / shell.panel /
  #   widget.launcher / widget.tray；lockscreen_widgets → hosts/omen/hm.nix
  #   （绑定 HDMI-A-1/1080p 机器形态，§0.5）。
  # 留在 GUI 层：wallpaper（日常随 GUI 换，非设计基线；见下方壁纸注释）。
  # ============================================================

  programs.noctalia = {
    enable = true;
    systemd.enable = true; # user service 跟随 wayland.systemd.target（niri 会话）
    checkConfig = true; # 构建期跑 `noctalia config validate`，键名错误构建即报

    settings = {
      theme = {
        mode = "dark"; # 壳层组件固定暗色变体
        # 动态取色：壳层配色随壁纸生成（2026-09-26 用户决策，保留迁移期间的运行时行为并提升进 Nix）
        source = "wallpaper";
        # 模板写回禁用：kitty/gtk/niri/qt/starship 等程序配色由 catppuccin/nix 与 HM 声明式管理，
        # 模板会写回这些生成文件（kitty include 行 / niri include / gtk css）并与之打架——
        # 与已废除的 DMS 写回 hack 同构。若要某 app 跟随壁纸，从此处按需加 id 并移除其 catppuccin 管理。
        templates.builtin_ids = [ ];
      };

      # 毛玻璃（floating panel：启动器 Mod+P / 会话菜单 / 控制中心 / 剪贴板）
      # 档位 solid | soft | glass；需配合 niri-rules.nix 的 noctalia 图层 blur 规则才出真模糊
      shell.panel.transparency_mode = "glass";

      # 通知卡片：默认 0.97 近乎不透明，模糊透不出来；0.8 露出 niri blur
      notification.background_opacity = 0.8;

      widget.tray = {
        # fcclient (FlClash fork) 恒报 SNI Status=Passive（fork 原生层缺陷：上游 FlClash 每次 show
        # 结尾都 set_status(ACTIVE)，fork 卡在 Passive 且左键 Activate 从未实现）。
        # Noctalia 默认 hide_passive=true 会直接过滤 Passive 项 → 图标永远不显示。
        hide_passive = false;
        # 按 SNI Title 匹配（Title 跨重启稳定；GUI pin 存的随机 Id 重启即失效，如死 Id
        # "7EVqkROMq6" 不提升），pin 到托盘 inline：fcclient + clash-verge 托盘
        pinned = [
          "tray-icon tray app clash-verge-rev-tray"
          "com.fcclient.app"
        ];
        drawer = true; # 托盘收进抽屉（GUI 提升）
      };

      # ── GUI 设计提升（2026-09-26，自 GUI 覆盖层摘录）──
      # bar 布局：launcher/工作区 | 日期+时钟 | 托盘/通知/剪贴板/网络/蓝牙/音量/电池/控制中心/会话
      bar.default = {
        background_opacity = 0.75; # GUI 存的 0.74999998... 为 float32 舍入，此处还原为真值
        center = [
          "date"
          "clock"
        ];
        contact_shadow = true;
        end = [
          "tray"
          "notifications"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "battery"
          "control-center"
          "session"
        ];
        margin_edge = 5;
        margin_ends = 10;
        radius = 80;
        scale = 1.25; # 同上（GUI 存 1.25000001...）
        start = [
          "launcher"
          "workspaces"
        ];
      };

      # 启动器图标：lambda（GUI 提升）
      widget.launcher.glyph = "lambda";

      # 壁纸不进 Nix：登录后 `noctalia msg panel-toggle wallpaper`（或设置 GUI）选一次，
      # 选择持久化到 GUI 覆盖层，不与 Nix 层冲突
    };
  };

  # 迁移清理：声明式接管后移除的散落文件（模式参照 niri.nix cleanStaleNiriLinks）
  # ⚠️ 必须排在 checkLinkTargets 之前：若把清理排在链接检查后，实体残留文件会先触发
  # checkLinkTargets 冲突（backupFileExtension 拒绝覆盖已存在的 .hm-bak）→ 整个激活中止
  # → 清理根本没机会跑（2026-09-26 开机实测踩坑：DMS 的 gtk.css 残留卡死全部 HM 激活）。
  home.activation.cleanStaleNoctaliaResidue = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    # DMS 运行时残留（2026-09-26 DMS→Noctalia 迁移）
    if [ -d "$HOME/.config/DankMaterialShell" ]; then
      $DRY_RUN_CMD rm -rf "$HOME/.config/DankMaterialShell"
    fi
    # 主题模板写回产物（builtin_ids 已置空，写回链路关闭）
    $DRY_RUN_CMD rm -f "$HOME/.config/kitty/themes/noctalia.conf" "$HOME/.config/niri/noctalia.kdl"
    # DMS GTK 取色残留：dank-colors.css（DMS 写入）+ gtk-3.0/gtk.css（仅一行 import 它）。
    # HM 不管理这两条路径，switch 后无人接管会永久滞留。dank-colors 是 DMS 专有文件名，
    # 指纹唯一；gtk-3.0/gtk.css 借 import 行识别，均不会误伤 catppuccin/HM 产物。
    # 注意：gtk-4.0/gtk.css 不在此清理——该路径现由 HM 管理（catppuccin gtk4 CSS 注入），
    # 残留实体文件由 HM backupFileExtension 自动挪为 .hm-bak 后接管；且 catppuccin v2 引擎
    # 自带 @keyframes ripple + @define-color，内容指纹无法与 DMS 残留区分（勿再加守卫）。
    $DRY_RUN_CMD rm -f "$HOME/.config/gtk-3.0/dank-colors.css"
    if [ -f "$HOME/.config/gtk-3.0/gtk.css" ] && grep -q "dank-colors" "$HOME/.config/gtk-3.0/gtk.css"; then
      $DRY_RUN_CMD rm -f "$HOME/.config/gtk-3.0/gtk.css"
    fi
    # hyprlock 退役（锁屏切 Noctalia 内置）：HM 不再管理其生成文件，清孤儿链接
    if [ -L "$HOME/.config/hypr/hyprlock.conf" ]; then
      $DRY_RUN_CMD rm "$HOME/.config/hypr/hyprlock.conf"
    fi
  '';
}
