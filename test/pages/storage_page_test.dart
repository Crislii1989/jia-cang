import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/category.dart';
import 'package:jia_cang/models/category_item.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/models/storage.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/providers/storage_providers.dart';
import 'package:jia_cang/screen/storage/storage_page.dart';

/// 测试用分类管理器：只提供内置分类 `sports → 运动`，
/// 用来验证「搜中文分类名能命中该分类下的物品」。
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

Room _room(String id, String name, {int items = 0}) => Room(
  id: id,
  name: name,
  emoji: '🛏️',
  color: const Color(0xFFE8F5E9),
  items: items,
  storageCount: 0,
);

/// 卷尺：直接放在卫生间（不归属任何柜体/箱子），分类为 sports（运动）
final Item _tapeMeasure = Item(
  id: 'item_tape',
  name: '卷尺',
  location: '卫生间',
  status: 'safe',
  categoryKey: 'sports',
  roomId: 'room_bath',
  note: '五米钢卷尺',
  createdAt: DateTime(2026, 9, 15),
);

List<Override> _overrides({required List<Item> items}) => [
  categoryManagerProvider.overrideWith(() => _FakeCategoryManager()),
  roomsProvider.overrideWith(
    (ref) async => [
      _room('room_bed', '卧室'),
      _room('room_bath', '卫生间', items: 1),
    ],
  ),
  itemsProvider.overrideWith(() => _FakeItems(items)),
];

Future<void> _pumpStoragePage(WidgetTester tester, List<Override> overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: StoragePage()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

/// 在搜索框里输入关键字并等动画/异步数据落地
Future<void> _search(WidgetTester tester, String keyword) async {
  await tester.enterText(find.byType(TextField), keyword);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

/// 只匹配真正的 `Text` 组件。
///
/// `find.text` 会把搜索框里的 `EditableText` 一起匹配上——搜什么就命中搜索框
/// 自己，断言数量会被干扰（搜「卷尺」时永远是 2 个）。这里只看展示用文案。
Finder _label(String text) =>
    find.byWidgetPredicate((w) => w is Text && w.data == text);

void main() {
  group('StoragePage 搜索', () {
    testWidgets('按物品名搜索能搜到物品本身', (tester) async {
      await _pumpStoragePage(tester, _overrides(items: [_tapeMeasure]));
      await _search(tester, '卷尺');

      // 命中的物品要出现在结果里（此前只匹配房间名，会落到空态）
      expect(_label('卷尺'), findsOneWidget);
      // 承载它的房间也要出现，方便点进去看
      expect(_label('卫生间'), findsWidgets);
      expect(find.textContaining('没有匹配'), findsNothing);
    });

    testWidgets('按分类中文名搜索能命中该分类下的物品', (tester) async {
      await _pumpStoragePage(tester, _overrides(items: [_tapeMeasure]));
      await _search(tester, '运动');

      expect(_label('卷尺'), findsOneWidget);
      expect(find.textContaining('没有匹配'), findsNothing);
    });

    testWidgets('按备注搜索能命中物品', (tester) async {
      await _pumpStoragePage(tester, _overrides(items: [_tapeMeasure]));
      await _search(tester, '钢卷尺');

      expect(_label('卷尺'), findsOneWidget);
    });

    testWidgets('确实搜不到时给出「房间或物品」都没有匹配的提示', (tester) async {
      await _pumpStoragePage(tester, _overrides(items: [_tapeMeasure]));
      await _search(tester, '不存在的东西');

      expect(_label('卷尺'), findsNothing);
      expect(
        find.textContaining('没有匹配「不存在的东西」的房间或物品'),
        findsOneWidget,
      );
    });

    testWidgets('房间名照旧可以搜', (tester) async {
      await _pumpStoragePage(tester, _overrides(items: [_tapeMeasure]));
      await _search(tester, '卧室');

      expect(_label('卧室'), findsOneWidget);
      // 卧室里没有命中物品，不应把卫生间的东西也带出来
      expect(_label('卷尺'), findsNothing);
    });
  });

  group('categoryLabelOf', () {
    const cats = [
      Category('sports', '运动', emoji: '🏋️'),
      Category('kitchen', '厨房', emoji: '🍚'),
    ];

    test('key 命中时返回中文名', () {
      expect(categoryLabelOf(cats, 'sports'), '运动');
    });

    test('key 为空时返回兜底文案', () {
      expect(categoryLabelOf(cats, ''), '未分类');
      expect(categoryLabelOf(cats, '', fallback: ''), '');
    });

    test('key 查不到时原样返回，不显示空白', () {
      expect(categoryLabelOf(cats, 'ghost'), 'ghost');
    });
  });
}
