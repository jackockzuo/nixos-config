#!/usr/bin/env bash

# 10分钟锁屏，15分钟熄屏，30分钟休眠
# 锁屏 = Noctalia 内置锁屏（IPC 触发，PAM 认证走系统 login 服务），
# 睡眠前由 Noctalia 的 lock_before_suspend（logind PrepareForSleep）兜底上锁
exec swayidle -w \
timeout 600  'noctalia msg session lock' \
timeout 900  'niri msg action power-off-monitors' \
resume       'niri msg action power-on-monitors' \
timeout 1800 'systemctl suspend'
