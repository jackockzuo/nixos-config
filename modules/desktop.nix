# ============================================================
# desktop.nix —— 桌面会话与登录（greetd + Noctalia）
# 职责：greetd 登录界面、Noctalia 桌面壳、niri 合成器、portal
# ============================================================
{
  pkgs,
  ...
}:

{
  programs = {
    niri.enable = true; # 合成器必须由 NixOS 安装，greeter 才能列出

    # Noctalia 桌面壳（NixOS 侧只装包；用户服务/设置在 home/modules/desktop/noctalia.nix）
    # 🔴 不开 recommendedServices：会拉起 power-profiles-daemon，与本机 TLP + cpupower
    #    电源管理冲突（OMEN 调速由 omen-rs + TLP 独占，见 hosts/omen/）
    noctalia = {
      enable = true;
    };

    # dconf/GSettings：浏览器读系统代理需要 gsettings-desktop-schemas
    dconf.enable = true;
  };

  # Noctalia Greeter 登录界面（模块经 mkDefault 接管 greetd default_session.command，
  # 同时启用 AccountsService/polkit 并向 greeter 注入 XDG_DATA_DIRS——故本文件不再手动设）
  # 注意：不能显式设置 command！greeter 模块用 lib.mkDefault，显式赋值会覆盖
  services.displayManager.noctalia-greeter = {
    enable = true;
  };

  # Noctalia 内置锁屏的 PAM 认证走系统 `login` 服务（NixOS 默认提供，无需额外配置）。
  # pkexec setuid wrapper（NixOS 26.x 默认关）：GUI 提权工具（桌面提权启动器等）依赖
  # pkexec 弹系统密码框以 root 运行，不加此项报 "must be setuid root"。平台通用能力。
  security.polkit.enablePkexecWrapper = true;

  # greeter 外观同步免密：壳的壁纸/主题自动同步（shell.greeter_sync auto_sync）经 polkit 动作
  # org.noctalia.greeter.sync-appearance 以 root 写 /var/lib/noctalia-greeter/。该动作默认
  # auth_admin，而调用方无 logind 会话、会话内亦无 polkit agent——授权两条路全死，同步静默失败
  # （journal: "Error creating textual authentication agent"）。
  # 陷阱：policy 文件名是 org.noctalia.greeter.apply-appearance.policy，但其内部注册的
  # 动作 ID 是 org.noctalia.greeter.sync-appearance（文件名 ≠ 动作 ID）。写错 ID 时
  # pkexec 回退到 org.freedesktop.policykit.exec（auth_admin），规则永不命中——
  # 用 pkcheck --action-id <真实ID> 可自查是否已注册。
  # 注意：不可加 subject.local/active 条件——无会话调用方这两项恒 false，规则将永不匹配。
  # 动作仅能执行 store 内固定 helper（--sync），对 wheel 用户免密即上游预期做法。
  # 未用模块的 services.displayManager.noctalia-greeter.passwordless-sync-users：其规则
  # 额外要求 action.lookup("program")/lookup("user") 注解，而 .policy 只声明
  # org.freedesktop.policykit.exec.path/argv1，pkexec 路径不提供前两者。
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.noctalia.greeter.sync-appearance"
          && subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

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
