# hardware.nix —— 硬件（NVIDIA 混合显卡/蓝牙/VA-API）
# ============================================================
{ pkgs, config, ... }:

{
  hardware = {
    # NVIDIA RTX 4060
    nvidia = {
      # hardware.nvidia.enabled 是只读选项，由 videoDrivers 含 "nvidia" 自动推导
      open = false;
      modesetting.enable = true;
      nvidiaPersistenced = true;
      # 电源管理（nvidia 官方推荐；配合 nvidia-drm.modeset=1）
      powerManagement.enable = true;
      # 40 系移动端显存精细电源管理
      powerManagement.finegrained = true;
      # nixpkgs 官方 New Feature 分支（与 nvidia_cachyos 同为 610.57.04，不降级）；
      # 跟随当前 boot.kernelPackages，多内核切换时自动配套（见 multikernel.nix）
      package = config.boot.kernelPackages.nvidiaPackages.latest;
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
