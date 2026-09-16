import 'package:flutter/widgets.dart';

/// 首页版式等比缩放（2026-09-16「实际效果 vs 参考图」修正）。
///
/// **为什么要缩放**：设计稿 `docs/ui-hifi-mockups.html` 的机型是 **320×660**
/// （`.phone` 的 `padding 10/12/8` + `border 2` ⇒ 内容宽 **292**），
/// 代码里的尺寸（分类圆 56、字号 20/11/10.5、卡内距 5/10/11、行内距 7/8 …）
/// 全是按这个宽度定下的**绝对值**；而运行时横向容器一律用 `Expanded` 铺满视口。
/// 于是视口一宽（Web / 桌面预览常见 430~530），**横向被拉伸、纵向纹丝不动**：
/// 统计卡由竖版变横版、分类圆周围留白翻数倍、文字相对变小。
///
/// **解法**：以「可用行宽 ÷ 设计行宽 292」为缩放因子 [k]，
/// 首页所有尺寸写成 `设计值 * k`，任何宽度都保持设计稿的比例。
/// 配合 [maxContentWidth] 在宽视口把内容居中限宽，避免在桌面端被无限放大。
class HomeMetrics {
  HomeMetrics._();

  /// 设计稿机型宽
  static const double designPhoneWidth = 320;

  /// 设计稿内容宽 = 320 − 2×12(padding) − 2×2(border)
  static const double designRowWidth = 292;

  /// 页面左右留白（与 `AppDimensions.pageMarginHorizontal` 一致）。
  /// **不参与缩放**：它与悬浮条的 `sideInset = 20 − 6` 关系是钉死的，
  /// 改了会让「悬浮条比内容卡每侧宽 6」这条定稿规则失效。
  static const double pageMargin = 20;

  /// 宽视口下的内容上限。真机（≤430）完全不受影响；
  /// 桌面 / 网页预览会居中成一列手机宽度。
  static const double maxContentWidth = 430;

  /// 缩放因子下限：小屏不至于把内容挤爆
  static const double minScale = 0.9;

  /// 缩放因子上限：配 [maxContentWidth] 后，430 视口恰好取到 390/292 ≈ 1.336
  static const double maxScale = 1.35;

  /// 视口宽 → 缩放因子
  static double scaleFor(double windowWidth) {
    final content =
        windowWidth < maxContentWidth ? windowWidth : maxContentWidth;
    final row = content - pageMargin * 2;
    return (row / designRowWidth).clamp(minScale, maxScale);
  }

  /// 当前上下文对应的缩放因子
  static double of(BuildContext context) =>
      scaleFor(MediaQuery.sizeOf(context).width);

  /// 把设计稿上的一个尺寸换算成当前尺寸
  static double v(BuildContext context, double designValue) =>
      designValue * of(context);
}
