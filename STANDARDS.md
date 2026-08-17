# NixOS 配置准则（STANDARDS）

> 本文件是本仓库**唯一权威的修改依据**。任何对 `flake.nix`、`modules/`、`home/`、`secrets/`、`disko.nix`
> 的修改必须先对照本准则：符合准则 → 直接改；不符合 → 先改准则（PR 评审），再改配置。
>
> 适用机器：`omen`（HP OMEN 16-wf0xxx，x86_64-linux，单用户 `ran`）
> 最后评审：2026-08-16（依据 flake-parts 1.x / disko 1.13 / home-manager 26.05 / sops-nix master 官方文档）

---

## 0. 总原则（不可违反）

1. **事实标准优先**：以 Nix 官方生态的事实标准为准——Flakes + flake-parts 为核心架构；不写已被官方弃用的旧写法。
2. **声明式唯一来源（Single Source of Truth）**：任何配置项（代理地址、镜像源、allowUnfree、秘密、分区）全仓库只允许有一个定义点，其余全部引用它。
3. **深度模块化**：一目录一领域，一文件一关注点；聚合入口只做 `imports`，不写业务配置。
4. **warning/error 零容忍**：任何 rebuild / check 输出中的 warning、error、deprecation 提示都必须当场处理，不允许带病提交。
5. **官方文档为准**：写法有疑问时，以官方文档为准（本文件第 9 节的链接清单），不要凭记忆或旧教程。
6. **秘密永不落明文**：密钥/密码/token 一律进 `secrets/`（sops 加密），git 只存密文；`/nix/store` 不允许出现明文秘密。

---

## 1. 核心架构：Flakes + flake-parts

### 1.1 必须使用 flake-parts

- `flake.nix` 的入口必须是 `flake-parts.lib.mkFlake { inherit inputs; }`，禁止手写 `outputs = ...` 裸 flake。
- `inputs.flake-parts.url = "github:hercules-ci/flake-parts"`，并加 `flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs"`（保证 nixpkgs-lib 单一）。
- **不要再单独引用 `flake-modules-core`**：2024 年拆分出的 `flake-modules-core` 已合并回 `flake-parts` 仓库（GitHub 重定向回原仓库），现只引 `flake-parts` 一个 input。
- `systems` 用 `nix-systems/default`：`inputs.systems.url = "github:nix-systems/default"`，`systems = import inputs.systems;`；单机也可直接 `systems = [ "x86_64-linux" ];`。

