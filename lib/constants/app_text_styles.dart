import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 统一文本样式。
///
/// ⚠️ 引用 [AppColors] 动态令牌的样式**不能是 const**（颜色要随皮肤在运行时
/// 变化），所以这些是 getter；只有纯字号/字重（不含颜色）的才保留 const。
/// 调用处若写了 `const Text(style: AppTextStyles.xxx)` 需要去掉 const。
class AppTextStyles {
  AppTextStyles._();

  // ── 标题样式 ──
  static TextStyle get titleLarge => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleSmall => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get overlayTitle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );

  // ── 正文样式 ──
  static TextStyle get bodyLarge => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // ── 标签样式 ──
  static TextStyle get labelLarge => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelMedium => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
  );

  static TextStyle get labelSmall => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  // ── 特殊样式 ──

  static TextStyle get priceText => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.coralDeep,
  );

  static TextStyle get subtitleText => TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static TextStyle get sectionTitle => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get seeAllText => TextStyle(
    fontSize: 13,
    color: AppColors.btnTextFg,
    fontWeight: FontWeight.w600,
  );

  // ── Splash 专用 ──
  static TextStyle get splashTitle => TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: 6,
  );

  static TextStyle get splashSubtitle => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 3,
  );

  // ── 按钮 ──
  static const buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // ── 带颜色的变体 ──
  static TextStyle colored({
    required Color color,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle tag({Color? color, double fontSize = 11}) {
    return TextStyle(
      fontSize: fontSize,
      color: color ?? AppColors.textSecondary,
    );
  }

  static TextStyle statCount({required Color color}) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }

  static TextStyle infoValue({bool isAccent = false}) {
    return TextStyle(
      fontSize: 14,
      color: isAccent ? AppColors.coralDeep : AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
  }

  // ── 首页专用 ──
  static TextStyle get greetingText => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get greetingSub => TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static TextStyle get cardValue => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    height: 1,
  );

  static TextStyle get cardValueUnit => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get cardLabel => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle trendText({required Color color}) {
    return TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color);
  }

  static TextStyle get pendingTitle => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get pendingDesc => TextStyle(
    fontSize: 12,
    color: AppColors.textHint,
  );

  static const pendingCount = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );

  static const navLabel = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);

  static TextStyle get navLabelActive => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.navActive,
  );

  static TextStyle get actionLabel => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const toastText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get itemName => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get itemMeta => TextStyle(
    fontSize: 12,
    color: AppColors.textHint,
  );

  static TextStyle itemTag({required Color color}) {
    return TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color);
  }

  static TextStyle get pullIndicatorText => TextStyle(
    fontSize: 13,
    color: AppColors.textHint,
  );
}
