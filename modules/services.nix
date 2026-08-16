# ============================================================
# services.nix —— 系统服务
# 职责：音频（pipewire）、快照（snapper）、U盘/固件/电源
# 修改：启停系统服务 → 改这里
# 关联：hardware.nix（zram 交换在那边）
# ============================================================
_:

{
  services = {
    # ============ 快照防护：snapper（btrfs 滚挂兜底）============
    # 🔴 btrfs 布局：/ = @、/home = @home、/nix = @nix。
    # snapper 只对 / 和 /home 做时间线快照（/nix 是内容寻址 store，无需快照）。
    # 用法：sudo snapper -c root list / sudo snapper -c home list；恢复：sudo snapper -c root undochange
    snapper = {
      configs = {
        root = {
          SUBVOLUME = "/";
          ALLOW_GROUPS = [ "wheel" ]; # 让 wheel 组（ran 在 wheel）无需 root 也能操作快照
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "5"; # 保留最近 5 个每小时快照
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
      # 定时快照：错过（关机）则开机后立即补一次
      persistentTimer = true;
    };
    # ============ 音频 ============
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # ============ 基础服务 ============
    udisks2.enable = true; # U 盘自动挂载（udiskie）
    gvfs.enable = true;
    fwupd.enable = true; # 固件更新（fwupdmgr 更新 UEFI/笔记本固件）
    # 🔴 GNOME Keyring：portal.nix 的 Secret=gnome-keyring 依赖它！
    # 没有它 VSCode 无法保存 GitHub 登录态、Chrome 无法记住密码。
    # 之前 portal 指向了 gnome-keyring 但服务从未启用（bug）。
    gnome.gnome-keyring.enable = true;
    # 笔记本电源管理（TLP：电池阈值/省电调优，与 powerManagement 共存）
    tlp.enable = true;
    # 🔴 Intel CPU 散热管理：防止过热降频（HP OMEN 游戏本高负载场景）
    # thermald 与 TLP 互补（TLP 管电源策略，thermald 管热节流），可共存
    thermald.enable = true;
    # 🔴 必须显式关掉 power-profiles-daemon：DMS 模块默认启用它（mkDefault），
    # 与 TLP 功能重叠且 NixOS 断言两者互斥（同时 enable 会 rebuild 失败）。
    # 显式 false 优先级高于 DMS 的 mkDefault true。
    power-profiles-daemon.enable = false;
  };
  # 🔴 snapper 需要每个子卷下有 .snapshots 目录，否则创建快照报错。
  # btrfs 上最稳的是把 .snapshots 做成独立子卷（可被快照自身的父卷跳过），
  # 但普通目录也能用；这里用 systemd-tmpfiles 开机自动创建，保证存在。
  systemd.tmpfiles.rules = [
    "d /.snapshots 0755 root root -"
    "d /home/.snapshots 0755 root root -"
  ];
}
