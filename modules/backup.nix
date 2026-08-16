# ============================================================================
# restic 异地加密备份（补 snapper 本地快照的短板）
# ----------------------------------------------------------------------------
# snapper（modules/services.nix）负责本地 btrfs 快照，但本地快照防不了
# 磁盘损坏 / 整机丢失。本模块用 restic 做异地加密备份：
#   - restic 仓库本身加密（密码 + 数据均不入库），异地存放天然防丢失；
#   - 由 systemd timer 定时执行，错过时间点则开机补做（Persistent）；
#   - 现代写法：直接用 NixOS 自带的 services.restic.backups.<name>，
#     自动生成 restic-backups-<name>.service + .timer 两个单元，
#     无需手写 systemd 单元（已核实 nixpkgs 0e251e2 中存在该选项，
#     选项名见下方注释）。
#
# ⚠️ 导入位置：本文件声明的是 NixOS 系统级选项（services.restic），
#    不属于 home-manager 选项。若放在 home/modules/tools/ 下，需由
#    orchestrator 在系统级 modules/ 处导入（如 modules/default.nix），
#    不能走 home-manager 的 import 链。
#
# 🔴 使用说明（用户必读，三件事）：
#   🔴 1. 创建密码文件（root 才能读）：
#          sudo sh -c "echo '你的备份密码' > /etc/restic-password && chmod 600 /etc/restic-password"
#   🔴 2. 填写下方 repository（备份目标是私有信息，不硬编码真值）：
#          - 本地磁盘：  /mnt/backup-hdd/restic
#          - SFTP 远端：  sftp:user@host:/backups/restic
#          - rclone 远端：rclone:remote:bucket/restic（需另配 rcloneConfig）
#   🔴 3. （可选）调整备份路径 paths 与排除规则 exclude。
#
#   日常操作：
#     手动备份：  sudo systemctl start restic-backups-offsite.service
#     查看定时：  systemctl status restic-backups-offsite.timer
#     全部定时器：systemctl list-timers
#     查看日志：  journalctl -u restic-backups-offsite.service
#
#   说明：repository 的占位默认值（lib.mkDefault）在用户填写前是无效的，
#   此时服务启动会失败 —— 这是故意的，避免带病备份。
# ============================================================================
{ config, lib, pkgs, ... }:

{
  # 现代声明式做法：NixOS 内置 restic 备份模块（nixpkgs 0e251e2，
  # 源文件 nixos/modules/services/backup/restic.nix）。
  # 自动生成单元：restic-backups-offsite.service（oneshot）
  #             + restic-backups-offsite.timer（timerConfig 非空时）。
  # 已核实选项名（与上游完全一致）：
  #   initialize / repository / passwordFile / paths / exclude /
  #   timerConfig / pruneOpts / extraBackupArgs
  services.restic.backups.offsite = {
    # 首次运行时自动 restic init 初始化仓库（若仓库已存在则跳过）
    initialize = true;

    # 🔴 用户需填写：本地或远端仓库路径（私有信息，不硬编码）
    #    例："/mnt/backup-hdd/restic" 或 "sftp:user@host:/backups/restic"
    repository = lib.mkDefault "repo:/path/to/restic-repo";

    # 🔴 用户需创建：echo '密码' > /etc/restic-password && chmod 600
    #    （服务以 root 运行，restic 通过 RESTIC_PASSWORD_FILE 读取）
    passwordFile = "/etc/restic-password";

    # 备份 home 目录（snapper 快照含系统盘，restic 重点备份用户数据）
    paths = lib.mkDefault [ "/home/ran" ];

    # 排除规则（经 --exclude-file 传入，按路径组件模式匹配）
    exclude = [
      "/home/ran/.cache"                  # 缓存可再生
      "/home/ran/.local/share/nix"        # nix 缓存（可重建）
      "/home/ran/.local/share/Trash"      # 回收站
      "/home/ran/Downloads/starship-test" # 临时测试目录
      "/home/ran/Downloads/nvim-lsp-test" # 临时测试目录
      "*.iso"                             # 大镜像文件
      "node_modules"                      # 依赖可重装
      ".venv"                             # 虚拟环境可重建
    ];

    # 定时执行：每天一次，错过则开机补做，随机延迟 30 分钟错开高峰
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;       # 错过备份时间则开机补做
      RandomizedDelaySec = "30m"; # 错开高峰
    };

    # 快照保留策略：每日留 7 份、每周留 4 份、每月留 6 份
    # （forget --prune 自动清理旧快照并压缩仓库）
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];

    # 附加参数：跳过含 CACHEDIR.TAG 标记的缓存目录（如 ~/.cache 的子项）
    extraBackupArgs = [ "--exclude-caches" ];
  };
}
