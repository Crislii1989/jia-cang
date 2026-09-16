import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/widgets/pill_content.dart';

/// 把 [PillContent] 放进一个带对称内边距的胶囊里，返回 (胶囊矩形, 文字矩形)。
Future<(Rect, Rect)> _pump(
  WidgetTester tester, {
  required String label,
  IconData? leading,
  IconData? trailing,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            key: const ValueKey('pill'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(width: 1.5),
            ),
            child: PillContent(
              label: label,
              labelStyle: const TextStyle(fontSize: 12),
              leading: leading,
              trailing: trailing,
            ),
          ),
        ),
      ),
    ),
  );
  return (
    tester.getRect(find.byKey(const ValueKey('pill'))),
    tester.getRect(find.text(label)),
  );
}

/// 内容组（图标+文字）的外接矩形。
Rect _groupRect(Rect pill, Rect text, Rect? leadingIcon, Rect? trailingIcon) {
  var left = text.left;
  var right = text.right;
  if (leadingIcon != null) left = leadingIcon.left;
  if (trailingIcon != null) right = trailingIcon.right;
  return Rect.fromLTRB(left, text.top, right, text.bottom);
}

void main() {
  group('PillContent 内容组（图标+文字）整体居中', () {
    testWidgets('无图标：文字居中', (tester) async {
      final (pill, text) = await _pump(tester, label: '筛选');
      expect(text.center.dx, moreOrLessEquals(pill.center.dx, epsilon: 0.5));
    });

    testWidgets('只有前置图标：内容组居中（文字按组规则右移半个图标位）', (tester) async {
      final (pill, text) = await _pump(
        tester,
        label: '筛选',
        leading: Icons.tune,
      );
      final icon = tester.getRect(find.byIcon(Icons.tune));
      expect(icon.right, lessThanOrEqualTo(text.left), reason: '图标不能压字');

      final group = _groupRect(pill, text, icon, null);
      expect(group.center.dx, moreOrLessEquals(pill.center.dx, epsilon: 0.5),
          reason: '「图标+文字」整组必须落在胶囊正中');
      // 左右留白对称（组居中的直观表现）
      expect(icon.left - pill.left, moreOrLessEquals(pill.right - text.right, epsilon: 0.5));
    });

    testWidgets('只有后置图标：内容组居中（文字按组规则左移半个图标位）', (tester) async {
      final (pill, text) = await _pump(
        tester,
        label: '新增时间',
        trailing: Icons.keyboard_arrow_down,
      );
      final icon = tester.getRect(find.byIcon(Icons.keyboard_arrow_down));
      expect(icon.left, greaterThanOrEqualTo(text.right), reason: '箭头不能压字');

      final group = _groupRect(pill, text, null, icon);
      expect(group.center.dx, moreOrLessEquals(pill.center.dx, epsilon: 0.5),
          reason: '「文字+箭头」整组必须落在胶囊正中');
      expect(text.left - pill.left, moreOrLessEquals(pill.right - icon.right, epsilon: 0.5));
    });

    testWidgets('前后都有图标：天然对称，文字居中', (tester) async {
      final (pill, text) = await _pump(
        tester,
        label: '收纳位置',
        leading: Icons.tune,
        trailing: Icons.keyboard_arrow_down,
      );
      expect(text.center.dx, moreOrLessEquals(pill.center.dx, epsilon: 0.5));
    });

    testWidgets('文字垂直方向居中', (tester) async {
      final (pill, text) = await _pump(
        tester,
        label: '筛选',
        leading: Icons.tune,
      );
      expect(text.center.dy, moreOrLessEquals(pill.center.dy, epsilon: 0.5));
    });

    testWidgets('文字既不被图标压住，也不会贴到胶囊外', (tester) async {
      final (pill, text) = await _pump(
        tester,
        label: '全部柜体',
        leading: Icons.arrow_upward,
      );
      expect(text.left, greaterThan(pill.left));
      expect(text.right, lessThan(pill.right));
    });
  });
}
