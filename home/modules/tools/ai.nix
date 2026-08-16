# ============================================================
# ai.nix —— 本地 AI（预留）
# 该放什么：Ollama / LM Studio / Chatbox 等本地模型工具
# 使用方式：home.packages = with pkgs; [ ollama ... ];
# ============================================================

{ pkgs, ... }:

{
  # opencode：终端内的 AI 编码代理（与 Claude Code 同类）
  home.packages = with pkgs; [
    opencode
  ];
}
