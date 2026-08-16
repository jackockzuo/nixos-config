# ============================================================
# media.nix —— 音乐/流媒体（预留）
# 该放什么：Spotify / ncmpcpp / playersctl 等桌面端播放器
# 使用方式：home.packages = with pkgs; [ spotify ... ];
# 注意：媒体服务器（Jellyfin 等）放 nixos-config/modules/media-server.nix
# ============================================================
{ pkgs, ... }:

{
  # 预留：需要时在此添加媒体播放器
  home.packages = with pkgs; [ ];
}
