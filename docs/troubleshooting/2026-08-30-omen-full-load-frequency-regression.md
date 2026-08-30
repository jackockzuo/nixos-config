# 疑难杂症：满载锁 2.16GHz（8-25 后性能回归）

- 日期：2026-08-30
- 状态：✅ 已解决
- 影响范围：32 核满载仅 ~2.16GHz（8-23 解锁后曾达 3.44GHz），温度 <70°C（功耗没吃满）
- 涉及文件：`modules/omencore.nix`（omen-power-unlock 服务）
- 关联：[2026-08-23-omen-ec-power-limit-2.5ghz-lock.md](./2026-08-23-omen-ec-power-limit-2.5ghz-lock.md)、[2026-08-25-coil-whine-cpu-governor.md](./2026-08-25-coil-whine-cpu-governor.md)

---

## 症状

1. 32 核满载（`yes >/dev/null` ×32）：平均频率 **2.16GHz**（上限 5.2GHz）；
2. 满载温度仅 **63-71°C**——对比 8-23 解锁后的 96°C，明显"没吃到功耗"（温度 = 功耗的代理指标）；
3. `platform_profile=performance`、`0xBA=05`（读回确认）、RAPL=115W（读回确认）——**全部"看起来正确"但仍低频**。

## 排查过程（时间线 + 关键证据）

### 1. 排除常规嫌疑（全部不是根因）
| 排查项 | 结果 | 结论 |
|---|---|---|
| EC 0xBA=5 | 读回 `05` ✅ | 已解锁 |
| RAPL PL1 | 手动写 115W 读回成功 ✅ | 通道可用 |
| platform_profile | `performance` ✅ | 已最高 |
| AC 供电 | `AC/online=1` ✅ | 插电 |
| 热降频 | 满载 63-71°C | 排除 |
| governor/EPP（8-25 改的） | A/B 切 performance → 满载仅 2.54GHz | **不是主因** |

### 2. 关键发现：EC 0x95 性能模式寄存器
读 OmenCore 源码 `LinuxEcController.cs`：
```csharp
REG_PERF_MODE = 0x95;             // Performance mode
PERF_MODE_PERFORMANCE = 0x31;     // ← performance 模式
```
- 本机 0x95 读回 `0x43`（非默认 0x30、非 performance 0x31）；
- 手动写 `0x95=0x31` + `0xBA=5` → 满载 **2.44GHz**（有改善但**不完整**）。

### 3. 决定性验证：重跑 8-23 原始命令
```bash
sudo omencore-cli perf --mode performance --power-limit 5
```
- 输出：`Backend: ACPI platform_profile`；
- 满载重测：**3.44GHz / 84°C** ✅——与 8-23 事故档的 3.4GHz/96°C 完全吻合。

## 根因分析

| # | 问题 | 直接原因 | 深层原因 |
|---|---|---|---|
| 1 | 手动 EC 写入不完整 | 只写了 0x95/0xBA 两个寄存器 | HP 固件的性能模式是**多寄存器协同序列**（功耗档/供电策略/风扇曲线…），platform_profile=performance 触发固件一次性应用完整序列；手动写两个寄存器只触发部分 |
| 2 | 为什么开机脚本"看起来对"却失效 | omen-power-unlock 只做 EC 直写（0xBA），从未走 platform_profile 完整序列 | 8-23 手动 omencore-cli 命令有效，但固化到服务时只固化了 EC 直写部分，遗漏了 platform_profile 完整调用 |
| 3 | daemon hold 为何没救 | omencore daemon 在跑（Hold Enabled: yes）但 hold 重新应用的是"轻量"配置 | daemon 的 hold 周期重写 platform_profile，但**一次完整 omencore-cli perf 调用**才是固件完整应用的关键 |

**温度佐证**（贯穿全程）：64°C → 84°C 的提升 = 功耗从 ~60W → ~115W，只有 platform_profile 完整序列才让 EC 真正放行供电。

## 修复方案（已固化）

