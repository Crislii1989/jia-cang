import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 统一阴影。
///
/// ⚠️ 全部写成 **getter**：颜色跟随皮肤，若用 `static const` 编译不过，
/// 若用 `static final` 则会在首次访问时把颜色冻结住（换肤后阴影不变），
/// 所以这里刻意保持「每次访问重新构造」。
class AppShadows {
  AppShadows._();

  // ── 卡片阴影 ──
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.08),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  // ── 浮动元素阴影 ──
  static List<BoxShadow> get floating => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ── 底部导航栏阴影 ──
  static List<BoxShadow> get navBar => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];

  // ── 添加按钮阴影 ──
  static List<BoxShadow> get addButton => [
    BoxShadow(
      color: AppColors.btnPrimaryShadow,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Logo 阴影 ──
  static List<BoxShadow> get logo => [
    BoxShadow(
      color: AppColors.btnPrimaryShadow,
      blurRadius: 48,
      offset: const Offset(0, 16),
    ),
  ];

  // ── 卡片主色阴影 ──
  static List<BoxShadow> get cardAccent => [
    BoxShadow(
      color: AppColors.floatCardShadowStrong,
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
  ];

  // ── 自定义阴影（带颜色） ──
  static List<BoxShadow> colored({
    required Color color,
    double blurRadius = 12,
    Offset offset = const Offset(0, 4),
    double alpha = 0.3,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }
}