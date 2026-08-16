# 本文件：atuin 终端历史搜索（SQLite 存储 + TUI 交互搜索）
#
# - 通过 home-manager 的 programs.atuin 模块启用，并开启 fish 集成
#   （↑ 上箭头绑定 atuin 搜索，替代原 shell 历史）
# - settings 为自由透传键值：HM 模块（rev 83b7606d）会把 settings
#   原样写入 ~/.config/atuin/config.toml，键的有效性由 atuin 自身决定
#
# 已验证（本仓库 nixpkgs 0e251e2 中 atuin 版本为 18.18.1，对照
# v18.18.1 源码 crates/atuin-client/src/settings.rs 与默认配置模板
# crates/atuin-client/config.toml）：
#   - enter_accept / workspaces / show_preview / search_mode /
#     keymap_mode / style / inline_height / exit_mode / history_filter
#     均为顶层有效键，取值见下
#   - filter_mode 在 18.18.1 顶层只接受单个字符串（如 "global"），
#     多模式列表须用 [search] 段的 search.filters 表达
#     （即"启用哪些过滤模式 + 循环顺序"，见默认配置模板注释与官方文档）
#   - common_prefix 仅存在于 [stats] 段，非顶层有效键 → 已省略
#   - 主题：atuin 18.x TUI 默认跟随终端的 16 色配色，无需单独 theme
#     配置；本机 kitty 已是 Catppuccin Mocha 16 色主题，atuin 自动匹配
{ pkgs, ... }:

{
  programs.atuin = {
    enable = true;
    # fish 集成：上箭头 / Ctrl-R 打开 atuin 历史搜索
    enableFishIntegration = true;

    settings = {
      # 回车直接执行选中的历史命令（而非先回填到命令行再编辑）
      enter_accept = true;

      # 可用过滤模式及循环顺序（对应旧版 filter_mode 列表语义）：
      # 全局 / 本机 / 本次会话 / 当前目录，不启用 workspace 标签
      search.filters = [ "global" "host" "session" "directory" ];

      # 启用 workspace 过滤模式（与上方 search.filters 组合使用）
      workspaces = true;

      # 搜索时预览选中命令的详细信息
      show_preview = true;

      # 模糊搜索模式
      search_mode = "fuzzy";

      # 启动键位模式：auto 跟随触发 atuin 的 shell 键位（fish 为 emacs）
      keymap_mode = "auto";

      # 界面紧凑样式
      style = "compact";

      # 内联搜索框最大行数
      inline_height = 24;

      # Esc 退出时回填原始命令（而非退出时保留查询词）
      exit_mode = "return-original";

      # 全局历史过滤正则列表，空列表 = 不过滤
      history_filter = [ ];
    };
  };
}
