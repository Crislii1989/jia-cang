import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 全局浅色主题（跟随当前皮肤的主色）。
///
/// 此前 MaterialApp 只有 `primarySwatch: Colors.amber`，导致
/// showDatePicker 等系统组件回落到 Material 默认紫色，与全局主题冲突
/// （2026-09-16 用户反馈）。这里集中给一套由皮肤主色派生的 ColorScheme，
/// 并为日期选择器定制样式；系统组件（开关/菜单/对话框）会自动跟随。
///
/// ⚠️ 本函数在**每次构建时调用**（见 main.dart 的 MaterialApp），
/// 换肤后主题会立刻跟着变；不要把它缓存成常量。
ThemeData buildAppTheme() {
  // fromSeed 出来的中间色（容器色/悬停色等）由珊瑚种子派生；
  // 品牌关键色再显式钉住，避免 HCT 调色带来的色相漂移
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.coral).copyWith(
    primary: AppColors.coralDeep,
    onPrimary: Colors.white,
    secondary: AppColors.coral,
    onSecondary: Colors.white,
    surface: AppColors.cardBg,
    onSurface: AppColors.blushInk,
    onSurfaceVariant: AppColors.blushInk2,
    outline: AppColors.border,
    error: AppColors.alertRed,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.blushBg,
    datePickerTheme: DatePickerThemeData(
      // 白卡 + 应用圆角，与全局弹窗底座观感一致
      backgroundColor: AppColors.cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      headerForegroundColor: AppColors.blushInk,
      headerHeadlineStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.blushInk,
      ),
      weekdayStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.blushInk2,
      ),
      dayStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.blushInk,
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return AppColors.blushInk3;
        return AppColors.blushInk;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.coral;
        return null;
      }),
      // 「今天」：珊瑚描边圆圈，选中时白字珊瑚底
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.coralDeep;
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.coral;
        return null;
      }),
      todayBorder: BorderSide(color: AppColors.coral),
      yearStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.blushInk,
      ),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.blushInk;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.coral;
        return null;
      }),
    ),
  );
}