标准骨架（迁移后形态）：

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    git-hooks.url = "github:cachix/git-hooks.nix";   # 原 pre-commit-hooks.nix，2025 已更名
    # ... 其他（dms / nix-index-database 等按需保留）
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks.flakeModule
        ./modules          # NixOS 模块（含 hosts 定义）
        # 注意：home/ 不走 flake 模块路线（§3.1），经 home-manager.nixosModules.home-manager
        #       的 home-manager.users.ran = ./home/home.nix 引用，不在此 import
      ];
      perSystem = { config, self', pkgs, ... }: {
        treefmt = {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        };
        # packages / devShells 等按需
      };
    };
}
```

### 1.2 NixOS 配置定义

- 用 flake-parts **内置** `flake.nixosConfigurations` 与 `flake.nixosModules` 选项，**不存在也不引入** `nixosModules.flakeModule` 这类第三方"标准模块"（调研确认无此模式）。
- 多主机预留：`flake.nixosConfigurations.omen = { ... };` 每主机一个文件，目录即模块（`imports = [ ./hosts/omen ./hosts/common ... ]`）。
- 跨系统取包用顶层模块参数 `withSystem`，不要在 `perSystem` 里定义 nixosConfigurations。

### 1.3 已废弃写法清单（禁止）

| ❌ 旧写法 | ✅ 新写法 |
|---|---|
| `mkFlake { inherit self; }` | `mkFlake { inherit inputs; }`（防无限递归） |
| `perSystem = system: { ... }` | `perSystem = { system, ... }: { ... }` |
| `flake.overlay` | `flake.overlays.default` |
| 同时引 `flake-parts` + `flake-modules-core` | 只引 `flake-parts`（已合并） |
| `github:cachix/pre-commit-hooks.nix` | `github:cachix/git-hooks.nix`（旧名仅重定向） |
| digga 的 `lib.mkFlake` / `withSystem` | flake-parts 原生 `withSystem` 模块参数 |
| `flake-parts-lib.mkSubmoduleOptions` / `mkDeferredModuleOption` | 直接 `mkOption` / `mkPerSystemOption`（2026-01 弃用） |

---

## 2. 目录结构：深度模块化

```
nixos-config/
├── flake.nix                    # 唯一入口（flake-parts）
├── flake.lock
├── STANDARDS.md                 # 本文件
├── README.md                    # 装机指南（分区部分迁移到 disko 后同步更新）
├── .sops.yaml                   # sops 密钥规则（age 公钥）
├── disko.nix                    # 声明式分区（btrfs 子卷布局）
├── hosts/
│   └── omen/
│       ├── default.nix          # 主机聚合（imports 下方各领域）
│       ├── hardware.nix         # 硬件专属（GPU/蓝牙/zram）—— 由 nixos-generate-config --no-filesystems 生成 + 手改
│       └── (可选) secrets.nix   # sops.secrets 声明
├── modules/                     # NixOS 系统级模块（共享于所有主机）
│   ├── default.nix              # 聚合入口（只 imports）
│   ├── system.nix               # stateVersion / allowUnfree 等基础
│   ├── boot.nix                 # GRUB 双系统
│   ├── nix.nix                  # nix-daemon / 镜像源 / GC
│   ├── proxy.nix                # options.proxy 单一来源
│   ├── locale.nix               # 时区/语言/输入法
│   ├── services.nix             # pipewire/snapper/tlp/...
│   ├── performance.nix          # 🎯 本机性能计算优化（scx/irqbalance/TLP/zram/fd）
│   └── ...
├── home/                        # home-manager 用户级模块
│   ├── home.nix                 # 聚合入口（imports）—— 被 flake 以 home-manager.users.ran 引用
│   ├── modules/                 # core/env/desktop/tools/network（现状保留）
│   └── source/                  # 配置文件源（niri/dms/beautify）
├── secrets/                     # sops 加密秘密（只存密文，可进 git）
│   └── secrets.yaml             # ENC[AES256_GCM,...]
├── assets/                      # 静态资源（grub 主题等）
├── docs/troubleshooting/        # 疑难杂症记录（一病一档，见该目录 README.md 约定）
└── .github/workflows/           # CI（nix flake check + treefmt）
```

**强制规则：**
- 新增配置 → 在对应领域新建 `<关注点>.nix`，并在所在目录 `default.nix` 的 `imports` 加一行。
- 新增故障记录/排查文档 → 进 `docs/troubleshooting/`（`<日期>-<症状>.md`），并在其 `README.md` 索引表加一行。
- **本机独有配置标记（🎯 [OMEN]）**：任何硬件绑定 / 单机特有 / 影响行为的调优（性能、功耗、驱动修复、挂载选项）必须在注释前缀 `# 🎯 [OMEN]`，并写清"为什么本机特有 + 关闭方法"。能做成 options 开关的（如 `options.omen.performance.enable`）优先用开关，实现"一行标记/关闭"。
- 系统级（需要 root/全局 PATH/常驻服务）进 `modules/`；用户级（配置/会话环境）进 `home/modules/`；两者职责不得颠倒。
- 预留模块（firewall/vpn/...）保持"注释即可启用"，删除时同步删 imports 行，禁止留空壳文件。
- **删除死代码**：`configuration.nix` 是遗留文件（flake 从未引用它），迁移期删除，避免误导"这里还能改配置"。

---

## 3. 用户管理：home-manager

### 3.1 集成方式（必须）

