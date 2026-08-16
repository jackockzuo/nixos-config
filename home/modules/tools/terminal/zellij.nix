{ ... }:

{
  # zellij 终端复用器（Catppuccin Mocha 主题）
  # 现代化改造：原 default.nix 用 xdg.configFile 手写 themes/*.kdl 与 layouts/*.kdl，
  # 现改用 HM 的 programs.zellij 模块（rev 83b7606d）——已核对模块源码
  # （modules/programs/zellij.nix）：themes 选项（attrsOf lines/path）写入
  # ~/.config/zellij/themes/NAME.kdl，layouts 选项（attrsOf lines/path）写入
  # ~/.config/zellij/layouts/NAME.kdl，settings 选项（yamlFormat → KDL 序列化）
  # 处理 config.kdl 的 theme 键
  programs.zellij = {
    enable = true;
    enableFishIntegration = true;

    # 主题文件 → ~/.config/zellij/themes/catppuccin-mocha.kdl
    # （原始 KDL 文本原样透传，与迁移前内容一致）
    themes."catppuccin-mocha" = ''
      themes {
          catppuccin-mocha {
              bg "#1e1e2e"
              fg "#cdd6f4"
              black "#11111b"
              red "#f38ba8"
              green "#a6e3a1"
              yellow "#f9e2af"
              blue "#89b4fa"
              magenta "#cba6f7"
              cyan "#94e2d5"
              white "#cdd6f4"
              orange "#fab387"
          }
      }
    '';

    settings.theme = "catppuccin-mocha";

    # 开发布局 → ~/.config/zellij/layouts/dev.kdl（zellij --layout dev 使用，
    # layout 文件名 dev 即命令里的 dev）
    # 左 pane 全高默认 shell；右 pane 上下分栏：上 shell、下 btop
    layouts.dev = ''
      layout {
          pane split_direction="vertical" {
              pane
              pane split_direction="horizontal" {
                  pane
                  pane command="btop"
              }
          }
      }
    '';
  };
  # 🔴 force 覆盖：zellij 首次运行自动生成默认主题/布局文件，模块生成的
  # configFile 不带 force，此处补上避免 activation 时 checkLinkTargets 报
  # "would be clobbered"（与迁移前的 force = true 语义一致）
  xdg.configFile."zellij/themes/catppuccin-mocha.kdl".force = true;
  xdg.configFile."zellij/layouts/dev.kdl".force = true;
}
