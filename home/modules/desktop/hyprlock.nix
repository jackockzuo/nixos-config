# ============================================================
# hyprlock.nix —— 锁屏（官方模块 programs.hyprlock）
# 原 source/niri/hyprlock.conf + hyprlock-colors.conf 迁移：
# 颜色 $vars 直接内联为 settings 顶层键（原 source = 引入文件的机制不再需要）
# 说明：hyprlock 二进制由系统层安装（packages.nix），package = null 只管配置；
#       PAM 认证在系统层 modules/desktop.nix 的 security.pam.services.hyprlock
# ============================================================
_:

{
  programs.hyprlock = {
    enable = true;
    package = null; # 系统层已装（packages.nix），HM 只管配置

    settings = {
      # ---- Material 调色板（原 hyprlock-colors.conf，rgba 为 matugen 色值）----
      "$background" = "rgba(131318ff)";
      "$error" = "rgba(ffb4abff)";
      "$error_container" = "rgba(93000aff)";
      "$inverse_on_surface" = "rgba(303036ff)";
      "$inverse_primary" = "rgba(555a92ff)";
      "$inverse_surface" = "rgba(e4e1e9ff)";
      "$on_background" = "rgba(e4e1e9ff)";
      "$on_error" = "rgba(690005ff)";
      "$on_error_container" = "rgba(ffdad6ff)";
      "$on_primary" = "rgba(262b60ff)";
      "$on_primary_container" = "rgba(e0e0ffff)";
      "$on_primary_fixed" = "rgba(10144bff)";
      "$on_primary_fixed_variant" = "rgba(3d4279ff)";
      "$on_secondary" = "rgba(2e2f42ff)";
      "$on_secondary_container" = "rgba(e1e0f9ff)";
      "$on_secondary_fixed" = "rgba(191a2cff)";
      "$on_secondary_fixed_variant" = "rgba(444559ff)";
      "$on_surface" = "rgba(e4e1e9ff)";
      "$on_surface_variant" = "rgba(c7c5d0ff)";
      "$on_tertiary" = "rgba(45263cff)";
      "$on_tertiary_container" = "rgba(ffd8eeff)";
      "$on_tertiary_fixed" = "rgba(2e1126ff)";
      "$on_tertiary_fixed_variant" = "rgba(5e3c53ff)";
      "$outline" = "rgba(91909aff)";
      "$outline_variant" = "rgba(46464fff)";
      "$primary" = "rgba(bec2ffff)";
      "$primary_container" = "rgba(3d4279ff)";
      "$primary_fixed" = "rgba(e0e0ffff)";
      "$primary_fixed_dim" = "rgba(bec2ffff)";
      "$scrim" = "rgba(000000ff)";
      "$secondary" = "rgba(c5c4ddff)";
      "$secondary_container" = "rgba(444559ff)";
      "$secondary_fixed" = "rgba(e1e0f9ff)";
      "$secondary_fixed_dim" = "rgba(c5c4ddff)";
      "$shadow" = "rgba(000000ff)";
      "$source_color" = "rgba(5a61b1ff)";
      "$surface" = "rgba(131318ff)";
      "$surface_bright" = "rgba(39393fff)";
      "$surface_container" = "rgba(1f1f25ff)";
      "$surface_container_high" = "rgba(2a292fff)";
      "$surface_container_highest" = "rgba(34343aff)";
      "$surface_container_low" = "rgba(1b1b21ff)";
      "$surface_container_lowest" = "rgba(0e0e13ff)";
      "$surface_dim" = "rgba(131318ff)";
      "$surface_tint" = "rgba(bec2ffff)";
      "$surface_variant" = "rgba(46464fff)";
      "$tertiary" = "rgba(e7b9d5ff)";
      "$tertiary_container" = "rgba(5e3c53ff)";
      "$tertiary_fixed" = "rgba(ffd8eeff)";
      "$tertiary_fixed_dim" = "rgba(e7b9d5ff)";

      # ---- 字体变量（原 hyprlock.conf 顶部）----
      # 锁屏是 UI 组件，用系统默认中文字体（Maple Mono 仅终端使用）
      "$font" = "Noto Sans CJK SC";
      "$font_clock" = "Noto Sans CJK SC";

      general = {
        hide_cursor = false; # 锁屏时不隐藏鼠标光标
        "ignore_empty_input" = true; # 输入框为空时回车不显示"验证失败"
      };

      animations = {
        enabled = true;
        bezier = "linear, 1, 1, 0, 0";
        animation = [
          "fadeIn, 1, 3, linear" # 淡入
          "fadeOut, 1, 5, linear" # 淡出
          "inputFieldDots, 1, 2, linear" # 密码圆点跳动
        ];
      };

      # ---- 背景：当前屏幕截图 + 磨砂玻璃质感 ----
      background = [
        {
          monitor = ""; # 应用到所有显示器
          path = "screenshot";
          color = "$surface"; # 截图加载失败的兜底背景色
          "blur_size" = 5; # 模糊半径
          "blur_passes" = 4; # 模糊迭代次数（越高越平滑，越耗性能）
          noise = 0.01; # 防色带
          contrast = 1.3000;
          brightness = 0.8000; # 背景别太亮
          vibrancy = 0.2100;
          "vibrancy_darkness" = 0.0;
        }
      ];

      # ---- 视觉重心上移：时间占屏幕上方 1/3，中下部留白 ----
      # 小时（大字，带阴影立体感）
      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo \"<b><big> $(date +\"%H\") </big></b>\"";
          color = "$primary";
          "font_size" = 130;
          "font_family" = "$font_clock";
          "shadow_passes" = 3;
          "shadow_size" = 4;
          position = "0, 29%";
          halign = "center";
          valign = "center";
        }
        # 分钟（与小时保持 13% 黄金间距）
        {
          monitor = "";
          text = "cmd[update:1000] echo \"<b><big> $(date +\"%M\") </big></b>\"";
          color = "$primary";
          "font_size" = 130;
          "font_family" = "$font_clock";
          "shadow_passes" = 3;
          "shadow_size" = 4;
          position = "0, 16%";
          halign = "center";
          valign = "center";
        }
        # 星期几（低频更新，省资源）
        {
          monitor = "";
          text = "cmd[update:18000000] echo \"<b><big> \"$(date +'%A')\" </big></b>\"";
          color = "$secondary";
          "font_size" = 28;
          "font_family" = "$font";
          position = "0, 7%";
          halign = "center";
          valign = "center";
        }
        # 日期（月 日）
        {
          monitor = "";
          text = "cmd[update:18000000] echo \"<b> \"$(date +'%b %d')\" </b>\"";
          color = "$secondary";
          "font_size" = 18;
          "font_family" = "$font";
          position = "0, 4%";
          halign = "center";
          valign = "center";
        }
      ];

      # ---- 底部交互区：密码输入框 ----
      "input-field" = [
        {
          monitor = "";
          size = "9%, 3.1%"; # 百分比宽高，适配不同分辨率
          "outline_thickness" = 2;
          "dots_size" = 0.26;
          "dots_spacing" = 0.64;
          "dots_center" = true;
          "dots_rounding" = -1; # -1 = 完美圆形
          rounding = 12;
          "outer_color" = "$primary $tertiary $primary"; # 渐变：主色→第三色→主色
          "inner_color" = "$surface_container";
          "font_color" = "$on_surface";
          "check_color" = "$secondary";
          "fail_color" = "$error";
          "fade_on_empty" = false; # 空输入也保持显示
          "placeholder_text" = "<i>Password...</i>";
          position = "0, 10%";
          halign = "center";
          valign = "bottom";
        }
      ];
    };
  };
}
