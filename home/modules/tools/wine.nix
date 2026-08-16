{ ... }:

{
  # ============================================================
  # wine.nix —— Wine 程序管理函数（可选导入）
  # 用途：安装/卸载 Windows 程序（独立 prefix 零残留）
  # 导入方式：需要时在 flake.nix 的 toolsModules 列表加入 ./tools/wine.nix
  # ============================================================

  # Wine 程序安装（推荐独立 prefix，卸载零残留）
  # 用法: wine-install <安装程序路径> [prefix名]
  #   例: wine-install setup.exe              → 用默认 ~/.wine 安装
  #   例: wine-install setup.exe sgs           → 用独立 prefix ~/.wine-sgs 安装
  xdg.configFile."fish/functions/wine-install.fish".text = ''
    function wine-install
        set -l installer $argv[1]
        set -l prefix_name $argv[2]
        if test -z "$installer"
            echo "用法: wine-install <安装程序> [prefix名]"
            echo "  例: wine-install setup.exe          # 默认 ~/.wine"
            echo "  例: wine-install setup.exe sgs       # 独立 prefix ~/.wine-sgs"
            return 1
        end
        if not test -f "$installer"
            echo "❌ 找不到安装程序: $installer"
            return 1
        end
        if test -n "$prefix_name"
            set -l prefix_dir ~/.wine-$prefix_name
            if not test -d "$prefix_dir"
                echo "📦 创建独立 prefix: $prefix_dir"
                WINEPREFIX="$prefix_dir" wineboot -u
            end
            echo "🚀 正在用 prefix $prefix_dir 安装 $installer ..."
            WINEPREFIX="$prefix_dir" wine "$installer"
        else
            echo "🚀 正在用默认 prefix 安装 $installer ..."
            wine "$installer"
        end
        echo "✅ 安装完成。卸载时用: wine-uninstall $prefix_name"
    end
  '';
  # Wine 程序卸载（打开官方卸载器 + 清理快捷方式/空目录残留）
  # 用法: wine-uninstall [prefix名]
  #   例: wine-uninstall        → 打开默认 prefix 的卸载器
  #   例: wine-uninstall sgs    → 打开 ~/.wine-sgs 的卸载器，卸载后清理该 prefix 的入口
  xdg.configFile."fish/functions/wine-uninstall.fish".text = ''
    function wine-uninstall
        set -l prefix_name $argv[1]
        set -l prefix_dir ~/.wine
        if test -n "$prefix_name"
            set prefix_dir ~/.wine-$prefix_name
        end
        if not test -d "$prefix_dir"
            echo "❌ prefix 不存在: $prefix_dir"
            return 1
        end
        echo "🧹 打开 Wine 卸载器 ($prefix_dir) —— 在列表里选目标程序卸载..."
        WINEPREFIX="$prefix_dir" wine uninstaller
        echo "🧹 正在清理快捷方式残留..."
        # 删除该 prefix 对应的开始菜单入口（如果 wine 用的是默认菜单目录）
        set -l prog_dir ~/.local/share/applications/wine/Programs
        if test -d "$prog_dir"
            # 清理空目录残留（.desktop 已删但目录还在的）
            for d in $prog_dir/*
                if test -d "$d"
                    set -l has_entry (find "$d" -name '*.desktop' 2>/dev/null | count)
                    if test "$has_entry" -eq 0
                        rmdir "$d" 2>/dev/null; and echo "🗑️  移除空目录: $d"
                    end
                end
            end
        end
        # 若指定了独立 prefix 且用户确认，可整体删除 prefix
        if test -n "$prefix_name"
            echo ""
            echo "💡 如果想彻底删除整个 prefix (含程序本体+注册表):"
            echo "   rm -rf $prefix_dir"
            echo "   确认无误后可执行: wine-uninstall --purge $prefix_name"
        end
    end
    # 子命令: --purge 彻底删除独立 prefix
    function __wine_purge
        set -l prefix_name $argv[1]
        if test -z "$prefix_name"; or test "$prefix_name" = "--purge"
            echo "用法: wine-uninstall --purge <prefix名>"
            return 1
        end
        set -l prefix_dir ~/.wine-$prefix_name
        if not test -d "$prefix_dir"
            echo "❌ prefix 不存在: $prefix_dir"
            return 1
        end
        echo "⚠️  即将彻底删除 $prefix_dir (程序+注册表+一切)..."
        read -l -P '确认输入 yes 继续: ' confirm
        if test "$confirm" = "yes"
            rm -rf "$prefix_dir"
            echo "✅ 已彻底删除 $prefix_dir"
            # 清理该 prefix 残留的快捷方式
            set -l prog_dir ~/.local/share/applications/wine/Programs
            if test -d "$prog_dir"
                for d in $prog_dir/*
                    if test -d "$d"
                        set -l has_entry (find "$d" -name '*.desktop' 2>/dev/null | count)
                        if test "$has_entry" -eq 0
                            rmdir "$d" 2>/dev/null
                        end
                    end
                end
            end
        else
            echo "已取消"
        end
    end
    # 路由: --purge 子命令
    if test "$argv[1]" = "--purge"
        __wine_purge $argv[2]
    end
  '';
}
