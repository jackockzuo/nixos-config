{
  description = "NixOS 配置 - HP OMEN 16-wf0xxx (ran)";

  inputs = {
    # 滚动更新通道（和当前 HM 一致）
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # 国内镜像替代（github 拉取不稳时换这个）：
    #nixpkgs.url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixpkgs-unstable/nixexprs.tar.xz";

    # ---- 核心架构：flake-parts（事实标准，见 STANDARDS.md §1）----
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # ---- 代码质量：格式化 + 提交检查（见 STANDARDS.md §6）----
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.url = "github:cachix/git-hooks.nix"; # 原 pre-commit-hooks.nix（2025 更名）
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # ---- 秘密管理：sops-nix（见 STANDARDS.md §5）----
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # ---- CachyOS 高性能包/内核（Chaotic-Nyx）：linuxPackages_cachyos、x86-64-v3 优化包 ----
    # 二进制缓存：nyx.cachix.org（见 modules/nix.nix substituters 首位）
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # DMS (DankMaterialShell) —— quickshell 桌面壳，模块用 nixpkgs 自带的 quickshell（≥0.3.0）
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 用户级配置已并入本仓库（home/ 目录），不再单独引用外部仓库
    # 肥猫云_Lite 打包目录（仓库外 ~/Documents/nix-packaging/，保持本仓库纯净）
    # path 输入不受"纯求值禁止仓库外绝对路径"限制，flake.lock 会记录路径
    fcclientPkg = {
      url = "path:/home/ran/Documents/nix-packaging/fcclient";
      flake = false; # 纯源文件目录（default.nix + .deb），不当作独立 flake
    };
    # 🔴 GitHub token 已迁移至 sops-nix（secrets/secrets.yaml 加密，见 modules/secrets.nix），
    #    原仓库外 secrets path 输入已删除（token 不再明文进 /nix/store）

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 🔴 omencore（HP OMEN 控制中心）：官方 release 二进制 zip，flake=false。
    #    版本号写在 URL 里；hash（narHash）由 flake.lock 自动管理。
    #    滚动更新：nix run .#omencore-update（改 URL 版本号 + nix flake lock 刷新 hash）
    omencore = {
      url = "https://github.com/theantipopau/omencore/releases/download/v4.1.7/OmenCore-4.1.7-linux-x64.zip";
      flake = false;
    };

  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # 单机架构（多主机扩展见 STANDARDS.md §1.2）
      systems = [ "x86_64-linux" ];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks.flakeModule
      ];

      # ---- 按系统：包 / 格式化 / 提交检查（见 STANDARDS.md §6）----
      # 注：函数体内用到的 `inputs`（如 fcclientPkg）是顶层闭包捕获，非 perSystem 参数
      perSystem =
        { system, pkgs, ... }:
        {
          # flake-parts 标准做法：自定义 perSystem pkgs（含 allowUnfree），
          # 供本 perSystem 所有模块（treefmt/git-hooks/包）共用同一份，
          # 包统一用 pkgs.callPackage（不再手动 import inputs.nixpkgs）
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true; # nixfmt-rfc-style（官方 RFC 风格），nix fmt 统一入口
            settings.excludes = [
              # hardware-configuration.nix 是 nixos-generate-config 生成文件（root 属主，
              # 只读），且内容随时会被重新生成覆盖——不纳入格式化/检查范围
              "hardware-configuration.nix"
            ];
          };
          pre-commit.settings = {
            # 全局排除：hardware-configuration.nix 是 nixos-generate-config 生成文件
            # （root 属主只读，随时会被重新生成覆盖）——不进入任何 pre-commit hook
            excludes = [ "hardware-configuration\\.nix" ];
            hooks = {
              # 格式化交给 treefmt/nixfmt（二选一原则），这里只做结构检查
              deadnix.enable = true; # 死代码检测
              statix = {
                enable = true; # 反模式检查
                # statix 自行遍历目录（不走 pre-commit 文件过滤），需单独 ignore
                settings.ignore = [ "hardware-configuration.nix" ];
              };
            };
          };

          # ---- 按需运行的包（nix run .#xxx，不装进系统，不进 systemPackages）----
          # fcclient：包定义在仓库外 ~/Documents/nix-packaging/fcclient，经 path 输入引入
          #   🔴 CI 处理：GitHub Actions 无此目录，CI 用 --override-input fcclientPkg
          #      指向仓库内 .ci/fcclient-placeholder（仅 eval 用占位，见 ci.yml）
          #   ⚠️ 勿用 builtins.pathExists 条件化（纯求值下恒 false，包会消失）
          #  omencore / omencore-update：见 packages/ 下各自 package.nix
          #  pi-coding-agent：nixpkgs 已有（跟随 nixos-unstable 滚动），直接 pkgs.pi-coding-agent
          packages = {
            fcclient = pkgs.callPackage inputs.fcclientPkg { };

            # 🔴 omencore（HP OMEN 控制中心：CLI + GUI）：nixpkgs 无此包 → 官方 release
            #    self-contained 二进制打包（.NET 8 + Avalonia，源码编译过重）。
            #    来源：inputs.omencore（flake 输入 = 官方 release zip，hash 在 flake.lock）
            #    打包逻辑：packages/omencore/package.nix（原样安装，经 nix-ld 运行）
            #    安装：modules/omencore.nix 的 environment.systemPackages（经 flake.overlays.default）
            #    滚动更新：nix run .#omencore-update（packages/omencore/update.sh）
            omencore = pkgs.callPackage ./packages/omencore/package.nix { src = inputs.omencore; };

            # omencore 滚动更新器：查 GitHub 最新 release → 改版本号 → 刷新锁 hash → 构建验证
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

      # ---- NixOS 配置（flake-parts 内置 flake.nixosConfigurations）----
      # 注：纯 attrset，不用函数签名；内部 inputs 为顶层闭包捕获
      flake = {
        # overlay：把 omencore 暴露为系统 pkgs（home.packages 直接可用）
        # 唯一来源 = packages/omencore/package.nix；此处仅接线（STANDARDS §0.2）
        # pi-coding-agent：nixpkgs 已有，无需 overlay
        overlays.default = final: _prev: {
          omencore = final.callPackage ./packages/omencore/package.nix { src = inputs.omencore; };
        };
        nixosConfigurations.omen = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./modules # 系统配置聚合（boot/hardware/network/users/desktop/...）
            ./hardware-configuration.nix # 硬件检测 + fileSystems（nixos-generate-config 产物）

            # 🔴 挂载自定义 overlay（omencore = packages/omencore/package.nix 唯一来源）：
            #    系统层 pkgs 与 home.packages 共用同一份，经 flake.overlays.default 接线
            #    pi-coding-agent 已改用 nixpkgs 自带包
            {
              nixpkgs.overlays = [ inputs.self.overlays.default ];
            }

            # ⚠️ 2026-08-16 回退：disko 声明式分区已移除（test 进紧急模式——
            #    disko 采纳动作未执行，生成的 fileSystems 引用不存在的 .snapshots
            #    子卷导致挂载失败）。fileSystems 恢复由 hardware-configuration.nix
            #    管理（by-uuid）。未来采纳 disko 需先执行 --mode format,mount。

            # ---- sops-nix 秘密管理（STANDARDS §5）：GitHub token 等 ----
            # 配置见 modules/secrets.nix（声明/解密 key/消费方接线）
            inputs.sops-nix.nixosModules.sops

            # ---- Chaotic-Nyx（CachyOS 包）：提供 chaotic.nyx.* 选项 + linuxPackages_cachyos ----
            # 配置见 modules/nix.nix（overlay/cpu-set）+ modules/boot.nix（内核切换）
            inputs.chaotic.nixosModules.default

            # ---- DMS (DankMaterialShell) 桌面壳模块（提供 programs.dank-material-shell 选项）----
            inputs.dms.nixosModules.default
            # DMS Greeter 登录界面模块（提供 programs.dank-material-shell.greeter 选项，
            # 自动接管 services.greetd 的 default_session.command）
            inputs.dms.nixosModules.greeter

            # ---- Nix 客户端与 flake 锁定版本对齐 ----
            # `nix shell nixpkgs#...` / `nix develop` 默认会拉一个新的 nixpkgs，
            # 与系统 flake 锁定版本不一致（多下载一份、行为可能漂移）。
            # 把 registry 的 nixpkgs 指向本 flake 锁定的 nixpkgs，两者永远一致。
            {
              nix.registry.nixpkgs.flake = inputs.nixpkgs;
              # nixPath 保留默认（channel 方式），只覆盖 registry 不影响系统内建查找
            }

            # ---- 复用现有 Home Manager 配置（用户级全部继承）----
            inputs.home-manager.nixosModules.home-manager
            # 模块写成函数以拿到 NixOS config：把系统级代理配置
            # （modules/proxy.nix 的 options.proxy）注入 HM，用户级 fish 开关/
            # 环境变量与 nix-daemon 共用同一地址（单点修改）
            ({ config, ... }: {
              home-manager = {
                # allowUnfree 已由 modules/system.nix 顶层 nixpkgs.config 管理
                # 🔴 useGlobalPkgs 必须为 true：HM 模块 fcitx5.nix 用
                # lib.mkIf (!config.home-manager.useGlobalPkgs or false) 判断是否接管
                # i18n.inputMethod——NixOS 上系统层已管理，设 true 让 HM 跳过，避免双份配置
                useGlobalPkgs = true;
                useUserPackages = true;
                # 🔴 修复：HM 在开机早期（system service，Before=systemd-user-sessions）激活时，
                # hm-setup-env 会临时拉起 dbus-daemon 抢占 /run/user/1000/bus，
                # 导致真正的 dbus-broker 启动失败 → 用户 systemd --user 无 DBus →
                # 登录后 niri-session 的 `systemctl --user start niri.service` 报
                # "process org.freedesktop.systemd1 exited with status 1"。
                # 改为 startAsUserService：HM 作为 systemd user service 在登录时激活，
                # 此时用户 DBus 已就绪，dconf 正常，不再抢 bus。
                # ⚠️ 见 STANDARDS §3（home-manager 一节）：✅ 调研确认保留（2026-08）——
                #    上游真实 bug #3172（boot 期激活 vs 用户 dbus 竞态）唯一受支持修复；
                #    无替代修复（#3405 未合并），移除会回归登录失败。勿改！
                startAsUserService = true;
                # 🔴 代理地址单一来源注入：HM 模块经 extraSpecialArgs 拿到 config.proxy
                extraSpecialArgs = {
                  inherit (config) proxy;
                };
                users.ran = {
                  # 用户级配置已并入本仓库 home/ 目录（home.nix 的相对 imports 自动解析）
                  imports = [ ./home/home.nix ];
                };
              };
              # 🔴 调研确认（home-manager PR #6981）：startAsUserService 模式下模块
              #    不自动启用用户服务（无 wantedBy）→ 登录时不会自动激活，仅 rebuild
              #    时经 sd-switch 触发。这里补上 wantedBy 让每次登录都激活。
              #    注意：不能 wants/after nix-daemon.socket（systemd 禁止用户→系统依赖，#8565）
              systemd.user.services.home-manager.wantedBy = [ "default.target" ];
            })
            inputs.nix-index-database.nixosModules.nix-index
            {
              programs.nix-index-database.comma.enable = true; # 开启逗号命令
            }
          ];
        };
      };
    };
}
