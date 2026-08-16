{ ... }:

{
  # onefetch：git 仓库信息面板（Catppuccin Mocha 配色）
  # onefetch 0.7+ 从 ~/.config/onefetch/config.yml 读取配色
  # 注：onefetch 无 HM 模块（已核对 raw.githubusercontent.com rev 83b7606d
  # 返回 404），xdg.configFile 即现代正确做法，保持原样
  xdg.configFile."onefetch/config.yml" = {
    text = ''
      # Catppuccin Mocha
      color:
        title: "#cba6f7"
        diagonal: "#313244"
        underscores: "#313244"
        punctuation: "#a6adc8"
        description: "#cdd6f4"
        info: "#89b4fa"
        hash: "#f5c2e7"
        author: "#a6e3a1"
        email: "#94e2d5"
        branch: "#fab387"
        language: "#cdd6f4"
        languages: "#cdd6f4"
        license: "#cdd6f4"
        commits: "#f9e2af"
        performers: "#cdd6f4"
        statistics: "#cdd6f4"
        style: "#cdd6f4"
        all_commits: "#cdd6f4"
        block: "#cdd6f4"
    '';
    force = true;
  };
}
