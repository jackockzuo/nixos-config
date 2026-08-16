{ ... }:

{
  # ---- 6. mpv ----
  # 效果：Vulkan 渲染 + auto-safe 硬解
  xdg.configFile."mpv/config" = {
    force = true; # 覆盖原作者旧配置
    text = ''
      #使用vulkan后端
      gpu-api=vulkan
      #通用自动模式硬解
      hwdec=auto-safe
    '';
  };

}
