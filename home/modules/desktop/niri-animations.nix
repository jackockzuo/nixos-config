# ============================================================
# niri-animations.nix —— 合成器动画（spring 弹簧动画族）
# 从 niri.nix 拆出：niri.nix 超「配置密集 ≤300 行」上限（STANDARDS §2.1）
# 仅修改动画时只动本文件
# ============================================================
_:

{
  wayland.windowManager.niri.settings.animations = {
    slowdown = 0.98114514; # <1 加快，>1 减慢
    "workspace-switch" = {
      spring = {
        _props = {
          "damping-ratio" = 0.82;
          stiffness = 400;
          epsilon = 0.0001;
        };
      };
    };
    "horizontal-view-movement" = {
      spring = {
        _props = {
          "damping-ratio" = 0.84;
          stiffness = 400;
          epsilon = 0.0001;
        };
      };
    };
    "window-open" = {
      spring = {
        _props = {
          "damping-ratio" = 1.0;
          stiffness = 1000;
          epsilon = 0.0001;
        };
      };
    };
    "window-close" = {
      spring = {
        _props = {
          "damping-ratio" = 0.8;
          stiffness = 400;
          epsilon = 0.0001;
        };
      };
    };
    "window-movement" = {
      spring = {
        _props = {
          "damping-ratio" = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };
      };
    };
    "window-resize" = {
      spring = {
        _props = {
          "damping-ratio" = 0.9;
          stiffness = 500;
          epsilon = 0.0001;
        };
      };
    };
    "screenshot-ui-open" = {
      "duration-ms" = 300;
      curve = "ease-out-quad";
    };
    "overview-open-close" = {
      spring = {
        _props = {
          "damping-ratio" = 1.0;
          stiffness = 900;
          epsilon = 0.0001;
        };
      };
    };
  };
}
