# 疑难杂症：kitty 毛玻璃消失（niri config.kdl 被覆盖成默认模板）

- 日期：2026-08-17
- 状态：✅ 已解决（含监控项）
- 影响范围：kitty 终端毛玻璃/透明效果消失（连带 binds/output/layout/rule/animations 的 include 一并丢失）
- 涉及文件：无仓库改动（`~/.config/niri/config.kdl` 运行时被外部覆盖）
- 关联：与 [2026-08-17-niri-login-sops-password.md](./2026-08-17-niri-login-sops-password.md) 同一次故障恢复期发现

---

## 症状

- kitty 终端毛玻璃/透明效果消失，背景看起来是实心；
- `~/.config/kitty/kitty.conf` 内容**正常**（`background_blur 1` + `background_opacity 0.8`，kitty 0.48.2，niri 26.04）。

## 环境

- niri 26.04（支持 ext-background-effect）、kitty 0.48.2（支持 blur ≥0.46.2）
- niri 配置由 home-manager 的 `wayland.windowManager.niri` 模块生成
  （2026-08-28 起：settings attrset → 单文件 config.kdl，构建期 `niri validate` 校验，
  部署为 store 只读 symlink；事故发生时仍是"拆分 include + force=true"旧架构）
- DMS（DankMaterialShell）greeter 配置了 `configHome = "/home/ran"`（同步用户 DMS 设置到 greeter）

## 排查过程（时间线 + 关键证据）

1. **确认 kitty 侧全部正常**：配置文件最新（0.8 + blur）、kitty 0.48.2、niri 26.04 → 问题不在 kitty；
2. **发现 niri 配置异常**：`~/.config/niri/config.kdl`（生效）是 **27264 字节的默认模板**，无任何 `include`；而 `config.kdl.bak` 是 HM symlink（原版）；
3. **对比 HM 原版**：store 内原版 config.kdl = 8676 字节，含 `include "binds.kdl" / "rule.kdl" / "output.kdl" / "layout.kdl" / "blur.kdl" / "animations.kdl"` 共 6 个；
4. **时间线定位**：8-16 22:33 重启进 gen48（此时密码已被 sops 链锁死，22:33:55 首次登录失败）→ **22:49 config.kdl 被覆盖**（无用户会话，仅 greeter 在跑）→ 23:34 二次重启；
5. **排除嫌疑**：
   - greeter 模块 preStart（root）：只操作 `/var/lib/dms-greeter`（拷贝用户 DMS 设置/壁纸），不碰 niri 配置 ✅排除；
   - HM 激活：22:49 无 rebuild/switch 记录 ✅排除；
   - 用户会话：22:33–23:35 无会话打开 ✅排除；
   - 覆盖者**未 100% 锁定**：最可能是 DMS greeter 运行时边界情况（仅发生一次，01:29 正常登录后 mtime 未再变）。

## 根因分析

niri 的 `config.kdl` 被某进程（无用户会话期间）覆盖为**默认模板**，丢失全部 include → niri 未加载 `blur.kdl`（毛玻璃规则）→ kitty 的透明窗口没有模糊效果。**kitty 是受害者**；binds/output/layout/rule/animations 的 include 也一并丢失（快捷键、显示器、布局等回到默认）。

## 修复方案

1. 从 HM store 恢复 config.kdl 原版（8676 字节，含全部 include）；
2. 恢复为 **store 只读 symlink**（目标只读，open-for-write 类误写会失败；之前被"mv symlink → .bak + 新建文件"绕过）；
3. 清理残留的 `config.kdl.bak`；
4. **自愈机制**：每次 `nixos-rebuild switch`，HM 重新部署 `~/.config/niri`，被覆盖自动复原。
5. **2026-08-28 架构升级**：config.kdl 改为 `wayland.windowManager.niri` 模块生成
   （单文件 + 构建期 `niri validate`），毛玻璃规则内联进 settings（不再有 include 可丢）；
   "被覆盖成默认模板" 的故障形态变为"整文件被替换"——HM 自愈机制不变。

验证：`head -5 ~/.config/niri/config.kdl` 应看到 home-manager 生成头注释（Automatically generated…）；
重启 niri 会话后毛玻璃恢复。

## 恢复流程（一条命令）

```bash
# 从当前部署的 HM files 恢复（路径随构建变化，用 readlink 定位）
HMF=$(readlink ~/.config/niri/config.kdl | sed 's|/config.kdl$||')
rm -f ~/.config/niri/config.kdl ~/.config/niri/config.kdl.bak
ln -s "$HMF/config.kdl" ~/.config/niri/config.kdl
niri msg action quit   # 重启 niri 会话生效
```

## 经验教训（防再犯）

1. **窗口特效"配置文件正常但效果没了" → 先查合成器配置**（niri config.kdl 是否被覆盖、内容是否还是模块生成版）；
2. **HM 管理的文件从 symlink 变成真实文件 = 被外部覆盖的信号**（对比 `ls -la` 与 store 原版）；
3. 排查覆盖者：先查时间窗口内有哪些进程有写权限（用户会话？root 服务？greeter？），再对照各组件源码的写路径。

## 遗留事项（TODO）

- [ ] **若重启后毛玻璃再次消失**（config.kdl 再次被覆盖）→ 查 `/tmp/dms-greeter.log`（greeter 日志已开启）锁定覆盖者，考虑调整 DMS greeter 的 `configHome` 或 niri 集成选项根治；
- [ ] 当前为 store 只读 symlink + HM 自愈兜底，未根治覆盖源头（源未 100% 锁定）。
