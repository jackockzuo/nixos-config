# ============================================================
# services.nix —— 系统服务
# 职责：音频（pipewire）、快照（snapper）、U盘/固件/电源
# ============================================================
_:

{
  services = {
    # 快照防护：snapper（btrfs 滚挂兜底）
    # btrfs 布局：/ = @、/home = @home、/nix = @nix
    snapper = {
      configs = {
        root = {
          SUBVOLUME = "/";
          ALLOW_GROUPS = [ "wheel" ];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "5";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "4";
          TIMELINE_LIMIT_MONTHLY = "3";
          TIMELINE_LIMIT_YEARLY = "1";
        };
        home = {
          SUBVOLUME = "/home";
          ALLOW_GROUPS = [ "wheel" ];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "5";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "4";
          TIMELINE_LIMIT_MONTHLY = "3";
          TIMELINE_LIMIT_YEARLY = "1";
        };
      };
      persistentTimer = true;
    };

    # 音频
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # 基础服务
    udisks2.enable = true;
    gvfs.enable = true;
    fwupd.enable = true;
    # GNOME Keyring：portal Secret=gnome-keyring 依赖（VSCode/Chrome 登录态）
    gnome.gnome-keyring.enable = true;
    # 注：thermald 已于 2026-09-03 移除——OMEN 16 固件无 DPTF(INT3400/INT3403 参与者)，
    #     它启动即 fail（"couldn't create any zones"，EC 风扇 + HWP + TLP 已覆盖，纯冗余）；
    #     若某机器 BIOS 有完整 DPTF，在对应 hosts/<machine>/ 主机剖面里单独启用。
  };

  # .snapshots 目录（tmpfiles 创建，disko 回退后保留此规则）
  systemd.tmpfiles.rules = [
    "d /.snapshots 0755 root root -"
    "d /home/.snapshots 0755 root root -"
  ];
}
