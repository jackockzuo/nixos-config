# 本文件：matugen 用户模板 —— DMS 换壁纸时自动生成 fish 终端配色
#
# ── 机制 / 依赖链 ──────────────────────────────────────────────────────────
# DMS 换壁纸 → dms 调用 matugen（合并 ~/.config/matugen/config.toml 到临时配置
#   文件，经 -c 传给 matugen）→ matugen 渲染本文件声明的用户模板
#   → 生成 ~/.config/fish/colors.matugen.fish → fish 启动时 source 覆盖静态配色
#
# ── 关键研究结论（DMS rev 069ddab0 源码 core/internal/matugen/matugen.go）──
# 1. DMS 的 settings.json 里 runUserMatugenTemplates = true（默认即 true），
#    DMS 每次重新生成主题时会读取用户配置 ~/.config/matugen/config.toml：
#    - buildMergedConfig() 用 extractTOMLSection 提取 [config] 段和 [templates] 段，
#      追加到 DMS 自己生成的内容之后，整体写入 /tmp/matugen-config-*.toml，
#      再 `matugen ... -c /tmp/...` 调用。DMS 从不覆盖 ~/.config/matugen/config.toml。
# 2. ⚠️ 必须用 [templates] 裸头 + [templates.<名字>] 命名表（input_path/output_path），
#    这是 DMS 自家模板（quickshell/matugen/configs/*.toml）的写法；
#    不能写 matugen 文档里常见的 [[templates]] 数组式：
#    - DMS 已先写入 [templates.dank] 等命名表，再接 [[templates]] 数组会触发
#      TOML 解析错误 "Cannot overwrite a value"（实测 tomllib 复现）；
#    - extractTOMLSection 用 strings.Index 找 "[templates]" 子串，[[templates]]
#      会被错切出 "[templates]]\n..." 的坏 TOML。
# 3. ⚠️ input_path / output_path 必须用绝对路径：DMS 把合并结果写到 /tmp 下的
#    临时文件再 -c 传入，matugen 以该临时文件所在目录为基准解析相对路径，
#    相对路径会解析到 /tmp 下而失效。用户模板段是原样追加（不做 SHELL_DIR/
#    CONFIG_DIR 变量替换），所以这里直接写 /home/ran 绝对路径。
# 4. ⚠️ 模板变量必须带 .default 限定：matugen 4.x 的上下文结构是
#    colors.<颜色名>.{dark,light,default}.{color,...}，写 {{colors.primary.hex}}
#    会解析失败（引擎 resolve_path 找不到 "hex" 键 → ResolveError → 渲染失败）。
#    因此下面全部用 {{colors.<名>.default.hex}}。
# ──────────────────────────────────────────────────────────────────────────
{ pkgs, ... }:

{
  # 1. 用户模板文件（mustache 语法，matugen 渲染）
  #    渲染目标：~/.config/fish/colors.matugen.fish（见下方 config.toml 的 output_path）
  #    matugen 提供的变量（scheme-tonal-spot 等 material 方案）：
  #    {{colors.primary.default.hex}} / {{colors.on_primary.default.hex}}
  #    {{colors.error.default.hex}} / {{colors.tertiary.default.hex}}
  #    {{colors.primary_container.default.hex}} / {{colors.surface.default.hex}}
  #    {{colors.secondary.default.hex}} / {{colors.surface_container.default.hex}}
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
  #    DMS 会合并本文件的 [templates] 段（见文件头研究结论），
  #    所以这里用 DMS 兼容的 [templates] + [templates.fish] 命名表格式，
  #    并写绝对路径（DMS 以 /tmp 临时文件为基准解析相对路径）。
  #    [config] 段省略：DMS 通过 -m/-t/--contrast 命令行参数控制配色方案，
  #    写入 [config] 反而可能与 DMS 的 scheme/contrast 设置产生干扰。
  xdg.configFile."matugen/config.toml" = {
    text = ''
      [templates]
      [templates.fish]
      input_path = '/home/ran/.config/matugen/templates/fish-colors.fish.template'
      output_path = '/home/ran/.config/fish/colors.matugen.fish'
    '';
    # force：matugen 首次运行不会自动生成 config.toml，但防止未来其他
    # 工具/手动运行生成同名文件导致 home-manager activation 冲突（与
    # topgrade.toml / btop 等模块的 force 同理）
    force = true;
  };
}
