# 2026-09-09 fish abbr 通用变量残留（配置删了还存在的根因）

## 现象
HM `shellAbbrs` 里删掉 `nr` 缩写、改为同名 fish 函数后，新开 shell 敲 `nr␣`
仍展开成旧命令，且压过新函数；用户反馈"经常遇见这种删不干净"。

## 根因链
1. 旧版 fish（<3.6）把 `abbr --add` 持久化为**通用变量** `_fish_abbr_<name>`，
   存在 `~/.config/fish/fish_variables` —— 该文件**不在 NixOS/HM 管理范围**。
2. fish ≥3.6 已不再写入 abbr 通用变量（改为 config.fish 每会话 `abbr --add`，
   无状态），但**旧遗留仍被逐会话"导入"**，且不会自清。
3. 因此配置删除只停了"不再新增"，遗留通用变量永远生效 —— 声明式只管自己
   生成的文件，"运行时写入用户状态"的那部分是盲区。

## 处置
```fish
abbr --erase (abbr --list)   # 全清；config.fish 会在新会话按配置重建（session 级）
set -e -U fcproxy_port        # 若已迁入声明式（home.sessionVariables）
```
确认：`cat ~/.config/fish/fish_variables` 只应剩 `__fish_initialized`。
另：fish 4.3+ 迁移产物 `conf.d/fish_frozen_{theme,key_bindings}.fish(.bak)`
可一并删除（fish 会在适当时机自行清理）。

## 防再犯（写入 STANDARDS §10 + env.nix）
- 想保留的运行时值（fcproxy_port）**迁入声明式**，使 `fish_variables` 可整删。
- 删 abbr/通用变量/迁移文件 → `abbr --erase` + **新 shell 验证**（旧会话内存
  里仍持有，退出时可能写回）。
- 排查通用流程：新 shell 仍旧 → 查 mtime 早于最近 rebuild 的非 HM 文件
  （`fish_variables` / `*.hm-bak` / `~/.cache/*`）。
