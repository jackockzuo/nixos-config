# ============================================================
# desktop.nix —— 桌面会话与登录（greetd + DMS）
# 职责：greetd 登录界面、DMS 桌面壳、niri 合成器、portal
# ============================================================
{
  config,
  pkgs,
  my,
  ...
}:

{
  programs = {
    niri.enable = true; # 合成器必须由 NixOS 安装，greeter 才能列出

    # DMS 桌面壳
    dank-material-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
      enableSystemMonitoring = true;
      enableVPN = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
      enableCalendarEvents = true;
    };

    # DMS Greeter 登录界面（自动接管 greetd default_session.command）
    # 注意：不能显式设置 command！greeter 模块用 lib.mkDefault，显式赋值会覆盖
    dank-material-shell.greeter = {
      enable = true;
      compositor.name = "niri";
      configHome = config.users.users.${my.username}.home;
      logs = {
        save = true;
        path = "/tmp/dms-greeter.log";
      };
    };

    # dconf/GSettings：浏览器读系统代理需要 gsettings-desktop-schemas
    dconf.enable = true;
  };

  # hyprlock 锁屏 PAM 认证（配置见 home/modules/desktop/hyprlock.nix）
  security.pam.services.hyprlock = { };

  # greeter 系统用户（greetd 标准做法）
  users.groups.greeter = { };
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
    };
  };

  # DMS Greeter 需要 XDG_DATA_DIRS 才能发现 niri 会话
  systemd.services.greetd.environment.XDG_DATA_DIRS =
    "${config.services.displayManager.sessionData.desktops}/share";

  # 开机弹性：慢启动时放宽 start-limit（StartLimit* 属于 [Unit] 段）
  systemd.services.greetd.unitConfig = {
    StartLimitIntervalSec = "300";
    StartLimitBurst = 30;
  };

  # portal：只保留 gnome + gtk（wlr 与 gnome 混用会导致 OBS 录屏问题）
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };

  environment.systemPackages = [ pkgs.gsettings-desktop-schemas ];
  environment.sessionVariables.GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}/glib-2.0/schemas";
}