- 用 `home-manager.nixosModules.home-manager`（官方模板与社区主流，15+ 知名配置一致）。`flakeModule` 路线仅在需要 `flake.homeConfigurations` 独立构建时引入，本仓库**不采用**。
- 选项固定为：
  - `useGlobalPkgs = true` ✅（省一次 nixpkgs 求值，overlay/unfree 由系统层管）
  - `useUserPackages = true` ✅（包进 `/etc/profiles/per-user/$USER`，且 `environment.pathsToLink = [ "/etc/profile.d" ]` 使 `home.sessionVariables` 覆盖整个图形登录会话）
  - `extraSpecialArgs = { inherit inputs; }` ✅（传递 flake inputs，禁止用 `_module.args`）
  - `sharedModules` ✅ 用于跨用户公共模块（当前单用户可不设，预留）
  - **`startAsUserService = true` ✅ 保留（调研确认，2026-08）**：该选项 26.05 新增、官方标注"非 pam_mount 场景仍实验性"，**但它是上游真实 bug #3172（boot 期 HM 激活 vs 用户 dbus-broker 竞态，导致登录后 `systemctl --user` 报 `org.freedesktop.systemd1 exited with status 1`）的唯一受支持修复**。本机曾实证踩中该竞态。无替代修复（PR #3405 未合并；#3172 2026 仍开放）。**配套必须**：`systemd.user.services.home-manager.wantedBy = [ "default.target" ]`（模块不自动启用用户服务，需手动补，否则登录时不激活）。**重评条件**：#3172/#8565 上游修复后。已知 tradeoff：#8565（用户单元无法依赖 nix-daemon.socket）、#9762（enableLegacyProfileManagement 被忽略）。
- 用户配置引用：`home-manager.users.ran = ./home/home.nix;`（或 `imports = [ ./home/home.nix ]`，等价）。

### 3.2 用户级模块写法

- 入口 `home/home.nix` 只做 `imports = [ ./modules/core.nix ./modules/env.nix ./modules/desktop ./modules/tools ./modules/network ];`。
- 有官方模块的工具 → `programs.<name>.enable = true`（自动接 shell 集成/会话变量/服务）；纯安装无配置 → `home.packages`。
- 配置文件：`~/.config` 下用 `xdg.configFile`（支持 `source/text/recursive/onChange/force/mkOutOfStoreSymlink`）；隐藏点文件用 `home.file.".<name>"`；禁止 `home.file` 指向 `~/.config`（语义重复）。
- imports 保持静态，条件逻辑一律 `lib.mkIf` 写在模块内部（保证 `nixos-option` 内省可靠）。
- fish：`users.users.ran.shell = pkgs.fish`（NixOS 自动写 `/etc/shells`）+ `programs.fish.enable = true`；**`programs.fish.promptInit` 已移除** → 用 `interactiveShellInit`；会话变量经 babelfish 翻译的 `hm-session-vars.fish` 自动加载，无需手写。

### 3.3 stateVersion（当前 24.05 是正常的）

- `home.stateVersion = "24.05"` 配 NixOS `25.05` **不是 bug**：stateVersion 是 home-manager 版本标记，不是 NixOS 版本，应保持首次使用的版本，仅在阅读对应 release notes 并迁移后升级。
- 真正要匹配的是**分支**：home-manager input 分支必须与 nixpkgs 分支一致（`nixos-unstable` ↔ `master`；`nixos-25.05` ↔ `release-25.05`），并 `inputs.nixpkgs.follows = "nixpkgs"`。

---

## 4. 磁盘管理：Disko 声明式分区

### 4.1 必须引入 disko

- `inputs.disko.url = "github:nix-community/disko"`（当前 1.13.x），flake 中 `imports = [ inputs.disko.nixosModules.disko ]`。
- 分区布局唯一来源是 `disko.nix`（本仓库根目录），`hardware-configuration.nix` 中的 `fileSystems`/`swapDevices` 由 disko 的 `_config` 自动生成（`disko.enableConfig` 默认 true），**禁止再手写 fileSystems**。
- `hardware-configuration.nix` 保留硬件部分（initrd 内核模块/kvm-intel/microcode），用 `nixos-generate-config --no-filesystems --root /mnt` 重新生成后并入 `hosts/omen/hardware.nix`。

