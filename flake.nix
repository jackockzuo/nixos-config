{
  description = "NixOS 配置（多主机；主机剖面见 hosts/，现仅 omen）";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # 核心架构（STANDARDS §1）
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # 代码质量（STANDARDS §7）
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # 秘密管理（STANDARDS §6）
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # CachyOS 高性能包/内核（网络环境项，多机通用）
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # DMS 桌面壳
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # omencore：官方 release 二进制（仅 omen 主机使用，2026-09-03 起 CLI-only）
    omencore = {
      url = "https://github.com/theantipopau/omencore/releases/download/v4.1.7/OmenCore-4.1.7-linux-x64.zip";
      flake = false;
    };

  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      # 身份单一来源（STANDARDS §0.2）：改这里 → 全仓库自动跟随
      # username/homeDirectory/stateVersion = 用户身份（多机共用）；
      # hostname/hostId = 每机常量，由下方 hosts 清单注入（共享层禁止写死机器标识）
      my = rec {
        username = "ran";
        homeDirectory = "/home/${username}";
        stateVersion = "24.05";
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

          # 按需运行的包
          packages = {
            omencore = pkgs.callPackage ./packages/omencore/package.nix { src = inputs.omencore; };
            omencore-update = pkgs.writeShellApplication {
              name = "omencore-update";
              runtimeInputs = with pkgs; [
                curl
                python3
                nix
                gnused
                gnugrep
                coreutils
              ];
              text = builtins.readFile ./packages/omencore/update.sh;
            };
          };
        };

      flake = {
        overlays.default = final: _prev: {
          omencore = final.callPackage ./packages/omencore/package.nix { src = inputs.omencore; };
        };

        # 每台主机 = 通用层 modules/ + 主机剖面 hosts/<name>/（nixosSystem 参数见 mkMy）
        nixosConfigurations = inputs.nixpkgs.lib.mapAttrs (
          hostname:
          { hostId, ... }:
          inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              my = mkMy hostname hostId;
            };
            modules = [
              # 通用层（平台无关）
              ./modules

              # 主机剖面（机器专属：硬件/性能解锁/主机 home）
              (import (./hosts + "/${hostname}"))

              # omencore overlay
              {
                nixpkgs.overlays = [ inputs.self.overlays.default ];
              }

              # sops-nix 秘密管理（STANDARDS §6）
              inputs.sops-nix.nixosModules.sops

              # Chaotic-Nyx
              inputs.chaotic.nixosModules.default

              # DMS 桌面壳
              inputs.dms.nixosModules.default
              inputs.dms.nixosModules.greeter

              # Nix registry 指向本 flake 锁定的 nixpkgs
              {
                nix.registry.nixpkgs.flake = inputs.nixpkgs;
              }

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
                      imports = [ ./home/home.nix ];
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
