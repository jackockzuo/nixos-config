# ============================================================
# nix.nix —— Nix LSP（nil）
#   取舍（已核对 nixpkgs 中 nil 和 nixd 都存在）：
#   - nil：轻量快速，补全够用，内存占用低 —— 默认选它
#   - nixd：功能全，基于 nixpkgs 分析（跳转/类型更准），内存占用高
#   🔴 本用户每天写 nix 配置：若想要更强的分析能力，
#      把下面 pkgs.nil 换成 pkgs.nixd 即可，其余不用动
# ============================================================
{ config, lib, pkgs, ... }:

{
  home.packages = lib.mkIf config.lsp.nix.enable [
    pkgs.nil # 轻量快速；如需 nixd：pkgs.nixd
  ];
}