本机 btrfs 布局（与现状 @/@home/@nix 完全一致，迁移无痛）：

```nix
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/...";   # 用 by-id，禁止裸 /dev/nvme0n1
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0022" "dmask=0022" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@"     = { mountpoint = "/";     mountOptions = [ "compress=zstd" "noatime" ]; };
              "@home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "noatime" ]; };
              "@nix"  = { mountpoint = "/nix";  mountOptions = [ "compress=zstd" "noatime" ]; };
              # snapper 快照目录：独立子卷 + 挂载（快照不递归自身）
              # ⚠️ 禁止声明为"不挂载"子卷（"/.snapshots" = { }）：运行时不可见，
              #    snapper 会报 "IO Error (open failed path:/.snapshots errno:2)"
              "/.snapshots"      = { mountpoint = "/.snapshots";      mountOptions = [ "noatime" ]; };
              "/home/.snapshots" = { mountpoint = "/home/.snapshots"; mountOptions = [ "noatime" ]; };
            };
          };
        };
      };
    };
  };
}
```

**disko 命令（禁止再用 `--mode disko`，已废弃）：**
- 全新安装：`nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount /home/ran/nixos-config/disko.nix`
- **采纳现有系统（不毁数据）**：`sudo nix run github:nix-community/disko/latest -- --mode format,mount /home/ran/nixos-config/disko.nix`——disko 的 create 脚本全部有 blkid 幂等守护（已存在的分区表/文件系统/子卷自动跳过）。
  - ⚠️ 前提：`disko.nix` 的分区**编号/大小/类型必须与现有盘完全一致**（现有 p1=ESP 1G、p2=btrfs 剩余）。sgdisk 按编号创建分区，若布局不匹配会报 "partition already exists"/"no free sectors" 并中断。
- 单一命令装机流：`disko-install`（disko 官方封装：分区+挂载+生成配置+安装一步完成）。

### 4.2 与 snapper 的配合

- disko 无原生 snapper 集成（btrfs 类型无 snapshots 选项）。`.snapshots` 有两种正确方案，**二选一，禁止混用**：
  - **方案 A（推荐，最干净）**：如上 disko 配置，`.snapshots` 声明为**挂载**的独立子卷（`mountpoint = "/.snapshots"`）。快照存放在独立子卷中，快照 `/` 时自动排除 `.snapshots` 自身（btrfs 子卷快照不包含其他子卷）。迁移后删除 `systemd.tmpfiles` 中对应的 `.snapshots` 目录规则（子卷挂载点已存在，tmpfiles `d` 规则变为无害 no-op，删除更干净）。
  - **方案 B（现状，零改动）**：保持 `systemd.tmpfiles` 目录方案（`.snapshots` 是普通目录），disko 配置中**不要**声明 `.snapshots` 子卷。缺点：快照 `/` 会递归包含 `.snapshots` 内的历史快照，靠 snapper 的清理策略兜底。
  - ⚠️ 两种方案均**禁止**声明"不挂载"的 `.snapshots` 子卷（`"/.snapshots" = { }`）：创建但不挂载 → 运行时路径不可见 → snapper 服务报 `IO Error`。
- `services.snapper` 现有配置（root/home 时间线 + ALLOW_GROUPS=wheel）保持不变；挂载选项 `compress=zstd` 必须**所有子卷一致**（btrfs 首挂载决定设备级选项，disko#331，修复 PR #1220 尚未合并——这是已知活坑）。

---

## 5. 秘密管理：sops-nix（禁止 agenix）

### 5.1 选型结论（2026-08 调研）

- **采用 sops-nix**：维护极活跃（2026-08-16 仍有提交，10 commits/30 天）；支持一文件多秘密（GitHub token + WiFi 密码 + API key 共用一个 `secrets.yaml`）；`sops secrets.yaml` 编辑器原地解密编辑，`sops diff` 明文差异；sops 文件自带 MAC 防篡改；`neededForUsers` 使密码管理成为一等公民。
- **不采用 agenix**：2026-02 之后零提交、最后 release 2023-12；一秘密一文件 + `secrets.nix` 注册表同步繁琐；无 MAC。
- 明确边界：sops 原生 SSH key 支持（PR #970）未合并 → **一律用 `ssh-to-age` 转换的 key 或独立 age key，禁止裸 SSH key 进 `.sops.yaml`**；两方案均非后量子安全，文档中不承诺。

