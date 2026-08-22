# ============================================================
# ai.nix —— 本地 AI 工具
# 该放什么：本地模型平台（Ollama / LM Studio / Chatbox）+ 终端 AI 代理
# 使用方式：home.packages = with pkgs; [ opencode pi-coding-agent ... ];
# ============================================================

{ pkgs, ... }:

{
  # 终端内的 AI 编码代理
  home.packages = with pkgs; [
    opencode
    pi-coding-agent # 🔴 自打包（packages/pi/package.nix，经 flake overlay 提供；pi 命令）
  ];
}
