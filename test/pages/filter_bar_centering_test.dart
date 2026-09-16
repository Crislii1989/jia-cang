import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/category_item.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/screen/inventory/inventory_page.dart';

class _FakeCategoryManager extends CategoryManager {
  @override
  Future<List<CategoryItem>> build() async => const [];
}

class _FakeItems extends Items {
  @override
  Future<List<Item>> build() async => const [];
}

Finder _text(String s) => find.byWidgetPredicate((w) => w is Text && w.data == s);

void main() {
  testWidgets('物品库：排序 / 筛选胶囊的「图标+文字」内容组整体居中', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryManagerProvider.overrideWith(() => _FakeCategoryManager()),
          itemsProvider.overrideWith(() => _FakeItems()),
        ],
        child: const MaterialApp(home: InventoryPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    for (final label in ['新增时间', '筛选']) {
      final tf = _text(label);
      expect(tf, findsOneWidget, reason: '找不到胶囊文字「$label」');

      final cf = find
          .ancestor(of: tf, matching: find.byType(Container))
          .first;
      final textRect = tester.getRect(tf);
      final chipRect = tester.getRect(cf);

      // 同一胶囊内的所有图标（前置 / 后置，可能没有）
      final iconRects = find
          .descendant(of: cf, matching: find.byType(Icon))
          .evaluate()
          .map((e) => tester.getRect(find.byElementPredicate((el) => el == e)))
          .toList();

      // 内容组矩形 = 文字 + 所有图标的包围盒
      var group = textRect;
      for (final r in iconRects) {
        group = group.expandToInclude(r);
      }

      // 内容组中心必须与胶囊中心重合。文字自身允许被图标挤偏
      // （这是「图标+文字组居中」约定的预期表现，用户已确认）。
      expect(
        group.center.dx,
        moreOrLessEquals(chipRect.center.dx, epsilon: 0.5),
        reason:
            '「$label」内容组中心 ${group.center.dx} '
            '≠ 胶囊中心 ${chipRect.center.dx}',
      );
      // 内容组两侧留白对称
      expect(
        group.left - chipRect.left,
        moreOrLessEquals(chipRect.right - group.right, epsilon: 0.5),
        reason: '「$label」内容组左右留白不对称',
      );
      // 文字垂直居中
      expect(
        textRect.center.dy,
        moreOrLessEquals(chipRect.center.dy, epsilon: 0.5),
        reason: '「$label」文字垂直方向未居中',
      );
    }
  });
}
