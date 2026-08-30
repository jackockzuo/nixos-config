# 疑难杂症：OMEN 满载锁 2.5GHz（EC 功耗墙 ~25W）

- 日期：2026-08-23
- 状态：✅ 已解决
- 影响范围：全核满载时 CPU 频率被锁 ~2.5GHz（P）/ 2.2GHz（E），温度仅 68-74°C——明显"没吃到功耗"；单核睿频正常（5.09GHz）
- 涉及文件：
  - `modules/omencore.nix`（ec_sys 加载 + `omen-power-unlock` 服务直写 EC 0xBA=5 + `omen-fan-perms` 风扇权限）
  - `modules/nix.nix`（nix-ld.libraries 补 libice/libsm —— 前置事故：omercore-gui 起不来）
  - `packages/omencore/`（OmenCore 打包 + 滚动更新）
  - `flake.nix`（omercore 输入/overlay/packages/omencore-update）

---

## 症状

1. 32 线程满载：P 核均匀 2.5GHz、E 核 2.2GHz，TCPU 仅 67-74°C；
2. 单核可睿频 5.09GHz（CPU/供电/散热本身健康）；
3. RAPL `PL1=115W / PL2=157W` 可写、读回成功，但满载频率纹丝不动；
4. `platform_profile=performance`、EPP=performance、governor=performance——全部正确仍无效。

## 环境

- HP OMEN 16-wf0xxx（板号 8BAB），i9-13900HX + RTX 4060m，混合显卡
- NixOS 26.11 + cachyos 内核 7.1.8，桌面 niri（Wayland + XWayland）
- 已接入 OmenCore 4.1.7（omercore-cli/gui），`ec_sys`/`acpi_call` 内核模块

## 排查过程（时间线 + 关键证据）

### 1. 排除缩缸 / 热降频
- 满载仅 68-74°C，离 100°C 热墙很远 → 不是散热问题。

### 2. 排除 RAPL 锁
- `echo 115000000 > constraint_0_power_limit_uw` → 读回 115W（可写）。
- 🔴 但满载温度才 68°C → **实际功耗远低于 115W** → RAPL 寄存器是"纸面数字"，EC 实际供电被掐。

### 3. 排除 EPP / 调速器
- `energy_performance_preference` 全 `performance`、`scaling_governor=performance`、`no_turbo=0` → 都不是。

### 4. WMAA 假 PASS（关键弯路）
- 按 omenhub（omen-cli）字节布局经 `/proc/acpi/call` 写 `\_SB.WMID.WMAA 0x29`（EC 功耗限制 PL1/PL2）：
  返回含 `0x50 0x41 0x53`（PASS）→ 但**不生效**（PL2 写 157W 读回仍是 130W）。
- 内核日志佐证：`HP WMI ACPI WMAA/WHCM aborts`、`missing WQ00 query method` → **本机固件 WMI 通道降级，PASS 是假的**。

### 5. 找到正确通道：ec_sys 直写 EC 寄存器
- 读 OmenCore 源码 `src/OmenCore.Linux/Hardware/LinuxEcController.cs`：
  - `REG_THERMAL_POWER = 0xBA`（热功耗限制倍率 0-5，5=最高）
  - `REG_PERF_MODE = 0x95`（性能模式）
- 但本机 `ec_sys` 模块**未加载**（`/sys/kernel/debug/ec/ec0/io` 不存在）→ 这条路一直没通。

### 6. 实证解锁
```bash
sudo modprobe ec_sys write_support=1
sudo omencore-cli perf --mode performance --power-limit 5   # 写 EC 0xBA=5
```
- 读回 `/sys/kernel/debug/ec/ec0/io` offset 0xBA = `0x05` ✅
- 满载重测：**P 核 3.6GHz(瞬时) / 3.4GHz(稳态)，E 核 3.0/2.8GHz，96°C 稳态**——频率锁解除。

## 根因分析

| # | 问题 | 直接原因 | 深层原因 |
|---|---|---|---|
| 1 | 满载锁 2.5GHz | EC 实际只给 ~25W 功耗 | EC 热功耗限制寄存器 0xBA 默认在低档；RAPL 写 115W 被 EC 实际供电覆盖（温度即证据） |
| 2 | 之前一直解不开 | TLP 写不进、WMAA 假 PASS、ec_sys 未加载 | ① TLP 键名错误（`PL1_LIMIT_AC` ≠ 官方 `PL1_LIMIT_ON_AC`，从未生效）；② 固件 WMI 降级（WMAA aborts）；③ **正确通道 ec_sys 直写寄存器没开** |

