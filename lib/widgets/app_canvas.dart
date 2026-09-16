import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/home_metrics.dart';

/// 宽视口下的「手机画布」（2026-09-16「实际效果 vs 参考图」修正）。
///
/// 窗口宽于 [HomeMetrics.maxContentWidth] 时，把**整个应用内容**居中限制到该宽度，
/// 两侧用全局底色托底；窄于该宽度（也就是真机）时原样返回，零影响。
///
/// 挂在 `MaterialApp.builder` 上，所以**所有路由、弹窗、浮层**一并生效，
/// 不需要每个页面各写一遍。
class AppCanvas extends StatelessWidget {
  const AppCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width <= HomeMetrics.maxContentWidth) {
      return child;
    }

    // 用 Row + 两个 Spacer 而不是 Center：Center 给的是**松约束**，
    // Navigator / Overlay 拿到无界高度会塌成 0；Row 配
    // crossAxisAlignment.stretch 能同时给出**紧的宽 + 紧的高**。
    return ColoredBox(
      color: AppColors.blushBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          SizedBox(width: HomeMetrics.maxContentWidth, child: child),
          const Spacer(),
        ],
      ),
    );
  }
}
