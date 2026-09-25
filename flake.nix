{
  description = "NixOS 配置";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs"; # 全仓单一 nixpkgs（STANDARDS §0.2）
    };
    # 核心架构（STANDARDS §1）
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    nixvim = {
      url = "github:nix-community/nixvim";
      # If you are not running an unstable channel of nixpkgs, select the corresponding branch of Nixvim.
      # url = "github:nix-community/nixvim/nixos-26.05";
    };
    # 代码质量（STANDARDS §7）
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # 秘密管理（STANDARDS §6）
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # DMS 桌面壳
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DMS Greeter 登录界面（已从 DankMaterialShell 拆分为独立仓库）
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";

    # 用户级配置（STANDARDS §3：作为 NixOS 模块集成）
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # OMEN 性能控制（本机 Rust 实现）
    omen-rs = {
      url = "github:jackockzuo/omen-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      lib = inputs.nixpkgs.lib;

      # 身份单一来源（STANDARDS §0.2）：改这里 → 全仓库自动跟随
      # username/homeDirectory/stateVersion = 用户身份（多机共用）；
      # hostname/hostId = 每机常量，由下方 hosts 清单注入（共享层禁止写死机器标识）
      my = rec {
        username = "ran";
        homeDirectory = "/home/${username}";
        stateVersion = "24.05";

        # GitHub token 片段路径（sops 渲染）。全局常量单一来源：
        #   modules/secrets.nix 生成于此，home/modules/core.nix 把它 include 进用户 nix.conf。
        nixAccessTokensPath = "/run/nix-access-tokens";

        # 配色单一来源（STANDARDS §0.2）：NixOS/HM 两侧 catppuccin 模块共用
        #   flavor/accent 改这里，系统层 modules/theme.nix 与用户层 home/modules/theme/ 同步跟随。
        catppuccin = rec {
          flavor = "mocha";
          accent = "mauve";
          # 派生主题名（无 catppuccin/nix 端口处使用：fcitx5 用户配置、GTK 主题包）
          names = {
            fcitx5 = "catppuccin-${flavor}-${accent}";
            gtk =
              "Catppuccin-${lib.toSentenceCase flavor}-Standard-${lib.toSentenceCase accent}-"
              + (if flavor == "latte" then "Light" else "Dark");
          };
        };
      };

      # 主机清单（STANDARDS §1）：加一台机器 = 这里一行 + hosts/<name>/ 目录
      hosts = {
        omen = {
          hostId = "007f0200"; # HP OMEN 16-wf0xxx（机器标识，勿改）
        };
      };

      mkMy = hostname: hostId: my // { inherit hostname hostId; };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks.flakeModule
      ];

      perSystem =
        { system, pkgs, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };

          # 开发环境
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.nixd
              pkgs.nixfmt
              pkgs.statix
              pkgs.deadnix
              pkgs.treefmt
              # 打包/flake 开发工具
              pkgs.nurl # URL → fetchurl/fetchFromGitHub 表达式
              pkgs.nix-fast-build # 并行构建 + 结果缓存
              pkgs.nixpkgs-review # 本地批量验证 nixpkgs PR
              pkgs.nixpkgs-hammering # 打包规范 lint
              pkgs.nix-diff # 解释两个 derivation 差异
              # 秘密管理 CLI（sops/age）已提升为全局安装 → home/modules/tools/dev.nix
              # （STANDARDS §3.1 包唯一性：同包全仓只声明一次）
            ];
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            settings.excludes = [
              "**/hardware-configuration.nix" # nixos-generate-config 产物（任意层级）
            ];
          };
          pre-commit.settings = {
            excludes = [ ".*hardware-configuration\\.nix$" ];
            hooks = {
              deadnix.enable = true;
              statix = {
                enable = true;
                settings.ignore = [ "hardware-configuration.nix" ];
              };
            };
          };
        };

      flake = {
        overlays.default = final: _prev: {
          # Go 1.25 兼容垫片：nixpkgs 2026-09-15 起把 `buildGo125Module` 变成 throw
          #   （“Go 1.25 is end-of-life”），而 sops-nix 最新 HEAD 仍写死该形参
          #   （pkgs/sops-install-secrets/default.nix）→ sops.package 求值即崩。
          #   sops-nix 显式接收 `buildGo125Module`，故仅把它重定向到当前 `buildGoModule`
          #   （Go 1.26）即可，语义等价、不碰其它包、无需硬编码 vendorHash。
          #   上游改用新 builder 后本垫片可删 (REF:2026-09-16-sops-nix-go125-eol)
          buildGo125Module = final.buildGoModule;
        };

        # 每台主机 = 通用层 modules/ + 主机剖面 hosts/<name>/（nixosSystem 参数见 mkMy）
        nixosConfigurations = inputs.nixpkgs.lib.mapAttrs (
          hostname:
          { hostId, ... }:
          inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              my = mkMy hostname hostId;
              inherit inputs;
            };
            modules = [
              # 通用层（平台无关）
              ./modules

              # 配色（catppuccin/nix NixOS 作用域：全局开关 + fcitx5/limine 等系统端口）
              inputs.catppuccin.nixosModules.catppuccin

              # 主机剖面（机器专属：硬件/性能解锁/主机 home）
              (import (./hosts + "/${hostname}"))

              # 兼容垫片 overlay（buildGo125Module → buildGoModule，sops-nix 用）
              {
                nixpkgs.overlays = [ inputs.self.overlays.default ];
              }

              # nixpkgs registry → 指向本 flake 锁定的 nixpkgs（本地 store 路径，免每次 git fetch）
              {
                nix.registry.nixpkgs.flake = inputs.nixpkgs;
              }

              # sops-nix 秘密管理（STANDARDS §6）
              inputs.sops-nix.nixosModules.sops

              # DMS 桌面壳
              inputs.dms.nixosModules.default
              # DMS Greeter（独立仓库，提供 programs.dms-greeter）
              inputs.dank-greeter.nixosModules.default

              # Home Manager（用户身份 my 注入，见 STANDARDS §0.2）
              inputs.home-manager.nixosModules.home-manager
              (
                { my, ... }:
                {
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    backupFileExtension = "hm-bak";
                    # 上游 #3172 boot 期 dbus 竞态唯一修复，勿改 (REF:2026-08-17-niri-login)
                    startAsUserService = true;
                    extraSpecialArgs = { inherit my; };
                    users.${my.username} = {
                      imports = [
                        inputs.nixvim.homeModules.nixvim # 编辑器（Nixvim，见 home/modules/tools/nixvim.nix）
                        inputs.catppuccin.homeModules.catppuccin # 配色（全局 + 已启用程序端口自动跟随）
                        ./home/home.nix
                      ];
                    };
                  };
                  systemd.user.services.home-manager.wantedBy = [ "default.target" ];
                }
              )
              inputs.nix-index-database.nixosModules.nix-index
              {
                programs.nix-index-database.comma.enable = true;
              }

            ];
          }
        ) hosts;
      };
    };
}