## 修复方案（已固化）

| 文件 | 改动 | 说明 |
|---|---|---|
| `modules/omencore.nix` | `boot.kernelModules` 加 `ec_sys` + `extraModprobeConfig "options ec_sys write_support=1"` | 开启 EC 寄存器写通道 |
| `modules/omencore.nix` | `omen-power-unlock` 服务第 1 步：`dd` 直写 EC `0xBA=5`（随后 WMAA 尽力而为 + RAPL 115/157） | 开机自动解锁功耗墙 |
| `modules/omencore.nix` | `omen-hardware-perms` 服务：hp-wmi `pwm*` + `platform_profile` + EC `io` 开放给 wheel（0664） | GUI 普通用户可调风扇/性能模式/功耗限制 |
| `modules/nix.nix` | nix-ld.libraries 补 `libice`/`libsm` | omercore-gui 启动（Avalonia X11 后端） |

验证：`journalctl -u omen-power-unlock` 无失败；`dd if=/sys/kernel/debug/ec/ec0/io bs=1 skip=186 count=1` = `05`。

## 补充：max 风扇档（pwm_enable=0）本机不回退（2026-08-23 实测）

- OmenCore 的 `fan --speed 100` 提示「temporary boost，~1 分钟后回 BIOS 控制」是**通用说明**；
  本机板号 8BAB 固件实测**不会回退**——`pwm_enable=0` 会一直保持，直到显式改回。
- 改回自动档（普通用户可写，见 omen-hardware-perms）：
  ```bash
  echo 2 > /sys/devices/platform/hp-wmi/hwmon/hwmon6/pwm1_enable
  # 或 sudo omencore-cli fan --profile auto
  ```
- 空载别挂 max（63°C 空载 6000 转：吵 + 费风扇寿命）；持续高负载用性能档让 EC 按需控速。

## 经验教训（防再犯）

1. **温度是功耗的代理指标**：满载 68°C → 没吃到功耗（被 EC 掐）；满载 96°C → 才真正解锁。频率锁 + 低温 = 先怀疑功耗档，不是 CPU 坏/热降频。
2. **WMAA 返回 PASS ≠ 生效**：固件降级时假 PASS（内核日志 `WMAA/WHCM aborts`）。判断 WMI 是否真生效，看内核日志 + 读回值，别只看返回值。
3. **HP OMEN 的 EC 功耗/性能控制走 ec_sys 直写寄存器**（OmenCore LinuxEcController 的 0x95/0xBA），不是 RAPL/WMAA。0xBA=5 是本机实证有效的解锁。
4. **内核/驱动问题先确认模块加载**：`ls /proc/acpi/call`（acpi_call）、`ls /sys/kernel/debug/ec/ec0/io`（ec_sys）、`ls /sys/devices/platform/hp-wmi/`（hp-wmi 各接口）。
5. **TLP 的 RAPL 键名是 `PL1_LIMIT_ON_AC`**（不是 `PL1_LIMIT_AC`）——键名错了 TLP 静默不写，表现为"配置了但没效果"。

## 遗留事项（TODO）

- [ ] **0x95 性能模式寄存器**：🔴 2026-08-30 已实证有效（0x30=default→0x31=performance，写入后满载 2.16→2.44GHz），
  **但完整生效必须走 `omencore-cli perf` 的 platform_profile 后端**（3.44GHz，见 2026-08-30 事故档）；
  仅手动写 0x95/0xBA 两个寄存器只触发部分效果（固件性能模式是多寄存器协同序列）。
- [ ] **96°C 满载是解锁后的常态**：散热在 TjMax(100°C) 内且稳态不涨；想降温可把 `omen-power-unlock` 里的 0xBA 从 5 降到 3/4，或 RAPL PL1 从 115W 调低。
- [ ] **GPU 遥测 unavailable**：混合显卡 dGPU 休眠时无 hwmon 温度源（`nvidia-smi` 可用，49°C），非缺陷。
