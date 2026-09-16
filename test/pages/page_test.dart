import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/category_item.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/providers/storage_providers.dart';
import 'package:jia_cang/screen/home_page.dart';
import 'package:jia_cang/screen/add_item_page.dart';

/// 测试用分类管理器：避免测试环境访问真实数据库。
///
/// 只放一个内置分类 `sports → 运动`，用来验证
/// 「编辑物品时按 categoryKey 回填中文名」这条链路。
class _FakeCategoryManager extends CategoryManager {
  @override
  Future<List<CategoryItem>> build() async => [
    const CategoryItem(
      id: 'sports',
      label: '运动',
      emoji: '🏋️',
      isBuiltIn: true,
    ),
  ];
}

/// 用内存数据替换 Items AsyncNotifier（绕过数据库依赖）
class _FakeItems extends Items {
  final List<Item> items;
  _FakeItems(this.items);

  @override
  Future<List<Item>> build() async => items;
}

/// AddItemPage 的位置选择器所需的公共覆盖项。
///
/// 页面会在 initState 里 listenManual(storageLocationTreeProvider)，
/// 而该 provider 会一路取到 roomDao → databaseProvider，也就是真的去
/// 实例化并打开一个 AppDatabase。在 widget 测试里这既不该发生（测试不该
/// 碰真实数据库文件），也会留下 drift 打开连接时创建的 Timer，
/// 导致 "A Timer is still pending even after the widget tree was disposed"。
/// 直接覆盖成空位置，页面逻辑照常渲染。
List<Override> _addItemPageOverrides() => [
  categoryManagerProvider.overrideWith(() => _FakeCategoryManager()),
  storageLocationTreeProvider.overrideWith(
    (ref) async => <StorageLocationNode>[],
  ),
];

void main() {
  group('HomePage', () {
    testWidgets('renders greeting', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemCountProvider.overrideWith((ref) => 2),
            weeklyNewCountProvider.overrideWith((ref) => 1),
            monthlyNewCountProvider.overrideWith((ref) => 2),
            recentItemsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // 问候语根据时间动态变化，使用默认昵称"小橘"
      expect(find.textContaining('小橘'), findsOneWidget);
    });

    testWidgets('renders data card labels', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemCountProvider.overrideWith((ref) => 2),
            weeklyNewCountProvider.overrideWith((ref) => 1),
            monthlyNewCountProvider.overrideWith((ref) => 2),
            recentItemsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('物品总数'), findsOneWidget);
      expect(find.text('本月新增'), findsOneWidget);
    });
  });

  group('AddItemPage', () {
    testWidgets('renders form fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _addItemPageOverrides(),
          child: const MaterialApp(home: AddItemPage()),
        ),
      );
      await tester.pump();

      expect(find.text('物品名称'), findsOneWidget);
      expect(find.text('到期日'), findsOneWidget);
      expect(find.text('登记时间'), findsOneWidget);
      expect(find.text('保存入库'), findsOneWidget);
    });

    testWidgets('shows validation error when saving empty form', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _addItemPageOverrides(),
          child: const MaterialApp(home: AddItemPage()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('保存入库'));
      await tester.pump();
      expect(find.text('请填写物品名称'), findsOneWidget);
      // 等 toast 的 2 秒自动消失 Timer 走完，避免测试结束时有 pending Timer
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('编辑模式按 categoryKey 回填分类中文名', (tester) async {
      final item = Item(
        id: 'item_1',
        name: '牙刷',
        location: '卫生间',
        status: 'safe',
        categoryKey: 'sports',
        roomId: 'room_bath',
        createdAt: DateTime(2026, 9, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._addItemPageOverrides(),
            itemsProvider.overrideWith(() => _FakeItems([item])),
          ],
          child: const MaterialApp(home: AddItemPage(itemId: 'item_1')),
        ),
      );
      // 首帧 → itemsProvider / 分类数据落地 → 预填充 + 分类反查
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('编辑物品'), findsOneWidget);
      // 名称与位置回填
      expect(find.text('牙刷'), findsOneWidget);
      expect(find.text('卫生间'), findsOneWidget);
      // 分类回填成中文名：既不是空态占位，也不是裸 key
      expect(find.text('运动'), findsOneWidget);
      expect(find.text('选择分类'), findsNothing);
      expect(find.text('sports'), findsNothing);
    });
  });
}
