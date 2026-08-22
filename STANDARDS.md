# STANDARDS —— NixOS 配置准则（精简版）

> 本仓库修改的唯一依据。**写作原则：每条规则必须防住一次真实事故或一个已知活坑；
> 没有事故背书的预言性规则一律不写。**
>
> 适用：单机 `omen`（HP OMEN 16-wf0xxx，x86_64-linux，单用户 `ran`）。
> 架构：Flakes + flake-parts + home-manager + sops-nix。
> 事故档案：`docs/troubleshooting/`（一档一文件；规则正文引用的事故都在那里）。
> 2026-08-21 精简为本版（旧长篇版见 git 历史）。

---

## 0. 底线（违反 = 系统不可用）

1. **秘密永不落明文**：token/密码只进 `secrets/secrets.yaml`（sops 加密），git 只存密文，`/nix/store` 不允许出现明文秘密。
2. **唯一来源**：代理地址、镜像源、allowUnfree、密码哈希、分区——全仓库各只有一个定义点，其余全部引用。
3. **不碰生成文件**：`hardware-configuration.nix` 不纳入格式化与检查（root 属主、随时被 `nixos-generate-config` 重新生成覆盖）。

---

## 1. 架构（固定，不扩展）

- 入口：`flake-parts.lib.mkFlake { inherit inputs; }`，`systems = [ "x86_64-linux" ]`。
- 主机：`flake.nixosConfigurations.omen`，modules 聚合见 §2。
- 禁止：手写裸 outputs、引 flake-modules-core、用 digga、`mkFlake { inherit self; }`。
- **不预建多主机结构**（hosts/、共享抽象等）——单机用不到，真的多主机那天再建。

---

## 2. 目录与聚合（含架构量化规则，2026-08-21 起为所有项目通用准则）

- `modules/` = 系统级（需要 root/常驻服务/全局 PATH）；`home/` = 用户级（配置/会话环境）。职责不颠倒。
- 一目录一领域、一文件一关注点；`default.nix` 只做 imports（每行带职责注释 = 定位地图）。
- 新增配置 → 领域内新建文件 + 所在目录 `default.nix` 的 imports 加一行；**不留空壳文件**（预留 = 注释一行，用时取消注释）。
- 真实事故记录进 `docs/troubleshooting/`（有事故才写，不预写）。

### 架构量化规则（平衡：快速定位 / 不杂乱 / 文件不长）

1. **一文件 = 一领域**；单文件 **40–200 行**——<40 行的同领域小文件合并进领域文件；>200 行在领域内再拆。
   - 💡 **豁免**：配置密集的领域主体文件（如 starship 提示符模块集、neovim initLua）允许 ≤300 行——强拆会破坏"一工具一文件"直觉、反而增加认知负担（本仓库实测 starship 299 / neovim 249）。
2. **目录 ≤2 层**；聚合链固定为「flake → 目录 default.nix → 文件」。
3. **一个目录文件数 ≤16**（一屏可扫完）。
4. **无预留空壳、无开关矩阵**（options 矩阵一律不建；需要时直接写配置）。
5. **default.nix 只做 imports，且每行带职责注释** = 定位地图。
6. **同领域小文件优先合并**（如 5 个 <60 行的桌面小配置 → misc.nix），合并后超 200 行再拆。

违反即回退该合并/拆分（由 `nix fmt` + `nix flake check` 兜底验证）。

---

## 3. home-manager

- `useGlobalPkgs = true`、`useUserPackages = true`；`extraSpecialArgs = { inherit (config) proxy; }`（代理唯一来源注入，见 §0.2）。
- `startAsUserService = true` + `systemd.user.services.home-manager.wantedBy = [ "default.target" ]`——上游 #3172 开机竞态的唯一修复，**不要动**。
- `home.stateVersion` 保持首次使用值，不随 NixOS 版本升。
- 有官方模块 → `programs.<x>.enable`；纯安装 → `home.packages`；配置文件 → `xdg.configFile`（禁止 `home.file` 指向 `~/.config`）。

---

## 4. 输入法环境变量（双作用域是官方写法，不是重复）

- fcitx 官方 wiki《Setup Fcitx 5》：IM 变量（`XMODIFIERS`/`QT_IM_MODULE`/`SDL_IM_MODULE`）应在**登录会话环境**设置；
  niri wiki《Application-Specific Issues》：niri 的 `environment` 块**不传给 systemd 启动的应用**（如 DMS 及其启动器）。
  因此合成器作用域与系统会话作用域**两者都需要，缺一不可**——这正是本仓库保留两处的原因。
- 落点固定：
  1. **系统会话作用域** → `modules/locale.nix` 的 `environment.sessionVariables`（统一收 XMODIFIERS / QT_IM_MODULE / SDL_IM_MODULE / GLFW_IM_MODULE）。
  2. **合成器作用域** → `home/source/niri/config.kdl` 的 `environment` 块。
  3. `home.sessionVariables` **不重复** IM 变量（与 /etc/profile 作用域重叠），只留用户专属变量。
