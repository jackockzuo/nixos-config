# 疑难杂症：登录桌面后持续"嗞嗞"线圈啸叫（CPU VRM 高频开关声）

- 日期：2026-08-25
- 状态：✅ 已解决
- 影响范围：开机登录进入桌面（niri + DMS）后持续发出"嗞嗞"声；Windows 下无此声音
- 涉及文件：
  - `modules/performance.nix`（TLP：`CPU_SCALING_GOVERNOR_ON_AC` / `CPU_ENERGY_PERF_POLICY_ON_AC`）

---

## 症状

1. 开机 → 登录进入桌面后开始持续"嗞嗞"声（尖锐线圈啸叫，非风扇"嗡嗡"）；
2. Windows 双系统下同样使用无此声音；
3. 登录界面（greeter）与桌面同为 niri 渲染，但声音在进入桌面会话后出现。

## 环境

- HP OMEN 16-wf0xxx（板号 8BAB），i9-13900HX + RTX 4060m
- NixOS 26.11 + cachyos 内核，桌面 niri（Wayland）+ DMS（quickshell）
- 🔴 **MUX 独显直连**：DRM 树只有 `card1`（NVIDIA 0x10de），无 i915/card0；内屏 eDP-1 与外接 HDMI 全部挂 RTX 4060
- 外接 25" 显示器 1920x1080@144Hz（HDMI-A-1），由独显呈现（nvidia-modeset 中断 ~150 次/秒）
- TLP：AC = `performance` governor + EPP=performance；PL1=115W / PL2=157W（EC 0xBA=5 解锁，见 2026-08-23 事故档）

## 排查过程（时间线 + 关键证据）

### 1. 排除 GPU 渲染负载（独显 VRM 啸叫）
- `nvidia-smi`：空闲 SM 210MHz / 2W / 1% util / P8 —— 桌面并未持续渲染，GPU 侧负载不成立；
- 内存时钟 405↔810MHz 摆动（`finegrained` 精细电源管理所致），但真空闲时稳定在 405MHz，无高频跳变。

### 2. 排除风扇
- hwmon6（hp）：fan1/fan2 = 0 RPM、pwm1=0、pwm1_enable=2（自动）；
- 全部 `cooling_device*` Fan state = 0/1 → 风扇未转，排除风扇轴承/共振声。

### 3. 排除显示器
- 外接屏为 144Hz HDMI 直连独显——此呈现路径持续存在（中断 ~150/s），但 GPU 侧无负载证据，暂不归因。

### 4. A/B 定位 CPU（决定性证据）
```bash
# 临时把 CPU 调速器切到 powersave（允许空闲降到 800MHz）
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```
- **声音立即消失** → 根因锁定在 CPU 频率策略。
- 改前状态：`scaling_governor=performance` + `energy_performance_preference=performance`，
  `cpuinfo_max_freq=5.2GHz` / `min=800MHz`，实测活跃核心 2.0GHz+（轻负载即顶高频）。

## 根因分析

| # | 问题 | 直接原因 | 深层原因 |
|---|---|---|---|
| 1 | 桌面会话持续"嗞嗞"声 | CPU VRM（供电电感）持续高频开关振动 | intel_pstate 的 `performance` governor 把活跃核心锁在最高 P-state（min=max），轻负载也保持 3~5GHz → 电感开关频率高、电流纹波大 → 线圈啸叫 |
| 2 | Windows 下无声 | Windows 电源计划默认动态调频（等效 powersave），空闲即降频 | 本机 Linux 侧 TLP 为性能计算显式配置了 `performance` governor，属主动选择 → 无日志无报错，只能靠 A/B 定位 |
| 3 | 为什么没先怀疑 CPU | 有独显直连 + 144Hz 外接屏的"嫌疑"在 | 想当然归因 GPU，实测 GPU 空闲（210MHz/2W）后才转向 CPU —— 教训见下 |

## 修复方案（已固化）

`modules/performance.nix`（TLP settings）：

| 改动 | 说明 |
|---|---|
| `CPU_SCALING_GOVERNOR_ON_AC`：`"performance"` → `"powersave"` | 实证有效的修复：允许空闲降到 800MHz；名字有迷惑性——intel_pstate 下 powersave 才是"动态调频"，负载时 HWP 仍睿频到 5.2GHz，**不是限频** |
| 新增 `CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance"` | TLP 默认 EPP=performance，与 powersave 搭配时轻负载仍倾向顶高频（残留啸叫风险）；balance_performance 让轻负载降频、重负载拉满 |

- **性能无损失**：PL1=115W/PL2=157W 解锁、scx_lavd、irqbalance 均不变；HWP 重载照样全核睿频；
- **唯一取舍**：空闲 CPU 遇突发任务的 HWP 升频 ramp 延迟（毫秒级，日常无感；微秒级延迟敏感场景可把 EPP 改回 performance）。
- 应用：`sudo nixos-rebuild switch --flake .#omen` → `sudo systemctl restart tlp`（AC 事件/开机时 TLP 自动重刷，手动 echo 会被覆盖，故必须写进配置）。
- 验证：`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` = `powersave`；`energy_performance_preference` = `balance_performance`；声音消失。

## 经验教训（防再犯）

1. **笔记本"嗞嗞"线圈声先定位声源再修**：CPU VRM（`scaling_governor`/`scaling_cur_freq`）、GPU VRM（`nvidia-smi` 时钟/功率）、风扇（hwmon fan RPM）、显示器——风扇看 hwmon、GPU 看 nvidia-smi、CPU 看 cpufreq，各有独立证据链。
2. **`performance` governor 是常见啸叫源**：intel_pstate 下它锁最高频（min=max），`powersave` 才是动态。名字有迷惑性，别被"performance=性能"误导。
3. **A/B 定位最快**：`echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor` 一条命令即可判别 CPU 侧，无需重启、无需改配置。
4. **不要想当然归因 GPU**：独显直连 + 144Hz 外接屏呈现路径确实持续存在（中断 ~150/s），但实测 GPU 空闲（210MHz/2W）时不是啸叫主因——用数据说话。

## 遗留事项（TODO）

- [ ] **GPU 侧线圈声风险仍在**：独显直连 + 144Hz 外接屏属于"呈现持续活跃"环境。若未来出现 GPU 侧啸叫，优先排查 `powerManagement.finegrained` 的显存时钟摆动（405↔810MHz）、降刷新率（120/60Hz）或换 DP 线开 VRR。
- [ ] 若后续重度使用觉得响应"发肉"（一般不会），可把 `CPU_ENERGY_PERF_POLICY_ON_AC` 改回 `"performance"`，governor 保持 powersave 即可兼顾安静与激进。