### 5.2 目录与规则

```
secrets/
├── .gitignore            # 禁止提交 *.tmp / 解密中间产物（可选）
└── secrets.yaml          # 加密后提交 git（ENC[AES256_GCM,...]），永不存明文
.sops.yaml                # 仓库根：creation_rules + age 公钥
```

`.sops.yaml`（注意 `key_groups` 内**不要**在第二个 key 前写 `-`，会触发 shamir 分片）：

```yaml
keys:
  - &omen age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
      - age:
          - *omen
```

```bash
# 生成 age key（私钥永不进仓库/进 git）
age-keygen -o ~/.config/sops/age/keys.txt
# 或从现有 SSH ed25519 转换
nix run nixpkgs#ssh-to-age -- -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt    # 得到公钥，写入 .sops.yaml
# 加 key 后必须同步
sops updatekeys secrets/secrets.yaml
```

### 5.3 NixOS / home-manager 接线

```nix
# hosts/omen/ 内
{ config, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];   # flake 顶层 imports 亦可

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  # 主机解密 key：首次启动自动生成（generateKey）或指定 sshKeyPaths
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;

  sops.secrets.github-token = { };      # → /run/secrets/github-token
  sops.secrets.wifi-ssid = { };
  sops.secrets.wifi-psk = { };

  # 密码（替代 initialPassword，见 5.4）
  sops.secrets.user-password.neededForUsers = true;   # 必须在 users 创建前解密
  users.users.ran = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user-password.path;
  };

  # 消费示例：systemd 服务读秘密
  systemd.services.xxx.serviceConfig.EnvironmentFile =
    config.sops.templates."xxx.env".path;
}
```

home-manager 侧：`home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ]`；用户级秘密走 `sops-nix.service`（systemd user unit）解到 `$XDG_RUNTIME_DIR/secrets.d`。

### 5.4 迁移事项（现状 → sops）

1. 删除 `flake.nix` 的 `secrets`（path: 输入）与 `nix.settings.access-tokens` 注入，改为 `sops.secrets.github-token` + `sops.templates`（或 `environmentFile`）注入 `nix.settings.access-tokens`。
2. `users.nix` 的 `initialPassword = "ran"` / root 密码 → `sops.secrets.*-password.neededForUsers = true` + `hashedPasswordFile`（用 `mkpasswd -s` 生成哈希存入 secrets.yaml；`neededForUsers` 秘密不能设 `owner`）。
3. 迁移顺序：先建 sops 文件并切到 `hashedPasswordFile`，验证 `/run/secrets/*` 就绪后再删旧 `path:` 输入与明文密码。
4. **impermanence 警示**：若未来用 tmpfs 根，`sops.age.keyFile` 必须落在持久化路径（如 `/nix/persist/...`）。
5. 已知限制写进文档：initrd 阶段不解密；`nixos-rebuild test` 先于 `switch` 验证。
6. 🔴 **keyFile 必须放开机早期可达的位置（`/` 下，如 `/var/lib/sops-nix/keys.txt`）**：
   `neededForUsers` 秘密在 initrd 激活阶段解密，此时独立子卷（如 `/home`）尚未挂载。
   放 `/home` 下会导致 sops 读不到密钥 → 密码文件从不生成 → shadow 锁死（2026-08-17 事故根因，实测 `/home` 晚挂载 4 秒）。禁止把 keyFile 放 `/home` 或任何独立子卷内。

---

## 6. 代码质量：格式化 / lint / CI

### 6.1 treefmt-nix（必须）

