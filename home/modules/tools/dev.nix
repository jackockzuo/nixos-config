# ============================================================
# dev.nix —— 开发工具（并入 dev/{git,gh,lazygit,direnv,tealdeer,topgrade,pass,languages}）
# 职责：git 工作流 / GitHub CLI / LSP server 包 / direnv / 密码管理 / 升级工具
# 注意：neovim 独立（neovim.nix）；编辑器 vscode 在本文件 programs.vscode（声明式扩展 + nixd 选项补全）
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
    # 🔴 更新链（2026-08-29 重写，事故驱动）：依次执行 ①更新 nixpkgs → ②质量门禁 → ③预构建+切换。
    #    - 只更新 nixpkgs（不碰 chaotic/home-manager/dms——全量漂移曾导致 sops 现场编译失败）
    #    - ③ 用 && 链：预构建失败则绝不执行 switch（"确认无误才切换"语义，topgrade 默认
    #      失败后继续，不合并会绕过验证直接切换）
    #    - 命令前 cd 到仓库（nix fmt 无 --flake 参数，必须目录内执行）；home.homeDirectory 声明式
    topgrade = {
      enable = true;
      settings = {
        misc = {
          disable = [
            "system"
            "pi"
          ];
          pre_sudo = true; # 提前 sudo -v 预热，末尾 sudo switch 免输入
          set_title = false;
        };
        commands = {
          # ① 更新（精确控制：只 nixpkgs，覆盖 99% 场景）
          "NixOS flake update" = "cd ${config.home.homeDirectory}/nixos-config && nix flake update nixpkgs";
          # ② 质量门禁
          "NixOS flake check" = "cd ${config.home.homeDirectory}/nixos-config && nix fmt && nix flake check";
          # ③ 预构建验证 + ④ 确认无误才切换（&& 短路保证）
          "NixOS rebuild" =
            "cd ${config.home.homeDirectory}/nixos-config && nix build .#nixosConfigurations.omen.config.system.build.toplevel && sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/nixos-config#omen";
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
    # 官方模块（programs.<x>.enable，见 STANDARDS §3）：扩展与设置全部声明式管理，
    # ~/.vscode/extensions 为 store 只读链接，升级走 flake lock，不再手工装扩展。
    # nixd 选项补全（NixOS + Home Manager 双选项集）由 nix-ide 扩展经
    # nix.serverSettings 传给 nixd，expr 用 builtins.getFlake 指向本仓库
    # （单一来源，见 STANDARDS §0.2），与 `nixos-rebuild switch --flake .#omen` 完全一致。
    vscode = {
      enable = true;
      # 扩展目录 store 只读（禁止手工装扩展，全部声明式）
      mutableExtensionsDir = false;
      profiles.default = {
        enableUpdateCheck = false; # 版本管理走 nixpkgs，不弹 marketplace 更新
        enableExtensionUpdateCheck = false;
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide # Nix 语言支持（nixd LSP：NixOS/Home Manager 配置项补全 + 跳转）
          mkhl.direnv # direnv 集成（有 .envrc 的项目自动加载环境）
          ms-ceintl.vscode-language-pack-zh-hans # 中文界面（继承原手工安装）
          timonwong.shellcheck # Shell 检查（source/niri/scripts 等手写脚本，需 shellcheck 包见下方）
          redhat.vscode-yaml # YAML 支持（.github/workflows、.sops.yaml；自带 yaml-language-server）
        ];
        userSettings = {
          # ---- 原手工 settings.json 内容保留（迁移至声明式）----
          "git.confirmSync" = false;
          "explorer.confirmDelete" = false;
          "explorer.confirmDragAndDrop" = false;
          "editor.fontFamily" = "'Maple Mono NF CN', monospace";
          "git.autofetch" = true;
          "git.enableSmartCommit" = true;

          # ---- Nix IDE（nixd）----
          "nix.enableLanguageServer" = true; # 用 nixd LSP（替代旧的 nix-instantiate）
          "nix.serverSettings" = {
            nixd = {
              # 包名/lib 补全来源 = 本 flake 锁定的 nixpkgs
              nixpkgs.expr = "import (builtins.getFlake (builtins.toString ./.)).inputs.nixpkgs { }";
              # 格式化与仓库 `nix fmt` 同源（nixfmt-rfc-style）
              formatting.command = [ "nixfmt" ];
              # 配置项补全（本机 = nixos-rebuild 集成式 HM，nixd 官方文档 B 方案）：
              # NixOS 选项 + Home Manager 选项两组，输入时自动补全可配置项
              options = {
                nixos.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.omen.options";
                home-manager.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.omen.options.home-manager.users.type.getSubOptions []";
              };
            };
          };
        };
      };
    };

    # gpg（GnuPG 配置，官方模块：settings 序列化生成 gpg.conf，布尔 true 输出裸键名）
    # 🔴 gpg-agent.conf 无对应 HM 模块选项 → 仍由下方 home.file 声明（2 行，不引入 services.gpg-agent 行为变更）
    gpg = {
      enable = true;
      settings = {
        default-new-key-algo = "ed25519+cv25519";
        no-symkey-cache = true; # 输出为裸键 no-symkey-cache（布尔 true → 只写键名）
        trust-model = "tofu+pgp";
        with-fingerprint = true;
      };
    };
  };

  # force 覆盖 topgrade 首次运行生成的默认模板（避免 checkLinkTargets 冲突）
  xdg.configFile."topgrade.toml".force = true;

  # ---- 密码管理（pass + gpg）+ LSP server 包（编辑器 vscode 在 programs.vscode，见上）----
  home = {
    # gpg-agent 缓存时长（gpg.conf 已由 programs.gpg 管理，见上）
    # 首次使用（手动）：gpg --full-generate-key → pass init <gpg-id> → pass insert ...
    file.".gnupg/gpg-agent.conf".text = ''
      default-cache-ttl 1800
      max-cache-ttl 7200
    '';

    # ---- LSP server 包（原 dev/lsp/ 框架精简；vscode 已改由 programs.vscode 声明式管理）----
    # 🔴 nvim 的 mason+lspconfig 自动从 PATH 检测已装 server，无需 options 开关矩阵
    #    （架构量化规则 §2.4：无开关矩阵）——直接装当前启用的 4 个语言 server
    packages = with pkgs; [
      clang-tools # cpp LSP（clangd + clang-format + clang-tidy）
      rust-analyzer
      pkgs.nixd # nix LSP（vscode Nix IDE 与 nvim 共用同一 PATH 上的 nixd）
      tinymist # typst LSP
      haskell-language-server # haskell LSP
      pkgs.nixfmt # nix 格式化（nixfmt-rfc-style 已合并进 nixfmt，见 eval 弃用警告）
      shellcheck # vscode timonwong.shellcheck 扩展的检查二进制（PATH 检测）
    ];
  };
}
