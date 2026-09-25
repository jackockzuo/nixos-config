# ============================================================
# virtualisation.nix —— 容器与虚拟化
# 职责：podman（distrobox 后端）、AppImage 支持、FUSE
# 修改：容器配置 → 改这里
# 关联：packages.nix（podman/distrobox 二进制）、users.nix（podman 组）
# ============================================================
_:

{
  # ============ AppImage 支持 ============
  programs.appimage = {
    enable = true;
    binfmt = true; # 允许直接执行
  };
  programs.fuse.userAllowOther = true; # AppImage/容器用户态挂载需要

  # ============ podman（distrobox 后端：shell-utils.nix distrobox / users.nix podman 组）============
  # 不开 dockerSocket：rootful 兼容 socket（/run/podman/podman.sock）≈ root；distrobox 用 rootless 即可
  virtualisation.podman.enable = true;

  virtualisation.containers = {
    enable = true;
    containersConf.settings = {
      engine = {
        env = [ "CONTAINERS_REGISTRIES_CONF=/etc/containers/registries.conf" ];
      };
    };
    registries.settings = {
      registry = [
        {
          location = "docker.io";
          # 配置国内可用的 mirror
          mirror = [
            { location = "docker.1ms.run"; }
            { location = "docker.xuanyuan.me"; }
            { location = "hub.rat.dev"; }
          ];
        }
      ];
    };
  };
}
