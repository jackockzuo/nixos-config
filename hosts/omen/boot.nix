# ============================================================
# boot.nix —— omen 专属引导外观与内核参数（STANDARDS §2：机器专属禁止放共享层）
# 内容：Limine 外观（壁纸/配色/品牌）+ 菜单分辨率 + Windows 多系统条目 + nvidia 内核参数
# 通用引导配置（Limine 启用/代际/内核选择/zram）在 modules/boot.nix
# ============================================================
{ pkgs, lib, ... }:

let
  # 蓝色调壁纸目录（JPG 构建期转 PNG；每次开机随机一张）
  wallpaperSrcDir = ../../assets/wallpaper;

  # 读取目录并筛选图片文件（jpg/jpeg/png）
  allFiles = builtins.attrNames (builtins.readDir wallpaperSrcDir);

  imageFiles = builtins.filter (
    name:
    let
      baseName = lib.toLower name;
    in
    lib.hasSuffix ".jpg" baseName || lib.hasSuffix ".jpeg" baseName || lib.hasSuffix ".png" baseName
  ) allFiles;

  # JPG → PNG 转换（PNG 原样保留，统一交给 Limine）
  processImage =
    name:
    let
      srcPath = wallpaperSrcDir + "/${name}";
      isJpg = lib.hasSuffix ".jpg" (lib.toLower name) || lib.hasSuffix ".jpeg" (lib.toLower name);
      newName =
        if isJpg then
          (lib.removeSuffix (if lib.hasSuffix ".jpeg" (lib.toLower name) then ".jpeg" else ".jpg") name)
          + ".png"
        else
          name;
    in
    if !isJpg then
      srcPath
    else
      pkgs.runCommand "limine-wallpaper-${newName}"
        {
          nativeBuildInputs = [ pkgs.imagemagick ];
        }
        ''
          magick "${srcPath}" -quality 100 "$out"
        '';

  processedWallpapers = map processImage imageFiles;
in
{
  boot = {
    loader.limine = {
      resolution = "1920x1200x32"; # 内核早期 fb = 内屏原生(eDP)

      style = {
        wallpapers = processedWallpapers;
        wallpaperStyle = "stretched";
        backdrop = "050A15"; # 极深蓝黑，极致深邃

        interface = {
          resolution = "auto"; # Limine 菜单 = 内屏原生(eDP)
          branding = "◆ Omen 16";
          brandingColor = "7DF0FF"; # 亮电蓝：作为视觉中心
          helpColor = "7390AA"; # 暗灰蓝：降低次要信息的侵略性
          helpColorBright = "A9D1FF";
          helpHidden = true; # 强烈建议隐藏，让界面极简
        };

        graphicalTerminal = {
          font = {
            scale = "2x2";
            spacing = 2;
          };
          palette = "0A1829;F7768E;9ECE6A;E0AF68;7DF0FF;BB9AF7;7DCFFF;D1F1FF";
          brightPalette = "1A2B3E;FF9E64;B9F27C;FF9E64;A9F1FF;DDBBFF;A9F1FF;FFFFFF";

          foreground = "D1F1FF"; # 冰蓝白：柔和而清冷
          background = "AA0A1829"; # 66% 透明度的深蓝幕布

          margin = 180; # 加大留白，产生“悬浮控制台”的错觉
          marginGradient = 75; # 边缘虚化，让菜单框与背景分形完美融合
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
