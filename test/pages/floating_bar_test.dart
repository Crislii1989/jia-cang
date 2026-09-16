import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/category.dart';
import 'package:jia_cang/models/category_item.dart';
import 'package:jia_cang/models/enums/tab_type.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/providers/storage_providers.dart';
import 'package:jia_cang/screen/add_item_page.dart';
import 'package:jia_cang/screen/item_detail_page.dart';
import 'package:jia_cang/widgets/bottom_nav_bar.dart';
import 'package:jia_cang/widgets/floating_bar.dart';

/// 悬浮圆角白条（V2.6 定稿）的**几何回归**。
///
/// 这几条断言是设计稿里最容易在改版中被悄悄改坏的数字：
/// 「条比内容卡每侧宽出 6」= 内容卡左右留白 20 → 条左右留白 14；
/// 高 60 / 圆角 20 / 无顶部分割线 / 无激活指示线；条内按钮是 40pt 胶囊。
/// 底部导航、详情页操作条、添加页操作条必须完全同规格。
class _FakeCategoryManager extends CategoryManager {
  @override
  Future<List<CategoryItem>> build() async => [
    const CategoryItem(id: 'food', label: '餐厨', emoji: '🍳', isBuiltIn: true),
  ];
}

class _FakeItems extends Items {
  final List<Item> items;
  _FakeItems(this.items);

  @override
  Future<List<Item>> build() async => items;
}

/// 悬浮条本体：`FloatingBar` 里那层带装饰的 Container（不含外层左右留白）
Finder _barBox() => find
    .descendant(of: find.byType(FloatingBar), matching: find.byType(Container))
    .first;

/// 某个按钮文字所在的胶囊容器
Finder _pillOf(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(Container))
    .first;

const double _screenW = 800; // 测试默认屏宽
const double _cardMargin = 20; // 内容卡左右留白
const double _barMargin = FloatingBar.sideInset; // 条左右留白 = 20 - 6

void _expectFloatingBarGeometry(WidgetTester tester) {
  final rect = tester.getRect(_barBox());

  // 比内容卡每侧宽出 6
  expect(rect.left, _barMargin);
  expect(_screenW - rect.right, _barMargin);
  expect(
    rect.width,
    (_screenW - _cardMargin * 2) + (_cardMargin - _barMargin) * 2,
    reason: '条宽 = 内容卡宽 + 每侧 6',
  );

  expect(rect.height, FloatingBar.height);
  expect(rect.height, 60);

  final deco = tester.widget<Container>(_barBox()).decoration as BoxDecoration;
  expect(deco.borderRadius, BorderRadius.circular(20));
  expect(deco.border, isNull, reason: '悬浮条不能有顶部分割线');
  expect(deco.boxShadow, isNotNull);
}

void main() {
  testWidgets('底部导航：悬浮圆角条几何 + 4 Tab 文案 + 中央添加钮', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentTab: TabType.home,
            onTabChanged: (_) {},
          ),
        ),
      ),
    );

    _expectFloatingBarGeometry(tester);

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('物品库'), findsOneWidget);
    expect(find.text('收纳'), findsOneWidget);
    // 第 4 个 Tab 的文案是「我的」（旧版是「个人中心」）
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('个人中心'), findsNothing);
    // 中央添加钮（不是 Tab，点击 push /add_item）
    expect(
      find.descendant(
        of: find.byType(FloatingBar),
        matching: find.byIcon(Icons.add),
      ),
      findsOneWidget,
    );
  });

  testWidgets('详情页操作条：与导航条同规格，条内是 40pt 胶囊按钮', (tester) async {
    final item = Item(
      id: 'item_1',
      name: '牙刷',
      location: '卫生间',
      categoryKey: 'food',
      roomId: 'room_bath',
      createdAt: DateTime(2026, 9, 15),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsProvider.overrideWith(() => _FakeItems([item])),
          availableCategoriesProvider.overrideWith(
            (ref) => const [Category('food', '餐厨', emoji: '🍳')],
          ),
          storageLocationTreeProvider.overrideWith(
            (ref) async => <StorageLocationNode>[],
          ),
        ],
        child: const MaterialApp(home: ItemDetailPage(itemId: 'item_1')),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    _expectFloatingBarGeometry(tester);

    // V2.6/S3 改版：条内是「出借（ghost，safe 物品）/ 编辑（primary）」；
    // 删除不再是条内按钮，而是左下角固定旋钮（见 _DeleteKnob）。
    expect(find.byType(FloatingBarButton), findsNWidgets(2));
    for (final label in ['出借', '编辑']) {
      final pill = tester.widget<Container>(_pillOf(label));
      final deco = pill.decoration as BoxDecoration;
      expect(tester.getSize(_pillOf(label)).height, FloatingBar.buttonHeight);
      expect(deco.borderRadius, BorderRadius.circular(999));
    }
    // 删除旋钮：左下角贴边固定（left 14 / bottom 76），不随内容滚动
    final knob = tester.getRect(
      find.ancestor(of: find.byIcon(Icons.delete_outline), matching: find.byType(Container)).first,
    );
    expect(knob.width, 40);
    expect(knob.height, 40);
    expect(knob.left, 14);
  });

  testWidgets('添加页操作条：与导航条同规格', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryManagerProvider.overrideWith(() => _FakeCategoryManager()),
          storageLocationTreeProvider.overrideWith(
            (ref) async => <StorageLocationNode>[],
          ),
        ],
        child: const MaterialApp(home: AddItemPage()),
      ),
    );
    await tester.pump();

    _expectFloatingBarGeometry(tester);

    expect(find.text('保存入库'), findsOneWidget);
    expect(find.text('保存并继续新增'), findsOneWidget);
    expect(tester.getSize(_pillOf('保存入库')).height, FloatingBar.buttonHeight);
  });
}
