# dev.nix —— 开发工具（git/gh/lazygit/direnv/tealdeer/topgrade/pass/languages）
# 职责：git 工作流 / GitHub CLI / LSP server 包 / direnv / 密码管理 / 升级工具
# 注意：neovim 独立（neovim.nix）；vscode 声明式扩展 + nixd 选项补全
# ============================================================
{
  config,
  lib,
  pkgs,
  my,
  ...
}:

{
  # 开发工具（git / GitHub CLI / lazygit / direnv / tealdeer / topgrade）
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
    # fish 集成 type -q 守卫（容器兼容）(REF:2026-08-18-distrobox-nc)
    direnv = {
      enable = true;
      enableFishIntegration = false; # 集成交给下方守卫块
      nix-direnv.enable = true;
      silent = false;
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
    # 更新链（事故驱动）：nixpkgs → 质量门禁 → 预构建+切换 (REF:2026-08-29-topgrade-rewrite)
    topgrade = {
      enable = true;
      settings = {
        misc = {
          disable = [
            "system"
            "pi"
            "nix" # nix 步骤用 nix-env --upgrade，与 nix profile 不兼容 (REF:2026-08-30-topgrade-nix)
          ];
          pre_sudo = true; # sudo switch 免输入
          set_title = false;
        };
        commands = {
          # ① 更新（精确控制：只 nixpkgs，覆盖 99% 场景）
          "NixOS flake update" = "cd ${config.home.homeDirectory}/nixos-config && nix flake update nixpkgs";
          # ② 质量门禁
          "NixOS flake check" = "cd ${config.home.homeDirectory}/nixos-config && nix fmt && nix flake check";
          # ③ 预构建验证 + ④ 确认无误才切换（&& 短路保证）
          # rebuild 前自动 snapper 快照（/ + /home）：改配置翻车可一条命令回滚（snapper rollback/undochange）(REF:2026-08-29-topgrade-rewrite)
          "NixOS rebuild" =
            "sudo snapper -c root create -t single -d 'nixos-rebuild before' && sudo snapper -c home create -t single -d 'nixos-rebuild before' && cd ${config.home.homeDirectory}/nixos-config && nix build .#nixosConfigurations.${my.hostname}.config.system.build.toplevel && sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/nixos-config#${my.hostname}";
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

    # ---- 编辑器：VSCode（声明式扩展 + Nix 选项补全）----
    # nixd 选项补全：nix.serverSettings 经 nix-ide 传给 nixd，expr 用 builtins.getFlake 指向本仓库 (REF:2026-08-29-topgrade-rewrite)
    vscode = {
      enable = true;
      # 扩展目录 store 只读（禁止手工装扩展，全部声明式）
      mutableExtensionsDir = false;
      profiles.default = {
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide # Nix 语言支持（nixd LSP）
          mkhl.direnv # direnv 集成
          ms-ceintl.vscode-language-pack-zh-hans # 中文界面
          timonwong.shellcheck # Shell 检查
          redhat.vscode-yaml # YAML 支持
        ];
        userSettings = {
          "git.confirmSync" = false;
          "explorer.confirmDelete" = false;
          "explorer.confirmDragAndDrop" = false;
          "editor.fontFamily" = "'Maple Mono NF CN', monospace";
          "git.autofetch" = true;
          "git.enableSmartCommit" = true;

          # ---- Nix IDE（nixd）----
          "[nix]" = {
            "editor.formatOnSave" = true;
          };
          "nix.enableLanguageServer" = true;
          "nix.serverSettings" = {
            nixd = {
              eval = {
                # 这里的表达式确保 nixd 能读取到 flake.nix
                target = {
                  args = [ "--impure" ];
                  installable = ".#nixosConfigurations.${my.hostname}.config.system.build.toplevel";
                };
              };

              # 包名/lib 补全来源 = 本 flake 锁定的 nixpkgs
              nixpkgs.expr = "import (builtins.getFlake (builtins.toString ./.)).inputs.nixpkgs { system = \"${pkgs.stdenv.hostPlatform.system}\"; }";
              # 格式化与仓库 `nix fmt` 同源（nixfmt-rfc-style）
              formatting.command = [ "nixfmt" ];
              # 配置项补全（本机 = nixos-rebuild 集成式 HM，nixd 官方文档 B 方案）：
              # NixOS 选项 + Home Manager 选项两组，输入时自动补全可配置项
              options = {
                # expr 为字符串但经 nix 插值：改 flake.nix 顶部 my.hostname 自动跟随 (REF:2026-08-29-topgrade-rewrite)
                nixos.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${my.hostname}.options";
                home-manager.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${my.hostname}.options.home-manager.users.type.getSubOptions []";
              };
            };
          };
        };
      };
    };

    # gpg（GnuPG 配置）
    gpg = {
      enable = true;
      settings = {
        default-new-key-algo = "ed25519+cv25519";
        no-symkey-cache = true; # 裸键名输出（布尔 true）
        trust-model = "tofu+pgp";
        with-fingerprint = true;
      };
    };
  };

  # force 覆盖 topgrade 首次运行生成的默认模板（避免 checkLinkTargets 冲突）
  xdg.configFile."topgrade.toml".force = true;

  # 密码管理 + LSP server 包
  home = {
    # gpg-agent 缓存时长
    # 首次使用：gpg --full-generate-key → pass init <gpg-id> → pass insert ...
    file.".gnupg/gpg-agent.conf".text = ''
      default-cache-ttl 1800
      max-cache-ttl 7200
    '';

    # LSP server 包（nvim mason+lspconfig 自动从 PATH 检测）
    packages = with pkgs; [
      clang-tools # cpp LSP
      rust-analyzer
      pkgs.nixd # nix LSP（vscode + nvim 共用）
      tinymist # typst LSP
      haskell-language-server # haskell LSP
      pkgs.nixfmt # nix 格式化
      shellcheck # vscode shellcheck 扩展依赖
    ];
  };
}
