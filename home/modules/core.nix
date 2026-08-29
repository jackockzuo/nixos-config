# ============================================================
# core.nix —— 基础层（NixOS 下由 ~/nixos-config 系统层配合）
# 职责：用户身份、nix 客户端配置
# 不包含：环境变量（→ env.nix）、桌面组件（→ desktop/）、
#         开发工具（→ tools/）、网络（→ network/）
#
# NixOS 集成说明（见 nixos-config/flake.nix）：
# - useGlobalPkgs = true：二进制由系统层管理，HM 只管配置文件
# - 系统层已管理：nixpkgs.config.allowUnfree / nix.gc
# - 本模块只保留"用户级"职责，避免与系统层重复
# - 🔴 用户身份单一来源：flake.nix 顶部 my（username/homeDirectory/stateVersion），
#   经 extraSpecialArgs 注入，此处只引用
# ============================================================
{
  pkgs,
  lib,
  my,
  ...
}:

{
  # ---------- 用户（单一来源 flake.nix 顶部 my，见文件头注释）----------
  home = {
    inherit (my) username homeDirectory stateVersion;
  };

  programs.home-manager.enable = true;

  # ---------- nix 客户端配置（写入 ~/.config/nix/nix.conf）----------
  nix = {
    # standalone 构建需要；NixOS 集成时由系统层提供（mkDefault 允许覆盖）
    package = lib.mkDefault pkgs.nix;
    settings = {
      # 现代 Nix 命令和 Flakes 支持
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # 🔴 substituters 不再在此声明：单一来源是系统层 modules/nix.nix
      #    （daemon 通过 /etc/nix/nix.conf 统一管理下载源），
      #    客户端 nix shell / nix profile add 自动继承 daemon 配置。
      # trusted-public-keys 由系统层 daemon 侧管理，客户端不设避免 restricted 警告
      connect-timeout = 10;
    };
  };

  # ---------- 允许 unfree 包（用户级）----------
  # 🔴 useGlobalPkgs = true 时不能再设 nixpkgs.config（HM 弃用警告），
  #    unfree 由系统层 modules/nix.nix + system.nix 的 allowUnfree = true 管理，
  #    HM 直接用全局 nixpkgs 解析包，自动继承，无需重复声明。

  # ---------- 客户端级 unfree 允许（nix profile add / nix-env / nix-shell）----------
  # 🔴 作用域说明：上面两处 nixpkgs.config 只影响 nixos-rebuild / home-manager 的包解析；
  #    命令行 `nix profile add nixpkgs#xxx` 走的是客户端级配置 ~/.config/nixpkgs/config.nix，
  #    不读系统/HM 层。这里声明式生成该文件，`nix profile add` 等命令直接可用。
  #    参考：错误信息 "For nix-env/nix-build/nix-shell... add { allowUnfree = true; }
  #          to ~/.config/nixpkgs/config.nix"。
  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  # 允许 HM 接管已存在的手写 ~/.config/nix/nix.conf（替换为生成文件）
  xdg.configFile."nix/nix.conf".force = true;
}
