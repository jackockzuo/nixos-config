# ============================================================
# hardware.nix —— 硬件相关（显卡/蓝牙/交换）
# 职责：NVIDIA 混合显卡、图形库、蓝牙、zram 交换
# 修改：显卡模式切换/加硬件支持 → 改这里
# 关联：boot.nix（内核参数 nvidia-drm）
# ============================================================
_:

{
  hardware = {
    # ============ NVIDIA RTX 4060（open 驱动，package 自动匹配）============
    nvidia = {
      # 🔴 NVIDIA 主开关说明（2026-08-17 排查结论）：
      #    本 nixpkgs 中 hardware.nvidia.enabled 是只读选项，由
      #    services.xserver.videoDrivers 含 "nvidia"（见下方）自动推导为 true，
      #    模块自动加载 nvidia 内核模块 + 黑名单 nouveau，无需（也不能）手动设置。
      #    之前机器上 nouveau 在跑，是因为系统仍用旧内核/旧 generation 引导，
      #    未重启到新 generation（内核 7.1.8 + nvidia 595 模块已在 store）。
      open = false;
      modesetting.enable = true;
      nvidiaPersistenced = true;
      # 🔴 电源管理：DPMS/运行时电源控制，解决 Wayland 下休眠唤醒后合成器崩溃
      #（nvidia 官方推荐配置；配合 nvidia-drm.modeset=1 使用）
      powerManagement.enable = true;
      prime = {
        # 混合显卡：默认 offload（按需调用独显）
        offload.enable = true;
        # sync.enable = true;      # 若内屏直连独显，改用这行并注释掉 offload
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    graphics = {
      enable = true;
      enable32Bit = true; # 32 位图形库（Steam/Wine 需要）
    };
    # ============ 蓝牙（DMS bluez 面板 + 笔记本日常）============
    bluetooth.enable = true;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # ============ 交换：zram ============
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
}
