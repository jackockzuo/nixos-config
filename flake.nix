{
  description = "NixOS 配置 - HP OMEN 16-wf0xxx (ran)";

  inputs = {
    # 滚动更新通道（和当前 HM 一致）
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # 国内镜像替代（github 拉取不稳时换这个）：
    # nixpkgs.url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixpkgs-unstable/nixexprs.tar.xz";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 现有 Home Manager 配置仓库（单一起源，装机时靠 bind-mount 解析）
    hm-ran.url = "path:/home/ran/.config/home-manager";
  };

  outputs = { self, nixpkgs, home-manager, hm-ran, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.omen = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix

          # ---- 复用现有 Home Manager 配置（用户级全部继承）----
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
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
