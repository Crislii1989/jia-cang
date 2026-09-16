import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/providers/item_providers.dart';

/// 测试用物品列表
/// - 本周新增（本周一之后）→ 计入 weeklyNewCount
/// - 本月新增（1 日之后、本周一之前）→ 只计入 monthlyNewCount
/// - 更早 → 两者都不计入
List<Item> createTestItems() {
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day - (now.weekday - DateTime.monday));
  final firstOfMonth = DateTime(now.year, now.month, 1);

  final thisWeek = monday.add(const Duration(hours: 12));
  final thisMonthBeforeWeek = firstOfMonth.add(const Duration(days: 1));
  final lastMonth = DateTime(now.year, now.month - 1, 15);

  return [
    Item(
      id: '1',
      name: '本周新增',
      location: '客厅',
      createdAt: thisWeek,
    ),
    Item(
      id: '2',
      name: '本月早前',
      location: '书房',
      createdAt: thisMonthBeforeWeek,
    ),
    Item(
      id: '3',
      name: '上月物品',
      location: '储物间',
      createdAt: lastMonth,
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

/// 创建覆盖派生 Provider 的 ProviderContainer（绕过 itemsProvider 的数据库依赖）
ProviderContainer createTestContainer() {
  final items = createTestItems();
  return ProviderContainer(
    overrides: [
      itemsProvider.overrideWith(() => _FakeItems(items)),
    ],
  );
}

void main() {
  group('itemCountProvider', () {
    test('返回物品总数', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      await container.read(itemsProvider.future);
      expect(container.read(itemCountProvider), 3);
    });
  });

  group('weeklyNewCountProvider', () {
    test('只统计本周一之后创建的物品', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      await container.read(itemsProvider.future);
      expect(container.read(weeklyNewCountProvider), 1);
    });
  });

  group('monthlyNewCountProvider', () {
    test('统计本月 1 日之后创建（含本周）', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      await container.read(itemsProvider.future);
      expect(container.read(monthlyNewCountProvider), 2);
    });
  });

  group('recentItemsProvider', () {
    test('按 createdAt 降序排列', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      await container.read(itemsProvider.future);
      final recent = container.read(recentItemsProvider);
      expect(recent.map((i) => i.name).toList(), ['本周新增', '本月早前', '上月物品']);
    });
  });

  group('itemByIdProvider', () {
    test('按 id 命中', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      await container.read(itemsProvider.future);
      final item = container.read(itemByIdProvider('2'));
      expect(item?.name, '本月早前');
    });

    test('不存在的 id 返回 null', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);
      await container.read(itemsProvider.future);
      expect(container.read(itemByIdProvider('nope')), isNull);
    });
  });
}
