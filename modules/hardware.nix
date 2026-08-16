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
      open = true;
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
  services.xserver.videoDrivers = [ "nvidia" ];

  # ============ 交换：zram ============
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
}
