# ============================================================
# hardware.nix —— 硬件相关（显卡/蓝牙/交换）
# 职责：NVIDIA 混合显卡、图形库（含 VA-API）、蓝牙
# 修改：显卡模式切换/加硬件支持 → 改这里
# 关联：boot.nix（内核参数 nvidia-drm）、performance.nix（zram 交换已移入）
# ============================================================
{ pkgs, ... }:

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
      # 🔴 finegrained：40 系移动端（4060m）显存精细电源管理，极度省电
      # 🎯 [OMEN] 本机 4060m 独有
      powerManagement.finegrained = true;
      # 🔴 配套驱动：CachyOS 官方文档推荐 pkgs.nvidia_cachyos（与 cachyos 内核
      #    kconfig parity 严格配对，chaotic overlay 提供，nyx 缓存有预编译）。
      #    不用 nixpkgs 的 nvidiaPackages（与 cachyos 内核补丁集未严格配对）。
      # 🔴 构建修复：cachyos 内核（LLVM 构建）的 dev 路径会泄漏进 nvidia .ko，
      #    触发 nixpkgs 默认 allowedReferences = [] 纯度检查
      #    （"output ... is not allowed to refer to linux-...-dev"）→ 构建失败。
      #    这里放宽内核模块派生的 allowedReferences（= null 即默认无限制），
      #    代价是闭包多带 kernel.dev（只读引用，约 1-2GB，功能无影响）。
      package = pkgs.nvidia_cachyos.overrideAttrs (old: {
        passthru = old.passthru // {
          mod = old.passthru.mod.overrideAttrs (_: {
            allowedReferences = null;
          });
        };
      });
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
      # 🔴 视频硬解（13 代核显）：intel-media-driver（iHD）必需，4K 视频不占计算核
      #    libva-vdpau-driver（原名 vaapiVdpau）+ libvdpau-va-gl：兼容老 X11/VDPAU 应用（Wayland 下基本用不到，无害）
      #    ⚠️ 不加 vaapiIntel（i965）：那是旧代核显驱动，13 代用 iHD，混装反而可能冲突
      extraPackages = with pkgs; [
        intel-media-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
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
}
