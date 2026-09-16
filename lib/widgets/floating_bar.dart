import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// 悬浮圆角白条（高保真稿 V2.6 定稿语言）。
///
/// 底部导航条、物品详情操作条、添加物品操作条**共用同一套几何**：
/// - 比内容卡**每侧宽出 6**（内容卡左右留白 20 → 条左右留白 14，用 [sideInset]）；
/// - 高 [height] 60 / 圆角 [radius] 20 / 距屏幕底部 [bottomGap] 8（再叠系统安全区）；
/// - 同一投影 `0 6px 16px rgba(150,90,70,.14)`；**无顶部分割线**；
/// - 条底是半透明白（导航条 .86 / 操作条 .92，见 `AppColors`）——**不用毛玻璃**。
///
/// 注意：页面若已被 `SafeArea` 包住（如 `BasePage`），这里的
/// `MediaQuery.padding.bottom` 已被消费为 0，底部只会留 [bottomGap]，这是对的。
class FloatingBar extends StatelessWidget {
  /// 内容卡左右留白 20 减 6 = 14 —— 条因此比卡片每侧宽出 6
  static const double sideInset = 14;

  /// 距屏幕底部的基础留白（V2.5 由 6 加到 8）
  static const double bottomGap = 8;

  static const double height = 60;
  static const double radius = 20;

  /// 操作条按钮高度（条内 60 里托 40 的胶囊）
  static const double buttonHeight = 40;

  static const EdgeInsets actionBarPadding = EdgeInsets.symmetric(
    horizontal: 8,
  );
  static const EdgeInsets navBarPadding = EdgeInsets.symmetric(horizontal: 4);

  final Widget child;

  /// 条底颜色：默认导航条的半透明白 .86
  final Color background;

  final EdgeInsetsGeometry padding;

  const FloatingBar({
    super.key,
    required this.child,
    this.background = AppColors.navBarBg,
    this.padding = actionBarPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: sideInset,
        right: sideInset,
        bottom: bottomGap + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: AppColors.barShadow,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// 悬浮操作条里的按钮语气档位。
enum FloatingBarTone {
  /// 主按钮：珊瑚实心 + 白字
  primary,

  /// 次要按钮：白底 + 极浅描边 + 深暖棕字
  ghost,

  /// 危险按钮：白底 + 极浅描边 + 警示红字（删除等不可逆动作）
  danger,
}

/// 悬浮操作条里的胶囊按钮（高 40 / 全圆角），与 [FloatingBar] 配套。
class FloatingBarButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final FloatingBarTone tone;

  const FloatingBarButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.tone = FloatingBarTone.ghost,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = tone == FloatingBarTone.primary;
    final Color contentColor;
    if (isPrimary) {
      contentColor = Colors.white;
    } else if (tone == FloatingBarTone.danger) {
      contentColor = AppColors.alertRed;
    } else {
      contentColor = AppColors.blushInk;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: FloatingBar.buttonHeight,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.coral : AppColors.cardBg,
          borderRadius: BorderRadius.circular(999),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.blushLine, width: 1.5),
          boxShadow: isPrimary
              ? const [
                  BoxShadow(
                    color: AppColors.btnPrimaryShadow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: contentColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: contentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
