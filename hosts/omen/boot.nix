# ============================================================
# boot.nix —— omen 专属引导外观与内核参数（STANDARDS §2：机器专属禁止放共享层）
# 内容：Limine 机器专属项（分辨率/品牌/字体留白/Windows 条目）+ nvidia 内核参数
# 颜色：由 catppuccin.limine 统一接管（modules/theme.nix），本文件禁止再写 style 颜色
#   （catppuccin 的 extraConfig 在 limine.conf 最前，任何 style 颜色都会覆盖它）
# 壁纸：不使用（catppuccin.limine 置 style.wallpapers = []，纯 Catppuccin 底色）
# 通用引导配置（Limine 启用/代际/内核选择/zram）在 modules/boot.nix
# ============================================================
_:

{
  boot = {
    loader.limine = {
      resolution = "1920x1200x32"; # 内核早期 fb = 内屏原生(eDP)

      style = {
        interface = {
          resolution = "auto"; # Limine 菜单 = 内屏原生(eDP)
          branding = "◆ Omen 16";
          helpHidden = true; # 让界面极简
        };

        graphicalTerminal = {
          font = {
            scale = "2x2";
            spacing = 2;
          };
          margin = 180; # 加大留白，产生“悬浮控制台”的错觉
          marginGradient = 75; # 边缘虚化
        };
      };

      # ---- 多系统：Windows 11（另一 NVMe 独立 ESP，固件启动项委托）----
      extraEntries = ''
        /Windows 11
          protocol: efi_boot_entry
          entry: Windows Boot Manager
      '';
    };

    # nvidia 兼容内核参数（主机专属；通用参数在 modules/boot.nix 的 kernelParams）
    kernelParams = [
      "ibt=off" # nvidia 兼容
      "nvidia-drm.modeset=1" # 强制 modeset 保证外显在早期亮起
    ];
  };
}
