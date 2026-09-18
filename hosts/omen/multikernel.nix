# ============================================================
# multikernel.nix —— Limine 菜单多内核切换（2026-09 启用）
# 机制：boot.specialisation → Limine 把当前 generation 生成子菜单
#       [Default(zen) / latest / lts]，开机进子菜单选内核即可。
# nvidia 跟随 boot.kernelPackages（hardware.nix 用 config.boot.kernelPackages.nvidiaPackages.latest），
#   故 specialisation 只切内核即可，无需再写 nvidia 覆盖。
# ⚠️ 备胎内核 + 对应 nvidia 模块首次启用需联网构建；切回 zen = 子菜单选 Default。
# ============================================================
{ pkgs, ... }:

{
  specialisation = {
    # 主线最新内核（尝鲜）
    latest.configuration = {
      boot.kernelPackages = pkgs.linuxPackages_latest;
    };

    # 6.12 LTS（稳定兜底）
    lts.configuration = {
      boot.kernelPackages = pkgs.linuxPackages_6_12;
    };
  };
}
