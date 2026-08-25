# ============================================================
# dev.nix —— 开发工具（并入 dev/{git,gh,lazygit,direnv,tealdeer,topgrade,pass,languages}）
# 职责：git 工作流 / GitHub CLI / LSP server 包 / direnv / 密码管理 / 升级工具
# 注意：neovim 独立（neovim.nix）；编辑器 vscode/zed 在本文件 home.packages
# ============================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ---- 开发工具（git 工作流 / GitHub CLI / lazygit / direnv / tealdeer / topgrade）----
  programs = {
    # git
    git = {
      enable = true;
      settings = {
        user = {
          name = "ran";
          email = "jackocksmic@outlook.com";
        };
        init = {
          defaultBranch = "main";
        };
      };
    };

    # GitHub CLI（SSH 协议）
    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };

    # lazygit（git TUI，Catppuccin Mocha 主题）
    lazygit = {
      enable = true;
      settings = {
        gui.theme = {
          selectedLineBgColor = [ "#313244" ];
          activeBorderColor = [
            "#89b4fa"
            "bold"
          ];
          inactiveBorderColor = [ "#585b70" ];
          optionsFgColor = [ "#89b4fa" ];
          selectedRangeBgColor = [ "#313244" ];
          cherryPickedCommitBgColor = [ "#45475a" ];
          cherryPickedCommitFgColor = [ "#cba6f7" ];
          unstagedChangesColor = [ "#f38ba8" ];
          defaultFgColor = [ "#cdd6f4" ];
          searchingActiveBorderColor = [ "#f9e2af" ];
        };
      };
    };

    # direnv（目录环境）
    # 🔴 fish 集成 type -q 守卫（容器兼容，2026-08-18 故障）
    direnv = {
      enable = true;
      enableFishIntegration = false; # 集成交给下方守卫块
      nix-direnv.enable = true;
    };

    # tealdeer（tldr 简洁手册）
    tealdeer = {
      enable = true;
      settings = {
        updates = {
          auto_update = true;
        };
      };
    };

    # topgrade（一键升级，NixOS flake 兼容）
    # 🔴 topgrade 对 NixOS 默认跑传统模式（/etc/nixos 不存在）→ disable system 步骤 +
    #    自定义 flake rebuild 命令；配置目录 home.homeDirectory 声明式
    topgrade = {
      enable = true;
      settings = {
        misc = {
          disable = [ "system" ];
          pre_sudo = true;
          set_title = false;
        };
        commands = {
          "NixOS flake update" = "nix flake update --flake ${config.home.homeDirectory}/nixos-config";
          "NixOS flake rebuild" =
            "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/nixos-config#omen";
        };
      };
    };

    # 统一 fish 集成守卫块（direnv）
    fish.interactiveShellInit = lib.mkAfter ''
      if type -q direnv
          if not functions -q __direnv_export_eval
              direnv hook fish | source
          end
      end
    '';
  };

  # force 覆盖 topgrade 首次运行生成的默认模板（避免 checkLinkTargets 冲突）
  xdg.configFile."topgrade.toml".force = true;

  # ---- 密码管理（pass + gpg）+ 编辑器 + LSP server 包 ----
  home = {
    # gpg 配置（目录固定 ~/.gnupg，GNUPGHOME 默认，不能用 xdg.configFile）
    # 首次使用（手动）：gpg --full-generate-key → pass init <gpg-id> → pass insert ...
    file = {
      ".gnupg/gpg.conf".text = ''
        default-new-key-algo ed25519+cv25519
        no-symkey-cache
        trust-model tofu+pgp
        with-fingerprint
      '';
      ".gnupg/gpg-agent.conf".text = ''
        default-cache-ttl 1800
        max-cache-ttl 7200
      '';
    };

    # 编辑器（原 dev/languages.nix）+ LSP server 包（原 dev/lsp/ 框架精简）
    # 🔴 nvim 的 mason+lspconfig 自动从 PATH 检测已装 server，无需 options 开关矩阵
    #    （架构量化规则 §2.4：无开关矩阵）——直接装当前启用的 4 个语言 server
    packages = with pkgs; [
      vscode
      zed
      clang-tools # cpp LSP（clangd + clang-format + clang-tidy）
      rust-analyzer
      nil # nix LSP（轻量；如需 nixd 换 pkgs.nixd）
      tinymist # typst LSP
    ];
  };
}
