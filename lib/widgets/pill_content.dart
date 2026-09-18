import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 胶囊按钮（chip / pill）的「图标 + 文字」内容区。
///
/// **居中策略：图标 + 文字作为一个内容组整体居中**（与 Material/iOS 等
/// 常规胶囊一致）。文字因此相对胶囊几何中心偏 `(图标宽 + 间距) / 2`
/// ——这是有意的：居中的视觉对象是「看得见的内容」，如果反过来把文字
/// 单独钉在几何中心，就得在图标对侧补一段**看不见的等宽空白**，整个
/// 可见内容会歪向一边，用户明确否掉了那种做法（2026-09-16 第三轮反馈；
/// 此前曾有过文字几何居中的版本）。
/// 两侧都有图标时内容组天然对称，文字正好居中。
///
/// 用法：
/// ```dart
/// Container(
///   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
///   child: PillContent(
///     label: '筛选',
///     leading: Icons.tune,
///     labelStyle: TextStyle(fontSize: 12, color: fg),
///   ),
/// )
/// ```
class PillContent extends StatelessWidget {
  const PillContent({
    super.key,
    required this.label,
    this.labelStyle,
    this.leading,
    this.trailing,
    this.iconSize = 12,
    this.gap = 4,
  });

  /// Web 端 CJK 字形的光学垂直补偿（CSS px，向上为负）。
  ///
  /// 依据（2× 截图逐像素实测，见 2026-09-16 流水）：Web 端 CJK 由浏览器
  /// 回退字体（微软雅黑等）渲染，其墨水相对行盒基线**整体偏下**
  /// 0.75~1.6px，且 `TextStyle.height/leadingDistribution` 都救不了
  /// ——行距分配移动的是行盒，墨水相对基线的位置是字体的属性。
  /// 这里做一个小幅光学补偿把墨水拉回几何中心。
  ///
  /// 只在 Web 生效：原生端 CJK 走内置 Noto Sans CJK，墨水基本居中，
  /// 不需要也不应该挪。
  static const double kWebTextOpticalLift = -0.75;

  /// 胶囊上的文字。
  final String label;

  /// 文字样式；其 `color` 同时用于图标着色。
  final TextStyle? labelStyle;

  /// 前置图标（如「筛选」的漏斗）。
  final IconData? leading;

  /// 后置图标（如排序胶囊的下拉箭头）。
  final IconData? trailing;

  final double iconSize;

  /// 图标与文字之间的间距。
  final double gap;

  @override
  Widget build(BuildContext context) {
    final iconColor = labelStyle?.color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          Icon(leading, size: iconSize, color: iconColor),
          SizedBox(width: gap),
        ],
        Transform.translate(
          offset: Offset(0, kIsWeb ? kWebTextOpticalLift : 0.0),
          child: Text(
            label,
            style: (labelStyle ?? const TextStyle()).copyWith(
              // 行内剩余空间上下均分（配合上面的光学补偿把字形拉正；
              // 在 height==null 时此项本身不移动墨水，仅语义上更正确）
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: gap),
          Icon(trailing, size: iconSize, color: iconColor),
        ],
      ],
    );
  }
}
