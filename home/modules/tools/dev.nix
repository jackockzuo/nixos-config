# dev.nix —— 开发工具（git/gh/lazygit/direnv/tealdeer/topgrade/pass/sops/languages）
# 职责：git 工作流 / GitHub CLI / LSP server 包 / direnv / 秘密与密码管理 / 升级工具
# 注意：编辑器为 nixvim（tools/nixvim.nix）；vscode 声明式扩展 + nixd 选项补全
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
          name = my.username;
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

    # lazygit（git TUI，配色由 catppuccin.lazygit 注入）
    lazygit = {
      enable = true;
    };

    # direnv（目录环境）
    # fish 集成 type -q 守卫（容器兼容）(REF:2026-08-18-distrobox-container-fish-unknown-command)
    direnv = {
      enable = true;
      enableFishIntegration = false; # 集成交给下方守卫块
      nix-direnv.enable = true;
      silent = false;
    };
    # 统一 fish 集成守卫块（direnv）
    fish.interactiveShellInit = lib.mkAfter ''
      if type -q direnv
          if not functions -q __direnv_export_eval
              direnv hook fish | source
          end
      end
    '';

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
    # 更新链（事故驱动）：nixpkgs → 质量门禁 → 预构建+切换
    topgrade = {
      enable = true;
      settings = {
        misc = {
          disable = [
            "system" # 原生 = nixos-rebuild switch --upgrade（flake 场景不用，统一走 nr）
            "pi"
            "nix" # = nix-channel/nix-env，与 flakes 不兼容
            # HM 集成式；且 topgrade 17.9.0 在仅 nh 可用但 NH_FLAKE 未设时触发 require_one panic
            "home_manager"
          ];
          pre_sudo = true; # sudo 免输入
          set_title = false;
          nix_handler = "nh"; # NixOS/HM 切换统一走 nh
        };
        commands = {
          # 唯一 NixOS 入口：门禁 → nr -u（快照 / + /home → 更新全部 inputs → nh 构建/diff/切换）
          "NixOS 全量更新+重建" =
            "cd ${config.home.homeDirectory}/nixos-config && nix fmt && nix flake check && fish -c 'nr -u'";
        };
      };
    };

    # ---- 编辑器：VSCode（声明式扩展 + Nix 选项补全）----
    # nixd 选项补全：nix.serverSettings 经 nix-ide 传给 nixd，expr 用 builtins.getFlake 指向本仓库
    vscode = {
      enable = true;
      # 扩展目录 store 只读（禁止手工装扩展，全部声明式）(REF:2026-09-12-vscode-extensions-layout-transition)
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

          tamasfe.even-better-toml # TOML 支持
          usernamehw.errorlens # 报错提示优化
          eamodio.gitlens # Git 辅助

          myriad-dreamin.tinymist

          haskell.haskell # Haskell 支持

          rust-lang.rust-analyzer # Rust 支持
        ];
        userSettings = {
          "git.confirmSync" = false;
          "explorer.confirmDelete" = false;
          "explorer.confirmDragAndDrop" = false;
          "editor.fontFamily" = "'Maple Mono NF CN', monospace";
          "git.autofetch" = true;
          "git.enableSmartCommit" = true;

          # ---- Haskell（haskell.haskell 2.x）----
          # 2.x 无内置 TextMate 语法高亮，颜色全靠 HLS semantic tokens；
          # 但该设置默认 false 且会被原样转发给 HLS → 必须显式开启才有高亮。
          "haskell.manageHLS" = "PATH"; # 不用 GHCup 下载，直接用 PATH 上的 Nix HLS
          "haskell.plugin.semanticTokens.globalOn" = true;
          # 项目 devShell 只装了 fourmolu（无 ormolu）
          "haskell.formattingProvider" = "fourmolu";

          # ---- Nix IDE（nixd）----
          "[nix]" = {
            "editor.formatOnSave" = true;
          };
          "nix.enableLanguageServer" = true;
          # 语义高亮：nixd 默认不声明 semanticTokensProvider，必须显式给它 --semantic-tokens
          # 否则 `pkgs.ripgrep` 这类属性选择只是 TextMate 默认前景色，看不出包名
          "nix.serverPath" = [
            "nixd"
            "--semantic-tokens"
          ];
          "editor.semanticHighlighting.enabled" = true;
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
                # expr 为字符串但经 nix 插值：改 flake.nix 顶部 my.hostname 自动跟随
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

    # 补充 LSP server 包（nixvim 的 lsp 自动装主服务，这里只补额外工具）
    # haskell-language-server 不放全局：工具链随项目 devShell 走（direnv），保持系统纯净
    packages = with pkgs; [

      tinymist # typst LSP

      shellcheck # vscode shellcheck 扩展依赖
      tokei # 代码行数统计（按语言分类，CI/仓库体检用）

      # ---- 编译加速 ----
      mold # 快速链接器
      sccache # 编译缓存

      # ---- 秘密/密钥管理（sops + age：编辑 secrets/secrets.yaml、轮换 age 密钥，见 STANDARDS §6）----
      sops
      age

      # ---- 密码管理（pass：gpg 加密；gpg 配置见上方 programs.gpg）----
      pass
      pinentry-curses # gpg 主密码输入（终端版 pinentry）
    ];
  };
}
