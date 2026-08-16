# /etc/nixos/configuration.nix
_: {
  # 1. 开启 nix-index 模块
  programs.nix-index.enable = true;

  # 2. (可选) 禁用系统默认的 command-not-found
  # 因为默认的那个在 NixOS 上更新很慢，经常找不到包
  programs.command-not-found.enable = false;

}
