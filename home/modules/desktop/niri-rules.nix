# ============================================================
# niri-rules.nix —— 窗口/图层规则 + 输出 + 毛玻璃（原 rule.kdl/output.kdl/blur.kdl）
# 顺序说明：_children 保序渲染；window-rule 顺序与原 include 顺序一致
# （rule.kdl 规则在前，blur.kdl 规则在后——后规则对同窗口可覆盖前规则属性）
# ============================================================
_:

{
  wayland.windowManager.niri.settings = {
    # ---- 毛玻璃全局参数（blur.kdl 顶层块）----
    # 现代参数（niri 26.04 默认 passes 3/offset 3，此处调轻：passes 2 省 GPU，
    # offset 3.0 平滑，noise 0.02 抗色带，saturation 1.4 低饱和更雅）
    blur = {
      passes = 2;
      offset = 3.0;
      noise = 0.02;
      saturation = 1.4;
    };

    _children = [
      # ================ 输出（原 output.kdl）================
      # eDP-1（笔记本内屏）：关闭（外接 HDMI 为主屏）
      {
        output = {
          _args = [ "eDP-1" ];
          off = { };
        };
      }
      # HDMI-A-1（主显示器）
      {
        output = {
          _args = [ "HDMI-A-1" ];
          mode = "1920x1080@144";
          scale = 1;
          position = {
            _props = {
              x = 0;
              y = 0;
            };
          };
          "focus-at-startup" = { };
        };
      }

      # ================ 图层规则（原 rule.kdl）================
      # 放进 overview 的壁纸程序（DMS 壁纸层，Quickshell namespace = quickshell）
      {
        "layer-rule" = {
          _children = [
            {
              match = {
                _props = {
                  namespace = "awww-daemonoverview";
                };
              };
            }
            {
              match = {
                _props = {
                  namespace = "swww-daemonoverview";
                };
              };
            }
            {
              match = {
                _props = {
                  namespace = "^quickshell$";
                };
              };
            }
          ];
          "place-within-backdrop" = true;
        };
      }

      # ================ 窗口规则（原 rule.kdl）================
      # 全局：禁止边框画到背景里
      {
        "window-rule" = {
          "draw-border-with-background" = false;
        };
      }
      # 浮动窗口最小尺寸（niri-siderbar 等需要）
      {
        "window-rule" = {
          match = {
            _props = {
              "is-floating" = true;
            };
          };
          "min-width" = 100;
          "min-height" = 100;
        };
      }
      # imv 图片预览：浮动打开且不自动聚焦
      {
        "window-rule" = {
          match = {
            _props = {
              "app-id" = "imv";
            };
          };
          "open-focused" = false;
          "open-floating" = true;
        };
      }
      # shorinclip / cliphist-tui 剪贴板 TUI
      {
        "window-rule" = {
          _children = [
            {
              match = {
                _props = {
                  "app-id" = "shorinclip";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "cliphist-tui";
                };
              };
            }
          ];
          "default-column-width" = {
            fixed = 625;
          };
          "default-window-height" = {
            fixed = 700;
          };
          "open-floating" = true;
          "default-floating-position" = {
            _props = {
              x = 0;
              y = 18;
              "relative-to" = "top";
            };
          };
        };
      }
      # 常见浮动软件清单（app-id 正则同时匹配 host/Flatpak 两套 id）
      {
        "window-rule" = {
          _children = [
            {
              match = {
                _props = {
                  "app-id" = "com.gabm.satty";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "media_info";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "video2gif";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "floating-term";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "nm-connection-editor";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "niri-quick-switch";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "firefox$";
                  title = "^Picture-in-Picture$";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "steam";
                  title = "Friends List";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "blueberry.py";
                  title = "蓝牙";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "blueman-manager";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "flameshot";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "com.github.hluk.copyq";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "be.alexandervanhee.gradia";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "org.pulseaudio.pavucontrol";
                  title = "音量控制";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "org.gnome.clocks";
                  title = "时钟";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "fcitx";
                  title = "Fcitx5 Input Window";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "org.gnome.FileRoller";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "waypaper";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "clipse-gui";
                };
              };
            }
            {
              match = {
                _props = {
                  title = "群聊的聊天记录";
                };
              };
            }
            {
              match = {
                _props = {
                  title = "聊天记录";
                };
              };
            }
            {
              match = {
                _props = {
                  title = "群相册";
                };
              };
            }
            {
              match = {
                _props = {
                  title = "日历";
                };
              };
            }
            {
              match = {
                _props = {
                  title = "重命名";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "btrfs-assistant";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "markpix";
                };
              };
            }
            {
              match = {
                _props = {
                  title = "Steam 设置";
                };
              };
            }
            {
              match = {
                _props = {
                  title = "另存为";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "better_control.py";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "floating-mpv";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "niri-hotkey-menu";
                };
              };
            }
          ];
          "open-floating" = true;
        };
      }
      # QQ 资料卡/天气：不自动聚焦
      {
        "window-rule" = {
          _children = [
            {
              match = {
                _props = {
                  "app-id" = "QQ";
                  title = "资料卡";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "QQ";
                  title = "天气";
                };
              };
            }
          ];
          "open-focused" = false;
        };
      }
      # waybar 命令中心模块
      {
        "window-rule" = {
          match = {
            _props = {
              "app-id" = "command-center";
            };
          };
          "default-column-width" = {
            fixed = 1000;
          };
          "default-window-height" = {
            fixed = 600;
          };
          "open-floating" = true;
        };
      }
      # 快速终端和笔记
      {
        "window-rule" = {
          _children = [
            {
              match = {
                _props = {
                  "app-id" = "notebook";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "quickterminal";
                };
              };
            }
          ];
          "open-floating" = true;
          "default-floating-position" = {
            _props = {
              x = 20;
              y = 20;
              "relative-to" = "top";
            };
          };
        };
      }
      # bluetui / impala
      {
        "window-rule" = {
          _children = [
            {
              match = {
                _props = {
                  "app-id" = "bluetui";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "impala";
                };
              };
            }
          ];
          "default-column-width" = {
            fixed = 800;
          };
          "default-window-height" = {
            fixed = 800;
          };
          "open-floating" = true;
        };
      }
      # clipse
      {
        "window-rule" = {
          match = {
            _props = {
              "app-id" = "clipse";
            };
          };
          "default-column-width" = {
            fixed = 625;
          };
          "default-window-height" = {
            fixed = 700;
          };
          "open-floating" = true;
        };
      }
      # waydroid 安卓模拟器：全屏浮动、无焦点环无阴影
      {
        "window-rule" = {
          _children = [
            {
              match = {
                _props = {
                  title = "gsr ui";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "waydroid";
                };
              };
            }
          ];
          "open-fullscreen" = true;
          "open-floating" = true;
          "focus-ring" = {
            off = { };
          };
          shadow = {
            off = { };
          };
        };
      }
      # 图片/视频查看类窗口：不透明 + 浮动
      {
        "window-rule" = {
          _children = [
            {
              match = {
                _props = {
                  title = "图片查看器";
                };
              };
            }
            {
              match = {
                _props = {
                  title = "画中画";
                };
              };
            }
            {
              match = {
                _props = {
                  title = "图片和视频";
                };
              };
            }
            {
              match = {
                _props = {
                  title = "视频播放器";
                };
              };
            }
          ];
          "open-floating" = true;
          opacity = 1.0;
        };
      }
      # mpv / celluloid：不透明（播放器保持实色）
      {
        "window-rule" = {
          _children = [
            {
              match = {
                _props = {
                  "app-id" = "mpv";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "celluloid";
                };
              };
            }
          ];
          opacity = 1.0;
        };
      }
      # wezterm：让窗口自己决定初始宽度（留空 = 空块）
      {
        "window-rule" = {
          match = {
            _props = {
              "app-id" = "^org\\.wezfurlong\\.wezterm$";
            };
          };
          "default-column-width" = { };
        };
      }
      # 密码管理器 + 微信：从屏幕捕获/录屏中屏蔽
      {
        "window-rule" = {
          _children = [
            {
              match = {
                _props = {
                  "app-id" = "^org\\.keepassxc\\.KeePassXC$";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "^org\\.gnome\\.World\\.Secrets$";
                };
              };
            }
            {
              match = {
                _props = {
                  "app-id" = "wechat";
                };
              };
            }
          ];
          "block-out-from" = "screen-capture";
        };
      }
      # steam 好友弹窗修复：右下角 + 不聚焦
      {
        "window-rule" = {
          match = {
            _props = {
              "app-id" = "steam";
              title = "^notificationtoasts_\\d+_desktop$";
            };
          };
          "default-floating-position" = {
            _props = {
              x = 10;
              y = 10;
              "relative-to" = "bottom-right";
            };
          };
          "open-focused" = false;
        };
      }

      # ================ 毛玻璃窗口规则（原 blur.kdl）================
      # 全局毛玻璃：所有窗口半透明 + 圆角 + 背景模糊
      # xray 不写 = 默认开启：仅模糊一次壁纸背景供所有窗口复用，零额外消耗
      {
        "window-rule" = {
          opacity = 0.94;
          "geometry-corner-radius" = 12;
          "clip-to-geometry" = true;
          "background-effect" = {
            blur = true;
          };
        };
      }
      # kitty 专属：毛玻璃终端（透明度单一来源 = kitty 内部 background_opacity）
      # 🔴 opacity 1.0：禁止 niri 侧再降透明度，避免与 kitty background_opacity 双重乘算；
      #    draw-border-with-background false：防止焦点环实心矩形透过半透明窗口
      {
        "window-rule" = {
          match = {
            _props = {
              "app-id" = "kitty";
            };
          };
          opacity = 1.0;
          "geometry-corner-radius" = 12;
          "clip-to-geometry" = true;
          "draw-border-with-background" = false;
          "background-effect" = {
            blur = true;
            xray = false;
          };
        };
      }
      # 浮动窗口：更透 + 实时模糊（xray=false 模糊底下所有窗口内容）
      # 注：xray=false 为实验性功能，拖动/开合动画时效果短暂消失、更耗性能
      {
        "window-rule" = {
          match = {
            _props = {
              "is-floating" = true;
            };
          };
          opacity = 0.9;
          "background-effect" = {
            xray = false;
            blur = true;
          };
        };
      }
      # waydroid：完全不透明（避免界面透过）
      {
        "window-rule" = {
          match = {
            _props = {
              "app-id" = "waydroid";
            };
          };
          opacity = 1.0;
        };
      }
    ];
  };
}
