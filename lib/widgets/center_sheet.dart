import 'package:flutter/material.dart';

/// 弹窗统一圆角半径。
///
/// 所有弹窗（`showCenterSheet` 调起的、以及页面 Stack 里浮层式的）
/// 都从这里取半径，避免各写一份、改一处漏一处。
const double kCenterSheetRadius = 24;

/// 将原 `showModalBottomSheet` 的内容包装为居中弹窗。
///
/// 用法与 `showModalBottomSheet` 一致，只是弹窗从底部改到屏幕中间，
/// 适合选择器、操作菜单等需要快速触达的场景。
///
/// 自动处理：
/// - 屏幕中间定位 + **四角圆角**
/// - 最大宽度限制（移动端全宽减 padding，桌面/web 端不超过 420）
/// - 最大高度限制（屏幕高度 75%）
///
/// **圆角是在这里（底层）裁剪的**：[builder] 返回的内容即使自带了
/// `BorderRadius.only(topLeft/topRight)` 这种「只圆上边」的旧式贴底装饰，
/// 也会被外层 `ClipRRect` 统一裁成四角圆角，不会再出现底部直角边。
/// 因此调用方可以放心沿用旧代码，**不需要**各自再补圆角。
Future<T?> showCenterSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color backgroundColor = Colors.white,
  double borderRadius = kCenterSheetRadius,
  bool barrierDismissible = true,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final screenHeight = MediaQuery.sizeOf(context).height;
  // 移动端贴近全宽减边距；宽屏（web/桌面）限宽 420 居中
  final maxWidth = screenWidth < 600 ? screenWidth - 32 : 420.0;
  final maxHeight = screenHeight * 0.75;

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Material(
              color: backgroundColor,
              child: builder(ctx),
            ),
          ),
        ),
      );
    },
  );
}

/// 弹窗内容面板：白底、四角圆角、统一内边距。
///
/// 与 [showCenterSheet] 配套使用：调用方只要返回
/// `CenterSheetSurface(child: ...)`，就不必再手写
/// `BoxDecoration(color: Colors.white, borderRadius: ...)`——
/// 手写时最容易漏掉下面两个角（历史上就是「贴底弹窗」留下的写法）。
class CenterSheetSurface extends StatelessWidget {
  /// 面板内容。
  final Widget child;

  /// 内边距，默认与旧弹窗一致（左 20 / 上 20 / 右 20 / 下 28）。
  final EdgeInsetsGeometry padding;

  /// 圆角半径，默认 [kCenterSheetRadius]。
  final double borderRadius;

  /// 背景色。
  final Color color;

  const CenterSheetSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 28),
    this.borderRadius = kCenterSheetRadius,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// 页面内浮层式居中弹窗外壳（替代 `Positioned.fill` + `Align.bottomCenter`）。
///
/// 直接作为页面 `Stack` 的子节点使用：
/// ```dart
/// Stack(
///   children: [
///     ...,
///     if (_showModal)
///       CenterModalShell(
///         onDismiss: _close,
///         child: SingleChildScrollView(child: Column(...)),
///       ),
///   ],
/// )
/// ```
///
/// 与 [showCenterSheet] 的区别：本组件不新建 route，直接在页面里盖一层遮罩，
/// 适合需要贴着页面状态、由 `setState` 控制的弹窗。
///
/// 相同点：**始终居中、四角圆角**——底部不会贴边，也不会有直角边。
class CenterModalShell extends StatelessWidget {
  /// 面板内容（不含内边距与背景，外壳统一提供）。
  final Widget child;

  /// 点击遮罩时的回调；为 null 时点遮罩不关闭。
  final VoidCallback? onDismiss;

  /// 最大宽度（宽屏/桌面端限宽，避免横跨整个屏幕）。
  final double maxWidth;

  /// 最大高度占屏幕高度的比例。
  final double maxHeightFactor;

  /// 最大高度绝对值上限（可选，与 [maxHeightFactor] 取小）。
  final double? maxHeight;

  /// 面板内边距。
  final EdgeInsetsGeometry padding;

  /// 圆角半径。
  final double borderRadius;

  /// 遮罩颜色。
  final Color barrierColor;

  /// 面板的 Key（测试用）。
  static const Key panelKey = ValueKey('centerModalPanel');

  const CenterModalShell({
    super.key,
    required this.child,
    this.onDismiss,
    this.maxWidth = 480,
    this.maxHeightFactor = 0.78,
    this.maxHeight,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 28),
    this.borderRadius = kCenterSheetRadius,
    this.barrierColor = const Color(0x59000000),
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heightLimit = screenHeight * maxHeightFactor;
    final limit = maxHeight == null
        ? heightLimit
        : (maxHeight! < heightLimit ? maxHeight! : heightLimit);

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Container(
          color: barrierColor,
          // 阻止点击穿透到下层页面
          child: GestureDetector(
            onTap: () {},
            child: Center(
              child: Container(
                key: panelKey,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: limit),
                padding: padding,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                // 关键：把内容裁进圆角内，杜绝底部出现直角边
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
