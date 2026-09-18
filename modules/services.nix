# ============================================================
# services.nix —— 系统服务
# 职责：音频（pipewire）、快照（snapper）、btrfs scrub、U盘/GVFS/固件/密钥环
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

    # 静默损坏防护：btrfs 定期 scrub（SSD 每月；STANDARDS §5）
    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [
        "/"
        "/home"
      ];
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
    # thermald 未启用：OMEN 16 固件无 DPTF，启动即失败（couldn't create any zones）；
    # 需要 DPTF 的机器在 hosts/<machine>/ 主机剖面里单独启用（EC 风扇 + HWP + TLP 已覆盖本机）。
  };

  # .snapshots 必须是真正的 btrfs 子卷（普通目录会让 snapper 报 IO Error，STANDARDS §5）
  # 不能用 tmpfiles 建普通目录（会埋雷）；缺失时手动创建：
  #   sudo rm -rf /.snapshots /home/.snapshots && sudo btrfs subvolume create /.snapshots /home/.snapshots
}
