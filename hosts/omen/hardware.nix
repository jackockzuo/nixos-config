# hardware.nix —— 硬件（NVIDIA 混合显卡/蓝牙/VA-API）
# ============================================================
{ pkgs, ... }:

{
  hardware = {
    # NVIDIA RTX 4060
    nvidia = {
      # hardware.nvidia.enabled 是只读选项，由 videoDrivers 含 "nvidia" 自动推导 (REF:2026-08-17-nvidia-enabled)
      open = false;
      modesetting.enable = true;
      nvidiaPersistenced = true;
      # 电源管理（nvidia 官方推荐；配合 nvidia-drm.modeset=1）(REF:2026-08-17-nvidia-power)
      powerManagement.enable = true;
      # 40 系移动端显存精细电源管理
      powerManagement.finegrained = true;
      # CachyOS 专用驱动（与 cachyos 内核 kconfig parity 严格配对）
      # 构建修复：cachyos 内核 dev 路径泄漏触发 allowedReferences 纯度检查 → 放宽为 null
      package = pkgs.nvidia_cachyos.overrideAttrs (old: {
        passthru = old.passthru // {
          mod = old.passthru.mod.overrideAttrs (_: {
            allowedReferences = null;
          });
        };
      });
      prime = {
        offload.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      # 13 代核显视频硬解：iHD 必需；libva-vdpau-driver + libvdpau-va-gl 兼容老 X11 应用
      extraPackages = with pkgs; [
        intel-media-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
    bluetooth.enable = true;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
