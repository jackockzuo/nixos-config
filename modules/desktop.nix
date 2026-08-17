# ============================================================
# desktop.nix —— 桌面会话与登录（greetd + DMS）
# 职责：greetd 登录界面、DMS 桌面壳、niri 合成器、portal
# 修改：登录界面/桌面壳选项 → 改这里
# 关联：home-manager/desktop/（niri 具体键位等用户级配置）
# ============================================================
{ config, pkgs, ... }:

{
  # ============ 桌面：greetd + DMS Greeter 登录界面 ============
  # 说明：DMS greeter 模块（dms.nixosModules.greeter）会接管 default_session.command，
  # 启动 DMS 登录界面；登录后由 greeter 内部拉起 niri 会话。
  # 🔴 注意：这里不能显式设置 command！greeter 模块用 lib.mkDefault 设置 command，
  # 显式赋值优先级更高会覆盖掉 greeter → 登录界面不生效。command 交给 greeter 模块。
  programs = {
    niri.enable = true; # 合成器必须由 NixOS 安装（不能只靠 HM），greeter 才能列出

    # ============ DMS 桌面壳（DankMaterialShell）============
    #dms (DankMaterialShell, 模块来自 dms flake input: dms.nixosModules.default)
    dank-material-shell = {
      enable = true;

      systemd = {
        enable = true; # Systemd service for auto-start
        restartIfChanged = true; # Auto-restart dms.service when dms-shell changes
      };

      # Core features
      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableVPN = true; # VPN management widget
      enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      enableAudioWavelength = true; # Audio visualizer (cava)
      enableCalendarEvents = true; # Calendar integration (khal)
    };

    # DMS Greeter 登录界面（模块来自 dms flake input: dms.nixosModules.greeter）
    # 自动接管 services.greetd 的 default_session.command，开机显示 DMS 登录界面
    dank-material-shell.greeter = {
      enable = true;
      compositor.name = "niri"; # 用 niri 跑 greeter 界面（必须 NixOS 安装）
      # 同步用户 DMS 主题/壁纸/配色到 greeter（settings.json/session.json/dms-colors.json）
      configHome = "/home/ran";
      # 保存 greeter 日志方便排查
      logs = {
        save = true;
        path = "/tmp/dms-greeter.log";
      };
    };

    # ============ dconf / GSettings（系统代理等桌面集成依赖）============
    # 说明：fcclient 等代理客户端通过 gsettings (org.gnome.system.proxy) 设置系统代理，
    # 但 niri/DMS 不依赖 GNOME 模块，gsettings-desktop-schemas 不会自动进系统环境，
    # 导致浏览器（Chrome/Firefox）读系统代理时提示"没有安装架构"而无法走代理。
    # 这里显式启用 dconf 并把 gsettings-desktop-schemas 的 schema 目录暴露给会话。
    dconf.enable = true;
  };

  # 独立 greeter 系统用户（greetd 标准做法）：登录界面以最小权限运行，
  # 用户认证通过后才以目标用户（ran）启动桌面会话。
  # 参考 DMS greeter 模块测试（distro/nix/tests/greeter-niri-module.nix）
  users.groups.greeter = { };
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
  };

  services.greetd = {
    enable = true;

    settings.default_session = {
      # command 由 DMS greeter 模块提供（lib.mkDefault），此处不设置
      # 🔴 不要添加 initial_session（自动登录）：它会绕过 DMS 登录界面直接启动
      # niri，且与 greeter 流程冲突（initial_session 退出后才轮到 greeter）。
      user = "greeter";
    };
  };
  # 🔴 关键修复：DMS Greeter 需要 XDG_DATA_DIRS 才能发现 niri 会话（.desktop 文件）。
  # 官方 displayManager 模块会自动注入 `${sessionData.desktops}/share`，但纯 greetd 不走该模块，
  # 必须手动给 greetd 服务加上，否则 greeter 的会话列表为空 → 登录后无法启动 niri。
  systemd.services.greetd.environment.XDG_DATA_DIRS =
    "${config.services.displayManager.sessionData.desktops}/share";
  # 开机弹性：慢启动（user 管理器/dbus 未就绪）时别让 greetd 5 次/10s 就 start-limit-hit，
  # 放宽到 30 次/5 分钟，给系统时间自己稳定下来
  # 注意：StartLimit* 属于 [Unit] 段（unitConfig），放 serviceConfig 会报
  # "Unknown key 'StartLimitIntervalSec' in section [Service]"
  systemd.services.greetd.unitConfig = {
    StartLimitIntervalSec = "300";
    StartLimitBurst = 30;
  };

  # ============ portal（桌面集成）============
  # 🔴 只保留 gnome + gtk：niri 26.04+ 对 gnome portal 的录屏支持已完善，
  # wlr 与 gnome 混用会导致 OBS 等录屏软件识别不到屏幕（社区公认问题）。
  # gnome portal 经 dbus 自动拉起，无需显式启用其服务。
  xdg.portal = {
    enable = true;
    # wlr.enable = true; # ❌ 已移除：与 gnome portal 冲突
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };

  environment.systemPackages = [ pkgs.gsettings-desktop-schemas ];
  environment.sessionVariables.GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}/glib-2.0/schemas";
}
