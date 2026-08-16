{
  description = "NixOS 配置 - HP OMEN 16-wf0xxx (ran)";

  inputs = {
    # 滚动更新通道（和当前 HM 一致）
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # 国内镜像替代（github 拉取不稳时换这个）：
    #nixpkgs.url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixpkgs-unstable/nixexprs.tar.xz";
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
    # 🔴 私有配置目录（仓库外，git 不追踪 → token 永不泄露）
    # 与 fcclientPkg 同理：path 输入在纯求值下允许，flake.lock 记录路径。
    # 目录里放 github-token 文件（一行 token 文本），经下方 access-tokens 注入。
    secrets = {
      url = "path:/home/ran/Documents/nix-secrets";
      flake = false;
    };
    
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      dms,
      fcclientPkg,
      secrets,
      nix-index-database,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};
      # 独立构建包时用的 pkgs（允许 unfree，否则 nix build .#fcclient 会拒绝）
      # 注意：不能直接用上面的 pkgs，它不带 allowUnfree 配置
      packagePkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

    in
    {
      # 按需运行的包：nix run .#fcclient（不装进系统，不进 systemPackages）
      # 包定义在仓库外 ~/Documents/nix-packaging/fcclient，经 path 输入引入
      packages.${system}.fcclient = packagePkgs.callPackage fcclientPkg { };

      nixosConfigurations.omen = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules # 系统配置聚合（boot/hardware/network/users/desktop/...）
          ./hardware-configuration.nix

          # ---- 私有配置注入：GitHub token（仓库外 secrets 输入，不进 git）----
          # token 存在才设置（新机器无 token 也能构建，只是 api.github.com 限速）
          {
            nix.settings.access-tokens = lib.mkIf (builtins.pathExists "${secrets}/github-token") (
              "github=${builtins.readFile "${secrets}/github-token"}"
            );
          }

          # ---- DMS (DankMaterialShell) 桌面壳模块（提供 programs.dank-material-shell 选项）----
          dms.nixosModules.default
          # DMS Greeter 登录界面模块（提供 programs.dank-material-shell.greeter 选项，
          # 自动接管 services.greetd 的 default_session.command）
          dms.nixosModules.greeter

          # ---- Nix 客户端与 flake 锁定版本对齐 ----
          # `nix shell nixpkgs#...` / `nix develop` 默认会拉一个新的 nixpkgs，
          # 与系统 flake 锁定版本不一致（多下载一份、行为可能漂移）。
          # 把 registry 的 nixpkgs 指向本 flake 锁定的 nixpkgs，两者永远一致。
          {
            nix.registry.nixpkgs.flake = nixpkgs;
            # nixPath 保留默认（channel 方式），只覆盖 registry 不影响系统内建查找
          }

          # ---- 复用现有 Home Manager 配置（用户级全部继承）----
          home-manager.nixosModules.home-manager
          # 模块写成函数以拿到 NixOS config：把系统级代理配置
          # （modules/proxy.nix 的 options.proxy）注入 HM，用户级 fish 开关/
          # 环境变量与 nix-daemon 共用同一地址（单点修改）
          ({ config, ... }: {
            home-manager = {
              # allowUnfree 已由 configuration.nix 顶层 nixpkgs.config 管理
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
              startAsUserService = true;
              # 🔴 代理地址单一来源注入：HM 模块经 extraSpecialArgs 拿到 config.proxy
              extraSpecialArgs = { proxy = config.proxy; };
              users.ran = {
                # 用户级配置已并入本仓库 home/ 目录（home.nix 的相对 imports 自动解析）
                imports = [ ./home/home.nix ];
              };
            };
          })
  inputs.nix-index-database.nixosModules.nix-index
  {
    programs.nix-index-database.comma.enable = true; # 开启逗号命令(后面会讲)
  }


        ];
      };
    };
}
