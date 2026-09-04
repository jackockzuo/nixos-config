# STANDARDS —— NixOS 配置准则（精简版）

> 本仓库修改的唯一依据。**写作原则：每条规则必须防住一次真实事故或一个已知活坑；
> 没有事故背书的预言性规则一律不写。**
>
> 适用：**共享核心层平台无关**；机器专属能力（OMEN 解锁/显卡/显示器形态）一律收进
> `hosts/<machine>/` 主机剖面，仅目标机 build 时生效。现仅 `omen`（HP OMEN 16-wf0xxx，x86_64-linux，单用户 `ran`）。
> 架构：Flakes + flake-parts + home-manager + sops-nix；多主机由 flake.nix `hosts` 清单驱动。
> 事故档案：`docs/troubleshooting/`（一档一文件；规则正文引用的事故都在那里）。
> 2026-08-21 精简为本版（旧长篇版见 git 历史）。

---

## 0. 底线（违反 = 系统不可用）

1. **秘密永不落明文**：token/密码只进 `secrets/secrets.yaml`（sops 加密），git 只存密文，`/nix/store` 不允许出现明文秘密。
2. **唯一来源**：代理地址、镜像源、allowUnfree、密码哈希、分区——全仓库各只有一个定义点，其余全部引用。实现方式：
   - **全局常量**（username/stateVersion/代理镜像等环境常量）→ `flake.nix` 顶层 `let my = rec { ... }`，经 `specialArgs = { inherit my; }` 注入所有 NixOS/HM 模块。`my` 内分两类：**身份信息**（username/homeDirectory/stateVersion）和**每机常量**（hostname/hostId 由 `hosts` 清单经 `mkMy hostname hostId` 注入，禁止共享层写死机器标识）。
   - **镜像源/GOPROXY 等网络环境项** → 由各自 modules 的常量管理（如 `modules/nix.nix` substituters/registry/GOPROXY），不塞进 `my`。
   - **禁止**：模块内硬编码地址/用户名；用 `lib.mkForce` 覆盖唯一来源值；使用 `builtins.getEnv`（外部变量必须经 Flake 输入，确保构建封闭性 Hermeticity）。
3. **不碰生成文件**：`hosts/<machine>/hardware-configuration.nix` 不纳入格式化与检查（root 属主、随时被 `nixos-generate-config` 重新生成覆盖）。
4. **事故说明分层**：模块文件内保留「事故根因 → 防再犯规则」（1-2 句）；完整排查过程、环境、恢复流程移入 `docs/troubleshooting/` 对应文件。模块内不重复完整事故链。
5. **第三方软件红线（2026-09-03 起）**：私有/商业/闭源或依赖本机私有服务的程序，其**进程名/地址/端口/路由规则**一律不得出现在 `modules/` 共享层（含 dae 类配置与注释）；需要时经 `hosts/<machine>/` 主机剖面或仓库外独立 flake 引入。违反 = 可移植性损坏（其他机器求值通过但功能失效/断网）。

---

## 1. 架构（多主机，hosts 清单驱动）

- 入口：`flake-parts.lib.mkFlake { inherit inputs; }`，`systems = [ "x86_64-linux" ]`。
- 主机：`flake.nixosConfigurations` 由 `flake.nix` 顶部 `hosts` 清单 `mapAttrs` 生成；每台 =
  `modules/`（通用层）+ `hosts/<machine>/`（主机剖面，见 §2）。现清单仅 `omen`，配置名 `#omen` 不变。
- **加一台机器**：`hosts` 清单加一行（hostId）+ 复制 `hosts/omen/` 为 `hosts/<name>/`
  （重跑 `nixos-generate-config` 覆盖其 `hardware-configuration.nix`，按硬件裁剪 `hardware.nix`）。
- 禁止：手写裸 outputs、引 flake-modules-core、用 digga、`mkFlake { inherit self; }`、在共享层放机器专属模块（违规即回退到 hosts/）。

---

## 2. 目录与聚合（含架构量化规则，2026-08-21 起为所有项目通用准则）

- `modules/` = 系统级（需要 root/常驻服务/全局 PATH，**平台无关**）；`home/` = 用户级（配置/会话环境，**平台无关**）；
  `hosts/<machine>/` = 机器专属（硬件驱动/性能解锁/桌面输出形态/主机 home），**禁止把机器专属内容放共享两层**（2026-09-03 起）。
