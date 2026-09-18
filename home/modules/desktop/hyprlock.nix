# ============================================================
# hyprlock.nix —— 锁屏（官方模块 programs.hyprlock）
# 职责：锁屏配置；二进制由本模块安装（不再依赖系统层 packages.nix）
# PAM 认证：系统层 modules/desktop.nix 的 security.pam.services.hyprlock
# ============================================================
_:

{
  programs.hyprlock = {
    enable = true;

    settings = {
      # 调色板变量（$base/$surface0/$text/$accent/$pink/$red...）由
      # catppuccin.hyprlock 经 source 注入（见 home/modules/theme/）

      # 字体变量（锁屏是 UI 组件，用系统默认中文字体）
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

      # 背景：当前屏幕截图 + 磨砂玻璃质感
      background = [
        {
          monitor = ""; # 应用到所有显示器
          path = "screenshot";
          color = "$base"; # 截图加载失败的兜底背景色
          "blur_size" = 5; # 模糊半径
          "blur_passes" = 4; # 模糊迭代次数（越高越平滑，越耗性能）
          noise = 0.01; # 防色带
          contrast = 1.3000;
          brightness = 0.8000; # 背景别太亮
          vibrancy = 0.2100;
          "vibrancy_darkness" = 0.0;
        }
      ];

      # 视觉重心上移：时间占屏幕上方 1/3，中下部留白
      # 小时（大字，带阴影立体感）
      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo \"<b><big> $(date +\"%H\") </big></b>\"";
          color = "$accent";
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
          color = "$accent";
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
          color = "$subtext1";
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
          color = "$subtext1";
          "font_size" = 18;
          "font_family" = "$font";
          position = "0, 4%";
          halign = "center";
          valign = "center";
        }
      ];

      # 底部交互区：密码输入框
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
          "outer_color" = "$accent $pink $accent"; # 渐变：主色→粉色→主色
          "inner_color" = "$surface0";
          "font_color" = "$text";
          "check_color" = "$accent";
          "fail_color" = "$red";
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
