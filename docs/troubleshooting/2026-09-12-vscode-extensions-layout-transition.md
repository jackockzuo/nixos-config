# 疑难杂症：VS Code 无法安装 Typst 扩展 + home-manager 激活失败（extensions 目录布局切换）

- 日期：2026-09-12
- 状态：✅ 已解决
- 影响范围：`~/.vscode/extensions` 停留在旧代际的只读 store 软链 → VS Code 既装不了市场扩展，声明的 `myriad-dreamin.tinymist` 也不出现；`home-manager.service` 处于 `failed`
- 涉及文件：`home/modules/tools/dev.nix`（`mutableExtensionsDir`）
- 关联：`programs.vscode`（home-manager 模块，`mkVscodeModule.nix`）

---

## 症状

- VS Code 扩展面板搜 Tinymist/Typst → 点安装报错（目录只读/无法写入）。
- 命令行 `code --install-extension myriad-dreamin.tinymist` 同样失败。
- dev.nix 里明明声明了 `myriad-dreamin.tinymist`，`~/.vscode/extensions` 里却没有它。

## 环境

- home-manager `programs.vscode`，`profiles.default` 声明扩展；工作树把 `mutableExtensionsDir` 从 `false` 改成 `true` 并新增 `myriad-dreamin.tinymist`。
- 上一代（gen 244）仍是 `mutableExtensionsDir = false` 的「整目录软链」布局。

## 排查过程（关键证据）

1. `readlink -f ~/.vscode/extensions` → `/nix/store/n2af19...-vscode-extensions/share/vscode/extensions`（只读 store），`touch` 报 `只读文件系统`。
2. `systemctl --user status home-manager.service` → `failed (Result: exit-code)`，`ExecStart=.../54bnr...-home-manager-generation/activate` 退出 1。
3. journal：`Activating linkGeneration` → `Creating home file links` → 退出 1；末尾告警停在 `~/.vscode/extensions/usernamehw.errorlens`。
4. `~/.vscode/extensions` 软链指向 gen 244 的 `home-manager-files`（旧布局），而当前 generation 247 的 `home-files` 里 `.vscode/extensions` 已是**真实目录**（新布局）。

## 根因分析

home-manager 的 `mutableExtensionsDir` 两种布局互斥：

- `false`：`~/.vscode/extensions` 是**指向 store 的单个软链**（整目录只读）。
- `true`：`~/.vscode/extensions` 是**真实目录**，里面每个扩展一条软链（可被 VS Code 增删）。

从 `false` 切到 `true` 时，新代际要往 `~/.vscode/extensions/<扩展名>` 写链接，但 `~/.vscode/extensions` 本身还是「指向只读 store 的软链」。home-manager 的 `linkGeneration` 对「父目录是软链」的目标走慢路径，直接 `ln -Tsf`，软链会穿透进只读 store → `Read-only file system` → `exit 1` → `home-manager.service` 失败 → `~/.vscode/extensions` 永远停在旧代际。

于是：VS Code 写入失败（装不了市场扩展），且新增的 `myriad-dreamin.tinymist` 从未落地。

## 解决

选择**纯声明式**（与本模块注释、STANDARDS §0.2 封闭性一致）：

1. `home/modules/tools/dev.nix`：`mutableExtensionsDir = false;`（回到整目录 store 软链布局）。
2. `nix fmt && nix flake check` → `sudo nixos-rebuild switch --flake .#omen`（或 `nr`）。

切回 `false` 时目标是单个软链（`~/.vscode/extensions`），父目录 `~/.vscode` 不是软链，走快路径直接换链——**不会**再触发上面的穿透问题。

> 若确实要保留 `mutableExtensionsDir = true`（允许市场装扩展）：必须**先手动** `rm ~/.vscode/extensions`（它只是个软链）再激活，否则同样卡死。

## 防再犯规则

- 保持 `mutableExtensionsDir = false`，扩展全部声明式；**禁止手工装扩展**（(REF:2026-09-12-vscode-extensions-layout-transition)）。
- 任何 `mutableExtensionsDir` 的 `true/false` 切换，切换前先 `rm ~/.vscode/extensions`（旧布局软链是切换的唯一障碍）。
- 提交 checklist 第 7 条（关键服务状态核验）必须覆盖 `home-manager.service`：`systemctl --user status home-manager.service` 不得为 `failed`——本次事故正是它静默失败了 3 个代际。