- 一目录一领域、一文件一关注点；`default.nix` 只做 imports（每行带职责注释 = 定位地图）。
  聚合链固定为「flake → hosts/<machine>/default.nix（或 modules/default.nix）→ 领域文件」。
- 新增配置 → 领域内新建文件 + 所在目录 `default.nix` 的 imports 加一行；**不留空壳文件**（预留 = 注释一行，用时取消注释）。
- 桌面合成器配置 = `home/modules/desktop/niri*.nix`（`wayland.windowManager.niri` 模块的 settings/binds/_children），**禁止手写 kdl**（2026-08-28 迁移，构建期 `niri validate` 兜底）。桌面**输出/显示器形态**属机器专属 → `hosts/<machine>/hm.nix`（如 omen：eDP-1 off / HDMI 主屏）。
- 真实事故记录进 `docs/troubleshooting/`（有事故才写，不预写）。

### 注释精简原则

- **定位注释**（default.nix imports 行）：一行说明该 import 的职责（做什么），不含历史背景、迁移说明。
- **配置注释**（config 块内）：保留事故防再犯规则（§0.4）和唯一来源说明；删除已迁移/已移出的历史说明、emoji 标记（🔴🎯📝）可选用于高危项。
- **历史背景**：移入 `docs/troubleshooting/` 或 git commit message，模块文件不保留。
- **事故引用格式**：模块内防再犯规则须包含 `REF:YYYY-MM-DD-关键词`（如 `REF:2026-08-21-fcitx5-gtk`），全局搜索该 ID 可直达 `docs/troubleshooting/` 对应文件。示例：`# GTK_IM_MODULE 必须 mkForce "" (REF:2026-08-21-fcitx5-gtk)`
- **事故文件命名**：`docs/troubleshooting/` 下文件名**必须**包含对应 REF ID（如 `2026-08-21-fcitx5-gtk.md`），终端 `ls docs/troubleshooting/ | grep ID` 或编辑器 `Ctrl+P` 输入 ID 即可秒开。

### 架构量化规则（平衡：快速定位 / 不杂乱 / 文件不长）

1. **一文件 = 一领域**；单文件 **40–200 行**——<40 行的同领域小文件合并进领域文件；>200 行在领域内再拆。
   - 💡 **豁免一（配置密集）**：配置密集的领域主体文件（如 starship 提示符模块集、neovim initLua）允许 ≤300 行——强拆会破坏"一工具一文件"直觉、反而增加认知负担（本仓库实测 starship 299 / neovim 249）。
   - 💡 **豁免二（纯数据声明，不受行数上限）**：声明式规则/键位表（如 niri 窗口规则、键位绑定、样式主题）**不设行数上限**——这类文件是"顺序即语义"的匹配列表，行数增长只来自数据条目，不增加认知复杂度。**但必须分段并加注释**（如 `# ---- 浏览器规则 ----`），禁止无分隔的长列表。
2. **目录 ≤2 层**；聚合链固定为「flake → 目录 default.nix → 文件」。
3. **一个目录文件数 ≤16**（一屏可扫完）。
4. **无预留空壳、无开关矩阵**（options 矩阵一律不建；需要时直接写配置）。
5. **default.nix 只做 imports，且每行带职责注释** = 定位地图。
6. **同领域小文件优先合并**（如 5 个 <60 行的桌面小配置 → misc.nix），合并后超 200 行再拆。

违反即回退该合并/拆分（由 `nix fmt` + `nix flake check` 兜底验证）。

---

## 3. home-manager

- `useGlobalPkgs = true`、`useUserPackages = true`；`extraSpecialArgs = { inherit my; }`（身份/每机常量注入，见 §0.2）。
- 主机专属 home（依赖某机 CLI/输出形态，如 fish perf-*、niri 输出段）→ `hosts/<machine>/hm.nix`，经
  `home-manager.users.<name>.imports = [ ./hm.nix ]` 引入；共享 home 层禁止引用机器专属二进制。
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
  2. **合成器作用域** → `home/modules/desktop/niri.nix` 的 `settings.environment`（原 home/source/niri/config.kdl，2026-08-28 迁移入 niri 模块）。
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
  （quickshell 等 systemd user 服务启动的）**只继承系统会话环境**，niri 的
  environment 块喂不到它（niri 官方 wiki）——因此 `QT_IM_MODULES = "wayland;fcitx"`
  （Qt 6.7+ 官方变量，合成器 text-input-v3 优先 → classicui 主题生效）**必须放系统层**
  `modules/locale.nix`；`QT_IM_MODULE = "fcitx"` 仅兜底 Qt4/5。缺 `QT_IM_MODULES`
  时 Qt6 强制走 fcitx-qt 应用内嵌候选框=原皮（本次事故）。niri.nix 的
  `settings.environment.QT_IM_MODULES` 保留为合成器 spawn 层。
