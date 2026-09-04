{
  description = "NixOS 配置 - HP OMEN 16-wf0xxx (ran)";

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

    # CachyOS 高性能包/内核
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

    # omencore：官方 release 二进制
    omencore = {
      url = "https://github.com/theantipopau/omencore/releases/download/v4.1.7/OmenCore-4.1.7-linux-x64.zip";
      flake = false;
    };

  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      # 单一来源聚合（STANDARDS §0.2）：改这里 → 全仓库自动跟随
      my = rec {
        hostname = "omen";
        username = "ran";
        homeDirectory = "/home/${username}";
        stateVersion = "24.05";
      };
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
              "hardware-configuration.nix" # nixos-generate-config 产物
            ];
          };
          pre-commit.settings = {
            excludes = [ "hardware-configuration\\.nix" ];
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
        nixosConfigurations.${my.hostname} = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit my; };
          modules = [
            ./modules
            ./hardware-configuration.nix

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

            # Home Manager（代理单一来源注入，见 STANDARDS §0.2）
            inputs.home-manager.nixosModules.home-manager
            ({ config, ... }: {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-bak";
                # 上游 #3172 boot 期 dbus 竞态唯一修复，勿改 (REF:2026-08-17-niri-login)
                startAsUserService = true;
                extraSpecialArgs = {
                  inherit (config) proxy;
                  inherit my;
                };
                users.${my.username} = {
                  imports = [ ./home/home.nix ];
                };
              };
              systemd.user.services.home-manager.wantedBy = [ "default.target" ];
            })
            inputs.nix-index-database.nixosModules.nix-index
            {
              programs.nix-index-database.comma.enable = true;
            }
          ];
        };
      };
    };
}
