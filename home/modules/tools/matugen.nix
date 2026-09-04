# matugen 用户模板 —— DMS 换壁纸时自动生成 fish 终端配色
#
# 机制：DMS 换壁纸 → matugen 渲染模板 → ~/.config/fish/colors.matugen.fish
# 约束：
#   - 必须用 [templates] 裸头 + [templates.<名字>] 命名表（DMS 兼容格式）
#   - input_path/output_path 必须用绝对路径（DMS 以 /tmp 临时文件为基准解析）
#   - 模板变量必须带 .default 限定（{{colors.<名>.default.hex}}）
#   - config.toml 必须含 [config] 段（可为空，DMS dry-run 依赖）
# REF:2026-08-17-matugen
{ config, ... }:

{
  # 1. 用户模板文件（mustache 语法，matugen 渲染）
  #    渲染目标：~/.config/fish/colors.matugen.fish
  #    变量：{{colors.<名>.default.hex}}（scheme-tonal-spot 材料配色）
  xdg.configFile."matugen/templates/fish-colors.fish.template" = {
    text = ''
      # 本文件由 matugen 自动生成（DMS 换壁纸时触发），请勿手改。
      # 来源模板：~/.config/matugen/templates/fish-colors.fish.template
      set -g fish_color_normal {{colors.primary.default.hex}}
      set -g fish_color_command {{colors.primary.default.hex}}
      set -g fish_color_param {{colors.on_primary.default.hex}}
      set -g fish_color_error {{colors.error.default.hex}}
      set -g fish_color_quote {{colors.tertiary.default.hex}}
      set -g fish_color_operator {{colors.tertiary.default.hex}}
      set -g fish_color_redirection {{colors.primary_container.default.hex}}
      set -g fish_color_autosuggestion {{colors.surface.default.hex}}
      set -g fish_color_cwd {{colors.secondary.default.hex}}
      set -g fish_color_selection --background={{colors.surface_container.default.hex}}
      set -g fish_color_search_match --background={{colors.surface_container.default.hex}}
      set -g fish_color_option {{colors.tertiary.default.hex}}
    '';
    # 保险起见 force：matugen / 其他工具不会写模板目录，但避免未来同名文件冲突
    force = true;
  };

  # 2. matugen 用户配置：声明模板输入→输出映射
  #    DMS 会合并本文件的 [templates] 段（DMS 兼容格式）
  #    必须含空 [config] 段（DMS dry-run 依赖）(REF:2026-08-17-matugen)
  xdg.configFile."matugen/config.toml" = {
    text = ''
      [config]
      [templates]
      [templates.fish]
      input_path = '${config.home.homeDirectory}/.config/matugen/templates/fish-colors.fish.template'
      output_path = '${config.home.homeDirectory}/.config/fish/colors.matugen.fish'
    '';
    force = true;
  };
}