- 改动 IM 变量时两处同步改（§10 checklist 第 5 项兜底）。

---

## 5. 磁盘

- fileSystems 由 `hosts/<machine>/hardware-configuration.nix` 管理（by-uuid）——现状，稳定，不折腾。
- disko 是可选目标：**重新接入顺序 = 重建 `disko.nix`（分区编号/大小/类型与现有盘一致）→ 备份 → `--mode format,mount` 采纳 → 再启用模块**。顺序颠倒会进紧急模式（2026-08-16 实踩）。
- ⚠️ `.snapshots` 禁止声明为"不挂载"子卷（snapper 会报 IO Error）。
- 🔴 `.snapshots` 必须是真正的 btrfs 子卷（2026-08-29 实测：普通空目录同样报
  `IO Error (.snapshots is not a btrfs subvolume)`，timeline/快照全部静默失败）——
  建子卷：`rmdir /.snapshots /home/.snapshots && sudo btrfs subvolume create /.snapshots /home/.snapshots`。
- **快照保留策略底线**：snapper TIMELINE_LIMIT_* 必须设置（当前：hourly=5, daily=7, weekly=4, monthly=3, yearly=1）。不设保留策略 → btrfs 元数据膨胀 → 空间满后 IO 性能骤降 + metadata 错误（btrfs 活坑）。配置见 `modules/services.nix` snapper 块。
- **快照访问权限**：重要子卷（/、/home）的 snapper 配置必须设 `ALLOW_GROUPS = "wheel"`——普通用户无需 sudo 即可只读访问 `.snapshots`，符合直觉。
- **静默损坏防护**：必须开启 `services.btrfs.autoScrub`（SSD 每月一次，HDD 每季度一次）——防止 bitrot 导致的静默数据损坏。
- **快照 ≠ 备份**：快照用于本地回滚（后悔药），物理损坏/文件系统崩溃会连带快照消失。核心数据（secrets 私钥、Documents、代码）必须有脱离快照的异地备份（Restic/Borg/U盘/Bitwarden）。secrets 物理私钥必须在外部安全介质保留副本。
- **Nix Store 血栓预防**：高频试验大型包（CUDA/LLM/桌面组件）会导致 Store 膨胀到 100GB+，挤压快照空间引发 Metadata 错误。必须启用 `nix.gc` 自动清理（保留 7-14 天）+ `nix.optimise.automatic = true` 硬链接去重。配置见 `modules/nix.nix`。

---

## 6. 秘密（sops-nix）

- 默认文件 `secrets/secrets.yaml`；密码用 `neededForUsers = true` + `hashedPasswordFile`，不设明文密码。
- 🔴 **私钥必须放 `/` 下**（如 `/var/lib/sops-nix/keys.txt`）：2026-08-17 放 `/home` → 开机时 `/home` 尚未挂载 → shadow 锁死。禁止放任何独立子卷。
- 本机方案 = 既有盘手动拷贝私钥（`/var/lib/...` 与 `~/.config/sops/age/...` 同一私钥两份）；`generateKey` 仅全新装机自动生成。两者互斥。
- 改密码：`mkpasswd -s` → `sops secrets/secrets.yaml` 更新 → rebuild 验证。
- 多机：新机的 age 公钥加进 `.sops.yaml` 的 `keys` 与 `creation_rules.key_groups` 后
  `sops updatekeys secrets/secrets.yaml`；同一 secrets.yaml 多机共用（密码/私钥策略不变）。

---

## 7. 质量门禁（三步 + 断言）

1. `nix fmt`（nixfmt-rfc-style）
2. `nix flake check`（含 deadnix/statix）
3. `git diff --check`（2026-08-21：尾随空格曾漏进提交）
4. **断言测试**：硬件专属模块（如 `hosts/omen/omencore.nix`）应加 `assertions` 防误用。`message` 须包含**解决路径**（如何修复）。示例：
   ```nix
   assertions = [{
     assertion = config.networking.hostName == "omen";
     message = "omencore.nix 仅限 omen 主机！请检查 networking.hostName 或禁用本模块。";
   }];
   ```