- 🔴 **GTK 输入法只有一条正路（2026-08-21 事故教训）**：Wayland 原生 GTK3/4 走合成器
  text-input-v3，因此 **GTK3/GTK4 任何形式都不设 im-module**——既不放
  `GTK_IM_MODULE` 环境变量，也**不放 `gtk3/gtk4.extraConfig` 的 `gtk-im-module`**
  （settings.ini 该键对 Wayland 与 X11 同时生效，写了就回退内嵌候选框=原皮），
  还要**主动覆盖官方模块的自动注入**：NixOS fcitx5 模块在其 `environment.variables`
  里写死 `GTK_IM_MODULE = "fcitx"`（经 /etc/profile→set-environment 喂给所有会话，
  仓库内 grep 不到）——必须 `environment.variables.GTK_IM_MODULE = lib.mkForce ""`
  （GTK 空串=未设）才真正关掉。GTK2（仅 X11/XWayland）保留 `gtk-im-module=fcitx`；
  XWayland GTK3 由 GTK3 内建 XIM 兜底（XMODIFIERS 已设）。完整事故链见
  docs/troubleshooting/2026-08-21-fcitx5-gtk-im-module-original-skin.md。
- 🔴 **Qt 输入法双通道（2026-08-21 DMS Spotlight 原皮真根因）**：Qt6 Wayland 应用
  （quickshell 等 systemd user 服务启动的）**只继承系统会话环境**，niri config.kdl
  的 environment 块喂不到它（niri 官方 wiki）——因此 `QT_IM_MODULES = "wayland;fcitx"`
  （Qt 6.7+ 官方变量，合成器 text-input-v3 优先 → classicui 主题生效）**必须放系统层**
  `modules/locale.nix`；`QT_IM_MODULE = "fcitx"` 仅兜底 Qt4/5。缺 `QT_IM_MODULES`
  时 Qt6 强制走 fcitx-qt 应用内嵌候选框=原皮（本次事故）。niri config.kdl 的
  `QT_IM_MODULES` 保留为合成器 spawn 层。
- 改动 IM 变量时两处同步改（§10 checklist 第 5 项兜底）。

---

## 5. 磁盘

- fileSystems 由 `hardware-configuration.nix` 管理（by-uuid）——现状，稳定，不折腾。
- disko 是可选目标：**重新接入顺序 = 重建 `disko.nix`（分区编号/大小/类型与现有盘一致）→ 备份 → `--mode format,mount` 采纳 → 再启用模块**。顺序颠倒会进紧急模式（2026-08-16 实踩）。
- ⚠️ `.snapshots` 禁止声明为"不挂载"子卷（snapper 会报 IO Error）。

---

## 6. 秘密（sops-nix）

- 默认文件 `secrets/secrets.yaml`；密码用 `neededForUsers = true` + `hashedPasswordFile`，不设明文密码。
- 🔴 **私钥必须放 `/` 下**（如 `/var/lib/sops-nix/keys.txt`）：2026-08-17 放 `/home` → 开机时 `/home` 尚未挂载 → shadow 锁死。禁止放任何独立子卷。
- 本机方案 = 既有盘手动拷贝私钥（`/var/lib/...` 与 `~/.config/sops/age/...` 同一私钥两份）；`generateKey` 仅全新装机自动生成。两者互斥。
- 改密码：`mkpasswd -s` → `sops secrets/secrets.yaml` 更新 → rebuild 验证。

---

## 7. 质量门禁（三步，够用）

1. `nix fmt`（nixfmt-rfc-style）
2. `nix flake check`（含 deadnix/statix）
3. `git diff --check`（2026-08-21：尾随空格曾漏进提交）
- CI = 上面三件事，不引第三方服务。
- ⚠️ 禁止 `builtins.pathExists` 条件化配置（纯求值恒 false，包会消失——踩过坑）。

---

## 8. 零容忍

- rebuild/check 的 warning、error、deprecation 当场处理，不允许带病提交。
- 升级 NixOS/HM 大版本前读 release notes，逐条核对仓库受影响项。

---

## 9. 版本

- `nixos-rebuild switch` 验证成功后 `git tag vX.Y.Z`（tag 指向已验证提交）。
- `main` 唯一长期分支，验证后才提交；应急回滚 = `git checkout vX.Y.Z` → rebuild → 回 main。

---

## 10. 提交 checklist（6 项）

- [ ] `nix fmt` 通过
- [ ] `nix flake check` 通过
- [ ] `git diff --check` 无空白错误
- [ ] 无明文秘密进 git（diff 复查 + `secrets/` 仅密文）
- [ ] 注释/表述与改动同步（含本文件；双作用域变量两处同步）
- [ ] rebuild 无新增 warning

---

## 文档锚点（有疑问先查这里）

- flake-parts：<https://flake.parts/getting-started>
- home-manager 手册：<https://nix-community.github.io/home-manager/>
- disko：<https://github.com/nix-community/disko>
- sops-nix：<https://github.com/Mic92/sops-nix>
- niri wiki：<https://niri-wm.github.io/niri/>（Application-Specific Issues / Input method）
- fcitx wiki：<https://fcitx-im.org/wiki/Setup_Fcitx_5>
- nixpkgs release notes：<https://nixos.org/manual/nixos/stable/release-notes.html>