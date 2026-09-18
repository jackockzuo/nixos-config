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

  # ============ podman（distrobox 后端）============
  #distrobox（依赖 rootless podman；NixOS 正确姿势是 virtualisation.podman，
  #手写 systemd.services.podman 会与 podman 自带单元冲突变成 bad-setting）
  virtualisation.podman = {
    enable = true;
    # 不开 dockerSocket：它暴露的是 rootful Docker 兼容 socket（/run/podman/podman.sock，
    #   docker 组≈root）。distrobox 用 rootless podman 即可，无需此面。
    #   若确需 Docker-API 客户端，改用 rootless 用户 socket（systemd.podman.socket 用户服务）。
  };
}