- CI = 上面四件事，不引第三方服务。
- ⚠️ 禁止 `builtins.pathExists` 条件化配置（纯求值恒 false，包会消失——踩过坑）。

---

## 8. 零容忍

- rebuild/check 的 warning、error、deprecation 当场处理，不允许带病提交。
- 升级 NixOS/HM 大版本前读 release notes，逐条核对仓库受影响项。
- **启动项生存位**：Bootloader 必须保留至少 15-20 个 Generations（`boot.loader.grub.configurationLimit = 10` 已配置，但手动 `nix-collect-garbage -d` 会绕过——禁止在系统微小不稳定时执行，那是自毁长城）。
- **驱动更新离线兜底**：涉及核心驱动（Wi-Fi/GPU）的更新，必须在网络环境良好的情况下进行，并确保本地有上一版本的生成记录（可 `nixos-rebuild switch --rollback` 回退）。

---

## 9. 版本

- `nixos-rebuild switch` 验证成功后 `git tag vX.Y.Z`（tag 指向已验证提交）。
- `main` 唯一长期分支，验证后才提交；应急回滚 = `git checkout vX.Y.Z` → rebuild → 回 main。

---

## 10. 提交 checklist（7 项）

- [ ] `nix fmt` 通过
- [ ] `nix flake check` 通过
- [ ] `git diff --check` 无空白错误
- [ ] 无明文秘密进 git（diff 复查 + `secrets/` 仅密文）
- [ ] 注释/表述与改动同步（含本文件；双作用域变量两处同步）
- [ ] rebuild 无新增 warning
- [ ] **关键服务状态核验**：涉及 systemd 服务的改动，rebuild 后必须 `systemctl --user status <service>` 确认无 `activating (auto-restart)` 等静默失败（NixOS 只保证服务"定义"了，不保证在特定硬件上"跑起来"）

---

## 🎯 [OMEN] 本机硬件要点（仅 omen 剖面；事故背书见 troubleshooting）

- **功耗墙解锁只信 OmenCore CLI 官方接口**（`hosts/omen/omencore.nix` 的 `omen-power-unlock` 服务开机执行
  `perf --mode performance --power-limit 5`，内部封装 hp-wmi/EC 并读回验证——2026-08-30 起零裸 hex）：
  底层通道仍是 `ec_sys` 写 EC 寄存器 `0xBA=5`（write_support=1 必须）；TLP 的 PL 配置（键名须 `PL1_LIMIT_ON_AC`，
  本机仍写不进）、WMAA 固件假 PASS（内核日志 `WMAA/WHCM aborts`）、RAPL 被 EC 实际供电覆盖——全是死路（2026-08-23 事故）。
  2026-09-03 起 CLI-only（GUI/桌面项/root wrapper/omen-hardware-perms 已移除——GUI 需向 wheel 开放整片 EC RAM）。
- **AC 下 CPU 调速器用 `powersave` + EPP `balance_performance`**（`hosts/omen/performance.nix`）：
  `performance` governor 在 intel_pstate 下锁最高频（min=max）→ CPU VRM 电感高频开关 →
  登录桌面后"嗞嗞"线圈啸叫（2026-08-25 实测）；powersave 才是动态调频，重载时 HWP 仍睿频到
  5.2GHz，PL1/PL2 解锁与 scx_lavd 均不受影响，性能无损。
- 改 omencore/功耗/风扇相关配置 → 对照 `docs/troubleshooting/2026-08-23-omen-ec-power-limit-2.5ghz-lock.md`。

## 文档锚点（有疑问先查这里）

- flake-parts：<https://flake.parts/getting-started>
- home-manager 手册：<https://nix-community.github.io/home-manager/>
- disko：<https://github.com/nix-community/disko>
- sops-nix：<https://github.com/Mic92/sops-nix>
- niri wiki：<https://niri-wm.github.io/niri/>（Application-Specific Issues / Input method）
- fcitx wiki：<https://fcitx-im.org/wiki/Setup_Fcitx_5>
- nixpkgs release notes：<https://nixos.org/manual/nixos/stable/release-notes.html>