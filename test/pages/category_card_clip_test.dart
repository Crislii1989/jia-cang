import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/category_item.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/screen/category/category_page.dart';

/// 测试用分类管理器：避免测试环境访问真实数据库。
class _FakeCategoryManager extends CategoryManager {
  @override
  Future<List<CategoryItem>> build() async => [
    const CategoryItem(
      id: 'digital',
      label: '数码',
      emoji: '📱',
      isBuiltIn: true,
    ),
  ];
}

/// 顶部色条：4px 高、带渐变、无圆角（圆角由外层卡片裁出来）
bool _isAccentBar(Widget w) {
  if (w is! Container) return false;
  if (w.constraints != const BoxConstraints.tightFor(height: 4)) return false;
  final d = w.decoration;
  return d is BoxDecoration && d.gradient is LinearGradient;
}

/// 卡片外壳：24 圆角 + 阴影
bool _isCardShell(Widget w) {
  if (w is! Container) return false;
  final d = w.decoration;
  return d is BoxDecoration &&
      d.borderRadius == BorderRadius.circular(24) &&
      (d.boxShadow?.isNotEmpty ?? false);
}

void main() {
  group('分类卡片圆角裁剪', () {
    // 回归背景：顶部色条是一条 4px 高的实心矩形，卡片圆角是 24px。
    // 卡片这一层不裁剪时，色条四角会戳出圆角弧线之外 →「颜色条突出分类的边框」。
    // 修法是给卡片 Container 加 clipBehavior；色条自己写 BorderRadius 没用，
    // 因为它只有 4px 高，24 的圆角会被 Flutter 缩放到 ~2px，仍然比卡片圆角「方」。
    testWidgets('卡片必须裁剪子节点，色条不再戳出圆角', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryManagerProvider.overrideWith(() => _FakeCategoryManager()),
          ],
          child: const MaterialApp(home: CategoryPage()),
        ),
      );
      // 异步 notifier 落地 + 400ms 入场动画走完
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final barFinder = find.byWidgetPredicate(_isAccentBar);
      expect(barFinder, findsWidgets, reason: '没找到顶部色条，测试前提不成立');

      final cardFinder = find.ancestor(
        of: barFinder.first,
        matching: find.byWidgetPredicate(_isCardShell),
      );
      expect(cardFinder, findsWidgets, reason: '没找到 24 圆角带阴影的卡片外壳');

      final card = tester.widget<Container>(cardFinder.first);
      expect(
        card.clipBehavior,
        Clip.antiAlias,
        reason: '分类卡片必须裁剪子节点，否则 4px 高的顶部色条会戳出 24px 圆角',
      );
      expect(
        (card.decoration! as BoxDecoration).boxShadow,
        isNotEmpty,
        reason: '裁剪只作用于子节点，卡片阴影必须保留（不要为了裁剪把阴影删掉）',
      );

      final bar = tester.widget<Container>(barFinder.first);
      expect(
        (bar.decoration! as BoxDecoration).borderRadius,
        isNull,
        reason: '色条的圆角由外层卡片裁剪，自身不要再写 BorderRadius（写了也没用且会误导）',
      );
    });
  });
}