- `imports = [ inputs.treefmt-nix.flakeModule ]`；`treefmt.programs.nixfmt.enable = true`（nixfmt-rfc-style，官方 RFC 风格）。统一入口：`nix fmt`。
- 全部 .nix 文件（flake.nix / modules/** / home/** / disko.nix）必须通过 `nix fmt --check`，提交前必跑。

### 6.2 git-hooks.nix（必须，原 pre-commit-hooks.nix）

```nix
imports = [ inputs.git-hooks.flakeModule ];
perSystem = { config, ... }: {
  pre-commit.settings.hooks = {
    nixpkgs-fmt.enable = true;      # 或 treefmt 已在做 → 二选一
    deadnix.enable = true;          # 死代码检测
    statix.enable = true;           # 反模式检查（可选）
  };
};
```

- 校验目标：`self.checks.${system}.pre-commit-check`。

### 6.3 CI（GitHub Actions）

- 每个 PR：`nix flake check`（含 treefmt 检查 + pre-commit-check）+ `nix fmt -- --fail-on-change`。
- 不引入外部服务依赖；用 `DeterminateSystems/nix-installer-action` + `magic-nix-cache-action`。
- ⚠️ **fcclientPkg 特殊处理**：它是仓库外 path 输入（`/home/ran/Documents/nix-packaging/fcclient`），CI 无此目录。
  - CI 命令：`nix flake check --override-input fcclientPkg "path:${GITHUB_WORKSPACE}/.ci/fcclient-placeholder"`
  - 占位包 `.ci/fcclient-placeholder/default.nix`（`{ pkgs }: pkgs.hello`）仅求值不构建。
  - ⚠️ **禁止**用 `builtins.pathExists` 条件化 packages（纯求值下恒 false，本机包会消失——踩过坑）。
  - `--override-input` 必须 `path:` 前缀 + 绝对路径（相对路径解析到 flake 自身，报错误导）。

---

## 7. warning / error 零容忍流程

1. **`nix flake check` 必须 100% 通过**才能提交；`nixos-rebuild dry-build` 无 error 才能 `switch`。
2. **warning 当场处理**，禁止注释掉/绕过：
   - deprecation（如 `mkSubmoduleOptions`、旧选项名）→ 按第 1.3 节换新写法；
   - "Unknown key in section" 类 systemd 警告 → 核对 `unitConfig` vs `serviceConfig` 归属（历史案例：greetd StartLimit，已修复）；
   - HM 弃用警告（如 `gtk4.theme` 需 `null` 显式声明）→ 按 release notes 迁移。
3. 每次 `nixos-rebuild` 输出中出现新 warning 时：记录 → 修根因 → 验证消失，三步走；**不允许"已知警告但先这样"**。
4. 升级 NixOS/HM 大版本前：必读 `nixpkgs/release-notes` 与 `home-manager/docs/release-notes/rl-*.md`，逐条核对本仓库受影响项。
5. 每次 `nix flake lock` 更新后：`nix flake check` + `nixos-rebuild dry-build` 双验证。

---

## 8. 现状审计（2026-08-16 基线，迁移路线图）

### 8.1 当前偏差清单（必须按路线图修正）

| # | 现状问题 | 违反准则 | 修正动作 |
|---|---|---|---|
| 1 | ~~`configuration.nix` 遗留死代码~~ ✅ 已删除（2026-08） | §2 深度模块化 | 完成 |
| 2 | ~~裸 flake，无 flake-parts~~ ✅ 已迁移（2026-08） | §1.1 | 完成（`mkFlake` + `flake.nixosConfigurations`，`nix flake check` 全绿） |
| 3 | ~~秘密用仓库外 `path:` 输入 + `initialPassword` 明文~~ ✅ **迁移完成（2026-08）**：GitHub token + ran/root 密码哈希全部迁入 sops（`secrets/secrets.yaml` 加密 + `modules/secrets.nix` 接线，`neededForUsers` 管理密码）；`path:` 输入已删、`~/Documents/nix-secrets` 已删；store 零明文泄漏（toplevel 依赖扫描验证） | §0.6 / §5 | 完成 |
| 4 | 分区靠 README 手动 parted，无 disko | §4.1 | ⚠️ **2026-08-16 已回退**：disko 接入曾导致 `nixos-rebuild test` 进紧急模式（disko 采纳动作未执行，生成的 fileSystems 引用不存在的 `.snapshots` 子卷 → 挂载失败）。fileSystems 已恢复由 `hardware-configuration.nix`（by-uuid）管理。**未来接入 disko 必须先执行 `--mode format,mount` 采纳，再启用模块** |
| 5 | ~~allowUnfree 重复声明~~ ✅ 已收敛（2026-08） | §0.2 单一来源 | 完成（仅 system.nix） |
| 6 | ~~`startAsUserService = true`（26.05 实验特性）~~ ✅ 调研确认保留（2026-08） | §3.1 | 保留（上游 #3172 竞态修复，无替代）；补 `wantedBy` 启用登录激活 |
| 7 | ~~镜像源系统层/用户层重复硬编码~~ ✅ 已收敛（2026-08） | §0.2 | 完成（仅 modules/nix.nix；客户端经 daemon 继承） |
| 8 | ~~无 treefmt / git-hooks / CI~~ ✅ treefmt+git-hooks+CI 已启用（2026-08） | §6 | treefmt(nixfmt)+statix+deadnix 全绿；CI（ci.yml：flake check + fmt 门禁）已建 |
| 9 | `~/.config/nixpkgs/config.nix` 的 allowUnfree | §3.2 | **保留 + 注释澄清**：作用域与 #5 不同——系统层 `nixpkgs.config` 只管 `nixos-rebuild`/HM 包解析；此文件管命令行客户端（`nix profile add`/`nix-env`/`nix-shell`）装 unfree 包，删除会破坏该能力。非冗余，是必需配置 |
| 10 | ~~`hardware-configuration.nix` 的 fileSystems 与 disko 职责重叠~~ ✅ 已回退（2026-08） | §4.1 | 回退完成：fileSystems 恢复 `hardware-configuration.nix`（by-uuid）管理；`hardware-detect.nix`/`disko.nix` 已删除。disko 接入需先采纳（§4.1 警示） |
| 11 | `home.stateVersion = "24.05"` 与 NixOS `25.05` | §3.3 | **保持不动**（正确行为），仅核对分支匹配 |

### 8.2 迁移路线图（分阶段，每阶段结束必须 `nix flake check` 通过）

- **Phase 0（清理）**：#1 删除 configuration.nix；#5/#7/#9 单一来源收敛。风险：无。立即做。
- **Phase 1（架构）**：#2 迁移 flake-parts（1.1 骨架 + treefmt + git-hooks 引入）。风险：低，纯结构重组，`nix flake check` 兜底。✅ **已完成（2026-08-16）**：flake-parts 迁移 + treefmt/statix/deadnix 全绿 + 存量 71 处 statix/deadnix 警告清零。
- **Phase 2（磁盘）**：#4 disko 声明式分区。⛔ **2026-08-16 已回退**：曾接入 disko.nix 并通过 check/dry-build，但 `nixos-rebuild test` 进紧急模式——**根因：disko 采纳动作（`--mode format,mount`）未执行，生成的 fileSystems 引用不存在的 `.snapshots` 独立子卷导致挂载失败**。经验教训：**先采纳（改分区）→ 再启用模块**，顺序不可颠倒。fileSystems 已恢复 `hardware-configuration.nix` 管理。未来重试：备份 → `disko --mode format,mount` → 启用模块 → test → switch。
- **Phase 3（秘密）**：#3 sops-nix 迁移（5.4 顺序），删除 path: 输入与 initialPassword。风险：中，先 `nixos-rebuild test`。✅ **已完成（2026-08-16）**：GitHub token → sops（`secrets/secrets.yaml` + `modules/secrets.nix`，NIX_CONFIG 注入 nix-daemon）；ran/root 密码 → `hashedPasswordFile`（`neededForUsers` 在 users 创建前解密）；`path:` 输入与 `~/Documents/nix-secrets` 删除；store 零明文泄漏。⚠️ 已泄露的旧 token 需在 GitHub 撤销后更新（见 §5.4 流程）。
- **Phase 4（质量）**：#8 CI + pre-commit 全量启用。✅ **已完成（2026-08-16）**：`ci.yml`（GitHub Actions：`nix flake check` + `nix fmt -- --fail-on-change`）建立；fcclientPkg 仓库外 path 输入用 `.ci/fcclient-placeholder` override 解决（CI 无该目录）；本机/CI 双环境验证通过。
- **Phase 5（可选演进）**：#6 ✅ 已调研解决（2026-08）：保留 startAsUserService + 补 wantedBy；多主机预留 `hosts/` 目录（当前单机可仅保留 `hosts/omen`）。

### 8.3 Phase 2 待执行：disko 采纳现有盘（用户操作）

> 配置已接入并验证（fileSystems 由 disko 生成，`nix flake check` + dry-build 全绿）。
> 以下采纳动作会**改变系统磁盘挂载**，需**备份后**由用户手动执行：

```bash
# 0. 前置：备份（snapper 快照 + 数据备份）
# 1. 采纳现有盘（不毁数据，blkid 幂等：已存在的分区表/文件系统/子卷跳过，
#    仅创建缺失的 .snapshots 独立子卷 + 下次挂载启用 compress=zstd/noatime）
sudo nix run github:nix-community/disko/latest -- --mode format,mount \
  /home/ran/nixos-config/disko.nix

# 2. 重建（fileSystems 生效，fstab 由 disko 生成）
sudo nixos-rebuild switch --flake .#omen

# 3. 验证
findmnt / /home /nix /boot /.snapshots /home/.snapshots   # 挂载点 + 选项
cat /etc/fstab                                            # disko 生成的 fstab
sudo snapper -c root list                                 # snapper 正常
```

**⚠️ 采纳后的已知后果（方案 A 已确认）**：
- `.snapshots` 独立子卷**遮蔽** @ 内的历史快照目录 → 历史快照不可见（数据不丢）
- 如需保留历史快照：采纳前手动迁移 `@/.snapshots` 与 `@home/.snapshots` 内容到独立子卷
- `compress=zstd` 仅对新写入数据生效；旧数据不压缩（可选 `btrfs filesystem defragment -r -czstd` 全盘压缩）
- 采纳后原 `hardware-configuration.nix` 不再存在（硬件部分在 `modules/hardware-detect.nix`）

---

## 9. 官方文档锚点（有疑问先查这里）

- flake-parts：<https://flake.parts/getting-started> · <https://flake.parts/options/flake-parts> · <https://wiki.nixos.org/wiki/Flake_Parts> · <https://nix.dev/concepts/flakes>（官方明确推荐 flake-parts 的 dendritic pattern）
- home-manager 手册：<https://nix-community.github.io/home-manager/>（NixOS 模块选项 · nix-flakes · upgrading/stateVersion · dotfiles）
- disko：<https://github.com/nix-community/disko>（README / docs/reference.md / docs/HowTo.md / example/btrfs-subvolumes.nix）
- sops-nix：<https://github.com/Mic92/sops-nix>（README 的 .sops.yaml 与 neededForUsers 段落 · modules/sops/default.nix）
- nixpkgs release notes：<https://nixos.org/manual/nixos/stable/release-notes.html>
- 官方规则清单（RFC）：nixfmt-rfc-style（<https://github.com/NixOS/nixfmt>）

---

## 10. 修改流程（提交 checklist）

任何修改 PR 必须通过：

- [ ] `nix flake check` 全绿（含 treefmt、pre-commit-check）
- [ ] `nix fmt --check` 通过
- [ ] `nixos-rebuild dry-build` 无 error，无**新增** warning
- [ ] 无明文秘密进入 git（`git diff` 检查 + `secrets/` 仅密文）
- [ ] 单一来源原则未破坏（修改点是否还有第二处需要同步改？）
- [ ] stateVersion / 分支匹配未破坏
- [ ] STANDARDS.md 若与此修改冲突 → 先更新本文件再改配置
