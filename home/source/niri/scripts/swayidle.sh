#!/usr/bin/env bash

# 5分钟锁屏，10分钟熄屏，20分钟休眠
# hyprlock 配置由 programs.hyprlock 生成（~/.config/hypr/hyprlock.conf），
# 无 -c 时 hyprlock 自动读取标准路径
exec swayidle -w \
timeout 600  'hyprlock &' \
timeout 900  'niri msg action power-off-monitors' \
resume       'niri msg action power-on-monitors' \
timeout 1800 'systemctl suspend'