`modules/omencore.nix` 的 `omen-power-unlock` 服务——**最终架构（2026-08-30 零裸 hex 写）**：

```bash
# 唯一操作：OmenCore 官方接口（内部封装 hp-wmi platform_profile + EC 0x95/0xBA + 读回验证）
omencore-cli perf --mode performance --power-limit 5
# 随后只读确认 platform_profile=performance + EC 0xBA=5（仅日志，无副作用）
```

**删除项及理由**（安全性优先，不直接写 EC 寄存器）：
- 手动 `dd` 写 0xBA → omencore `power-limit 5` 已封装（含验证）；
- WMAA 0x29 → 固件假 PASS（8-23 事故档），无实际作用；
- 手动 RAPL 写入 → 实测破坏 platform_profile 性能状态（3.44→2.45GHz），固件自行管理（强制 130W）；
- performance.nix 的 TLP PL1/PL2 配置 → 固件覆盖（写 115W 读回 130W），已删（避免误导）。

验证：`journalctl -u omen-power-unlock` 应有 `OK: Performance mode set to: performance` 且无失败；
满载测试：`for i in (seq 32); yes >/dev/null &; end; sleep 6; awk -F: '/MHz/{s+=$2; n++} END{print s/n}' /proc/cpuinfo` 应 ≥3.4GHz。

## 经验教训（防再犯）

1. **"寄存器看起来对" ≠ 完整生效**：EC 0xBA=05 读回正确、platform_profile=performance、RAPL=115W 全部正确，但满载只有 2.16GHz——**唯一可靠判据是满载频率 + 温度**（温度是功耗的代理指标）。
2. **厂商固件的性能模式是完整序列**：HP platform_profile=performance 不是写一个寄存器，是固件内部的多寄存器协同。**优先用官方工具（omencore-cli）触发，手动 EC 直写只做补充**。
3. **A/B 定位顺序**：先怀疑 8-25 引入的改动（governor/EPP）→ 实测排除 → 再回到 EC 层（0x95）→ 最后发现 platform_profile 完整调用。数据说话，不猜。
4. **服务固化要完整**：8-23 手动命令有效，但固化到开机服务时遗漏了 platform_profile 环节——固化的必须是**验证过的完整命令**，不能只取片段。
5. **🔴 不要手动写 RAPL**（2026-08-30 实证）：手动 echo PL 会**破坏 platform_profile 性能状态**（满载 3.44→2.45GHz，温度下降=功耗被掐）；改完必须重跑 `omencore-cli perf` 重新应用。且固件 performance 模式强制 PL1=130W（写 115W 被覆盖回 130W）——配置里的 115W 是纸面值，真实功耗墙由固件 platform_profile 决定。

## 进一步解锁的边界（2026-08-30 实测）

| PL1 | 满载 | 温度 | 结论 |
|---|---|---|---|
| 固件 130W（performance 模式）| **3.44 GHz** | **84°C** | ✅ 当前最佳点 |
| 手动 135W | 3.42 GHz | 92°C | ❌ 不增频只增温（E 核已到顶，P 核受频率曲线限制）|

**结论**：3.4GHz/84°C 已是这台 13900HX（8BAB 板 + 原装散热）的满载合理上限。
想再进一步只有硬件层（液金/更强风扇曲线/BIOS 解锁），或接受 92°C 换 0.02GHz（无意义）。
单核睿频 5.2GHz 已正常（8-23 事故档验证过 5.09GHz）。

## 遗留事项（TODO）

- [ ] **重启持久性验证**：rebuild + reboot 后确认满载仍 ≥3.4GHz（omen-power-unlock 服务开机自动跑 omencore-cli perf）。
- [ ] **daemon hold 与服务的交互**：omencore daemon 的 hold 周期重写是否覆盖/干扰 omen-power-unlock 的完整调用——观察一段时间，若重启后仍正常则无冲突。
- [ ] **0x95 寄存器语义**：读回 `0x43` 未知值，写入 0x31 有部分效果——本板 8BAB 的 0x95 完整取值域未穷举（0x43 可能是 balanced 或自定义档）。
