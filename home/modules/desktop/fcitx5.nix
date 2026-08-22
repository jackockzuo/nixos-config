# ============================================================
# fcitx5.nix —— 输入法用户级配置（fcitx5 + rime 雾凇）
# 系统层（modules/locale.nix）已负责：
#   - i18n.inputMethod.enable/type = fcitx5（含 rime-ice addons 与 override）
#   - QT/XMODIFIERS 等 IM 环境变量（单一来源，见 STANDARDS §4）
# 本模块只写用户级配置（~/.config/fcitx5、~/.local/share/fcitx5/rime）
# ============================================================
_:

{
  xdg = {
    configFile = {
      # 1. 彻底禁用云拼音（雾凇词库已足够，零延迟）
      "fcitx5/conf/cloudpinyin.conf".text = ''
        Enable=False
        Toggle Key=
        Minimum Pinyin Length=2
        Backend=Baidu
      '';

      # 2. 外观：Catppuccin 紫色主题 + Noto Sans CJK SC 字体 + 横排候选框
      #（候选框是 UI 组件，用系统默认中文字体；Maple Mono 仅终端使用）
      # force=true：防止 fcitx5 运行时重写 classicui.conf 覆盖主题（与下方 config 同理）
      "fcitx5/conf/classicui.conf" = {
        force = true;
        text = ''
          Vertical Candidate List=False
          Font="Noto Sans CJK SC 11"
          MenuFont="Noto Sans CJK SC 10"
          Theme=catppuccin-mocha-mauve
          DarkTheme=catppuccin-mocha-mauve
          UseDarkTheme=True
          PerScreenDPI=True
        '';
      };

      # 2b. GTK IM 模块按后端拆分（现代写法，fcitx wiki 2025-09 + STANDARDS §4）：
      # Wayland 原生 GTK3/4 → 合成器 text-input-v3（niri 支持）→ classicui 浮窗主题生效；
      # 因此 gtk3/gtk4 settings.ini **不再写** gtk-im-module（写了会退回应用内嵌候选框=“原皮”，
      # 2026-08-21 实测根因）。XWayland GTK3 走 GTK 内建 XIM（XMODIFIERS 全局已设）；
      # GTK2（仅 X11）保留 gtk-im-module=fcitx。详见 appearance.nix 的 gtk 段注释。

      # 4. 默认输入法 Profile：开机默认加载美式键盘 + Rime 雾凇拼音
      "fcitx5/profile".text = ''
        [Groups/0]
        Name=Default
        Default Layout=us
        DefaultIM=rime

        [Groups/0/Items/0]
        Name=keyboard-us
        Layout=

        [Groups/0/Items/1]
        Name=rime
        Layout=

        [GroupOrder]
        0=Default
      '';

      # 5. 输入法全局快捷键（Ctrl+Space 切换；Super+Space 让给启动器 DMS Spotlight）
      "fcitx5/config" = {
        force = true; # 覆盖 fcitx5 生成的现有配置
        text = ''
          [Hotkey]
          # 按住切换键的修饰键时进行轮换切换
          EnumerateWithTriggerKeys=True
          # 向前切换输入法
          EnumerateForwardKeys=
          # 向后切换输入法
          EnumerateBackwardKeys=
          # 轮换输入法时跳过第一个输入法
          EnumerateSkipFirst=False
          # 触发修饰键快捷键的时限 (毫秒)
          ModifierOnlyKeyTimeout=250

          [Hotkey/TriggerKeys]
          0=Ctrl+space
          1=Shift+space
          2=Zenkaku_Hankaku
          3=Hangul

          [Hotkey/ActivateKeys]
          0=Hangul_Hanja

          [Hotkey/DeactivateKeys]
          0=Hangul_Romaja

          [Hotkey/AltTriggerKeys]
          0=Shift_L

          [Hotkey/EnumerateGroupForwardKeys]
          0=Ctrl+space
          1=Shift+space

          [Hotkey/EnumerateGroupBackwardKeys]
          0=Shift+Ctrl+space

          [Hotkey/PrevPage]
          0=Up

          [Hotkey/NextPage]
          0=Down

          [Hotkey/PrevCandidate]
          0=Shift+Tab

          [Hotkey/NextCandidate]
          0=Tab

          [Hotkey/TogglePreedit]
          0=Control+Alt+P

          [Behavior]
          # 默认激活：打开即中文；需要输命令时按 Ctrl+Space 切回英文
          ActiveByDefault=True
          # 重新聚焦时重置状态
          resetStateWhenFocusIn=No
          # 共享输入状态
          ShareInputState=No
          # 在程序中显示预编辑文本
          PreeditEnabledByDefault=True
          # 切换输入法时显示输入法信息
          ShowInputMethodInformation=True
          # 在焦点更改时显示输入法信息
          showInputMethodInformationWhenFocusIn=False
          # 显示紧凑的输入法信息
          CompactInputMethodInformation=True
          # 显示第一个输入法的信息
          ShowFirstInputMethodInformation=True
          # 默认页大小
          DefaultPageSize=5
          # 覆盖 XKB 选项
          OverrideXkbOption=False
          # 自定义 XKB 选项
          CustomXkbOption=
          # Force Enabled Addons
          EnabledAddons=
          # Force Disabled Addons
          DisabledAddons=
          # Preload input method to be used by default
          PreloadInputMethod=True
          # 允许在密码框中使用输入法
          AllowInputMethodForPassword=False
          # 输入密码时显示预编辑文本
          ShowPreeditForPassword=False
          # 保存用户数据的时间间隔（以分钟为单位）
          AutoSavePeriod=30

        '';
      };
    };
    dataFile = {
      # 3. 声明式配置 Rime 引擎：强制使用"雾凇拼音" (rime_ice) 词库方案
      # 注意：rime-ice 数据由系统层 fcitx5-rime override 提供（共享数据目录），
      # 用户目录只需保留 .custom.yaml 打补丁，不要塞词库文件（会被 rime SyncUserData 清理）。
      "fcitx5/rime/default.custom.yaml".text = ''
        patch:
          "schema_list":
            - schema: rime_ice
      '';
      # 3b. 雾凇自定义（禁用 llm_translator：脚本缺失导致 rime 报错提示）
      "fcitx5/rime/rime_ice.custom.yaml".text = ''
        patch:

          # 1. 扩充允许输入的字符集：允许在拼音中直接输入指定的标点符号，阻止其直接上屏
          "speller/alphabet": "zyxwvutsrqponmlkjihgfedcba.,?'!:<>\\/"

          # llm_translator（AI 翻译）已禁用：脚本缺失导致 rime 报错
          # "engine/translators/@before 0": lua_translator@llm_translator
          # "recognizer/patterns/llm_pinyin": "^[a-z][a-z.,?'!:<>/\\\\]*$"

          # grammar 数据库缺失（wanxiang-lts-zh-hans.gram 不存在），禁用避免报错
          # "grammar/language": wanxiang-lts-zh-hans
      '';
      # 3c. rime.lua（llm_translator 已禁用）
      "fcitx5/rime/rime.lua".text = ''
        -- llm_translator = require("llm_translator")  -- 已禁用（脚本缺失）
      '';
    };
  };
}
