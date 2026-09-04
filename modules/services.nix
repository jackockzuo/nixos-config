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
    # Intel CPU 散热管理：防止过热降频（与 TLP 互补）
    thermald.enable = true;
  };

  # .snapshots 目录（tmpfiles 创建，disko 回退后保留此规则）
  systemd.tmpfiles.rules = [
    "d /.snapshots 0755 root root -"
    "d /home/.snapshots 0755 root root -"
  ];
}
