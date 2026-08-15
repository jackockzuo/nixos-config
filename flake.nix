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
    # 用户级配置仓库（GitHub 自包含，任意机器可拉取）
    # 本地开发时也可改回 path:/home/ran/.config/home-manager
    hm-ran.url = "path:/home/ran/.config/home-manager";
    hm-ran.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      hm-ran,
      dms,
      ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.omen = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix

          # ---- DMS (DankMaterialShell) 桌面壳模块（提供 programs.dank-material-shell 选项）----
          dms.nixosModules.default
          # DMS Greeter 登录界面模块（提供 programs.dank-material-shell.greeter 选项，
          # 自动接管 services.greetd 的 default_session.command）
          dms.nixosModules.greeter

          # ---- 复用现有 Home Manager 配置（用户级全部继承）----
          home-manager.nixosModules.home-manager
          {
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
              users.ran = {
                # 导入 HM 仓库的 home.nix（它的相对 imports 自动解析）
                imports = [ "${hm-ran}/home.nix" ];
              };
            };
          }
        ];
      };
    };
}
