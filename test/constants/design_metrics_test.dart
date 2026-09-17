import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/constants/design_metrics.dart';
import 'package:jia_cang/models/category_item.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/screen/home/home_page.dart';
import 'package:jia_cang/widgets/app_canvas.dart';

/// 首页版式等比缩放 / 宽视口限宽 的回归测试（2026-09-16）。
///
/// 背景：设计稿机型是 320 宽（内容宽 292），代码里的尺寸是绝对值，
/// 而横向容器 `Expanded` 铺满视口 —— 视口一宽，统计卡由竖版变横版、
/// 分类圆周围留白翻数倍。这组测试把「比例」钉死，防止改回去。
class _FakeCategoryManager extends CategoryManager {
  /// 给满 4 个分类：首页一行 4 个圆，正好覆盖四色轮转
  @override
  Future<List<CategoryItem>> build() async => const [
    CategoryItem(id: 'digital', label: '数码', emoji: '📱', isBuiltIn: true),
    CategoryItem(id: 'appliance', label: '家电', emoji: '🔌', isBuiltIn: true),
    CategoryItem(id: 'clothes', label: '衣物', emoji: '🧥', isBuiltIn: true),
    CategoryItem(id: 'toiletry', label: '洗护', emoji: '💊', isBuiltIn: true),
  ];
}

class _FakeItems extends Items {
  final List<Item> items;
  _FakeItems(this.items);

  @override
  Future<List<Item>> build() async => items;
}

List<Override> _overrides() => [
  itemsProvider.overrideWith(() => _FakeItems(const [])),
  categoryManagerProvider.overrideWith(() => _FakeCategoryManager()),
];

/// 圆形图标底：唯一同时「宽高都是紧约束」的正方形容器（统计卡由
/// `Expanded` 撑开、搜索条只有紧高度，都不会被这个谓词命中）。
Finder get _squareContainers => find.byWidgetPredicate((w) {
  if (w is! Container) return false;
  final c = w.constraints;
  return c != null &&
      c.minWidth == c.maxWidth &&
      c.minHeight == c.maxHeight &&
      c.maxWidth > 20 &&
      c.maxWidth < 200;
});

void main() {
  group('DesignMetrics', () {
    test('按设计稿内容宽 292 计算缩放因子', () {
      // 320 机型：可用行宽 = 320 − 2×20 = 280
      expect(DesignMetrics.scaleFor(320), closeTo(280 / 292, 0.0001));
      // 常见真机
      expect(DesignMetrics.scaleFor(360), closeTo(320 / 292, 0.0001));
      expect(DesignMetrics.scaleFor(390), closeTo(350 / 292, 0.0001));
      // 宽视口上限 430：可用行宽 390
      expect(DesignMetrics.scaleFor(430), closeTo(390 / 292, 0.0001));
    });

    test('宽于 430 的视口一律按 430 计算（与 AppCanvas 的限宽一致）', () {
      expect(DesignMetrics.scaleFor(531), DesignMetrics.scaleFor(430));
      expect(DesignMetrics.scaleFor(1440), DesignMetrics.scaleFor(430));
    });

    test('缩放因子被夹在 [0.9, 1.35] 内，不会失控', () {
      expect(DesignMetrics.scaleFor(200), DesignMetrics.minScale);
      expect(
        DesignMetrics.scaleFor(4000),
        lessThanOrEqualTo(DesignMetrics.maxScale),
      );
      // 上限本身不会被突破，且限宽后各宽视口结果完全一致
      expect(DesignMetrics.scaleFor(4000), DesignMetrics.scaleFor(430));
    });
  });

  group('AppCanvas', () {
    testWidgets('窄视口（真机）不介入', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final key = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(home: AppCanvas(child: SizedBox.expand(key: key))),
      );

      expect(tester.getSize(find.byKey(key)).width, 390);
    });

    testWidgets('宽视口把内容居中限宽到 430', (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final key = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(home: AppCanvas(child: SizedBox.expand(key: key))),
      );

      final rect = tester.getRect(find.byKey(key));
      expect(rect.width, DesignMetrics.maxContentWidth);
      expect(rect.center.dx, closeTo(450, 0.5)); // 居中
      expect(rect.height, 700); // 高度仍撑满，导航条/操作条贴底不塌
    });
  });

  group('首页尺寸随之等比', () {
    Future<void> pumpHome(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          // 按真实组合来：AppCanvas 在 ≤430 时是 no-op，宽视口才限宽
          child: const MaterialApp(home: AppCanvas(child: HomePage())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }

    testWidgets('分类圆直径 = 56 × k（430 视口下 k≈1.336）', (tester) async {
      await pumpHome(tester, const Size(430, 932));

      final k = DesignMetrics.scaleFor(430);
      expect(_squareContainers, findsNWidgets(4));
      for (final element in _squareContainers.evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, closeTo(56 * k, 0.5));
        expect(size.height, closeTo(56 * k, 0.5));
      }
    });

    testWidgets('分类圆直径 = 56 × k（320 机型下 k≈0.959）', (tester) async {
      await pumpHome(tester, const Size(320, 640));

      final k = DesignMetrics.scaleFor(320);
      for (final element in _squareContainers.evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, closeTo(56 * k, 0.5));
      }
    });

    testWidgets('统计卡保持竖版（高 / 宽 ≈ 1.42），不被拉成横版', (tester) async {
      await pumpHome(tester, const Size(430, 932));

      final card = find
          .ancestor(of: find.text('物品总数'), matching: find.byType(Container))
          .first;
      final size = tester.getSize(card);

      // 设计稿比例 96 / 67.75 ≈ 1.42（竖版）。
      // 修复前 430 视口下卡片被拉成 ≈92×93（比例 ≈1.00，接近方形/横版），
      // 所以 1.2 这条线能可靠区分「修好了」与「又拉横了」。
      expect(
        size.height / size.width,
        greaterThan(1.2),
        reason: '统计卡必须保持竖版比例，宽度不该随视口无限拉伸',
      );
      expect(size.height, greaterThan(size.width));
    });

    testWidgets('宽视口（531）与 430 的卡片比例一致 —— 不再随窗口变形', (tester) async {
      await pumpHome(tester, const Size(531, 855));

      final card = find
          .ancestor(of: find.text('物品总数'), matching: find.byType(Container))
          .first;
      final size = tester.getSize(card);

      // 531 视口下 AppCanvas 把内容限宽到 430，k 也取 430 档，
      // 所以卡片比例与真机 430 完全一致（这正是用户反馈的那一版）。
      expect(size.height / size.width, greaterThan(1.2));
      expect(size.width, lessThan(100));
    });
  });
}
