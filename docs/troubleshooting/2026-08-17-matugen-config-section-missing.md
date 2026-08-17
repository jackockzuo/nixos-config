# 疑难杂症：DMS 切换壁纸动态主题生成失败（matugen config.toml 缺 [config] 段）

- 日期：2026-08-17
- 状态：✅ 已解决
- 影响范围：DMS 换壁纸时动态主题（Material You）生成整体失败——fish 终端配色、kitty dank 主题等全部不更新
- 涉及文件：`home/modules/tools/theming/matugen.nix`（config.toml 加 `[config]` 空段 + 修正研究结论）
- 关联：与 [2026-08-17-niri-login-sops-password.md](./2026-08-17-niri-login-sops-password.md) 同一次故障恢复期发现

---

## 症状

- DMS 切换壁纸后主题生成失败（无新配色生成）；
- `~/.config/fish/colors.matugen.fish` 一直不存在；
- 日志报错：`matugen dry-run failed ... TOML parse error ... missing field 'config'`。

## 环境

- DMS（DankMaterialShell）`settings.json`：`matugenTemplateKitty: true` 等（换壁纸时经 matugen 生成各应用主题）
- matugen 4.1.0（DMS 调用，`--dry-run --json hex --old-json-output`，v4=true）
- 用户模板：`~/.config/matugen/templates/fish-colors.fish.template`（HM 管理）

## 排查过程（关键证据）

1. **journal 报错**（01:57:17）：
   ```
   dms: DMS API Error: matugen dry-run failed: matugen [image ... -m dark -t scheme-tonal-spot
        --json hex --dry-run --source-color-index 0 --old-json-output] failed (v4=true):
       TOML parse error at line 1, column 1
       1 | [templates]
         | ^
       missing field `config`
   ```
2. **命令特征**：报错命令**没有 `-c /tmp/...` 参数** → DMS 的 theme dry-run 是**直接解析用户 `~/.config/matugen/config.toml`**（不走 buildMergedConfig 合并路径）；
3. **用户配置内容**：`~/.config/matugen/config.toml` 只有 `[templates]` + `[templates.fish]`，**无 `[config]` 段** → matugen 4.x 顶层结构要求 `config` 字段存在 → 解析失败；
4. **DMS 合并路径**（`core/internal/matugen/matugen.go`）确认：buildMergedConfig 缺 [config] 时会补写空段（不报错），但 dry-run 路径不经过它。

## 根因分析

`matugen.nix` 原注释决策"省略 `[config]` 段，避免与 DMS 的 scheme/contrast 参数冲突"是**错误的**：
- matugen 4.x 的 config.toml **必须**含 `[config]` 段（可为空），否则 TOML 反序列化报 `missing field 'config'`；
- DMS 的 theme dry-run 直接解析用户 config.toml（不带 `-c`），缺失即整体失败；
- **空 `[config]` 不设 scheme/contrast**，与 DMS 的 `-m/-t/--contrast` 命令行参数无冲突——原"干扰"担忧不成立。

## 修复方案

1. **立即生效**：部署的 `~/.config/matugen/config.toml` 顶部加 `[config]` 空段（真实文件覆盖 HM symlink）；
2. **持久根治**：`home/modules/tools/theming/matugen.nix` 的 config.toml text 加 `[config]`，并新增研究结论第 5 条（必须含 [config] 段）；
3. **验证**：复现 DMS 的 dry-run 命令 → exit 0，成功输出主题 JSON。

验证：DMS 切一次壁纸 → 无报错；`~/.config/fish/colors.matugen.fish` 生成；`dank-theme.conf`/`dank-tabs.conf` mtime 更新。

## 恢复流程（无 rebuild 立即修复）

```bash
rm -f ~/.config/matugen/config.toml
cat > ~/.config/matugen/config.toml <<'EOF'
[config]
[templates]
[templates.fish]
input_path = '/home/ran/.config/matugen/templates/fish-colors.fish.template'
output_path = '/home/ran/.config/fish/colors.matugen.fish'
EOF
# 验证（应 exit 0）
/nix/store/va8gwx9i7zi85lnjmq114dbh3psfslsh-matugen-4.1.0/bin/matugen image ~/Pictures/Wallpapers/wallhaven-yq8w67.jpg -m dark -t scheme-tonal-spot --json hex --dry-run
```

> ⚠️ 部署文件已被覆盖为真实文件（非 HM symlink）；下次 rebuild 后由更新后的 HM store 版本接管（同样含 `[config]`）。

## 经验教训（防再犯）

1. **matugen 4.x 的 config.toml 必须含 `[config]` 段**（空段即可）——即使方案/对比度由命令行控制，段头也必须存在；
2. **"省略以避免冲突"类决策必须实测验证**：原注释基于理论推断省略 [config]，实测 dry-run 直接解析用户配置才暴露；
3. DMS 有两条 matugen 路径：theme dry-run（直接读用户 config.toml，无 -c）与 buildMergedConfig（合并到 /tmp 后 -c 传入）——排查时注意报错命令是否带 `-c` 以判断走哪条路径。

## 遗留事项（TODO）

- [ ] 无（已根治；下次 rebuild 部署新 store 版本后，手动覆盖的真实文件会被 HM 正确接管）。
