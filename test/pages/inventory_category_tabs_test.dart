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
  Future<List<CategoryItem>> build() async => _kFourteenCategories;
}

/// 与 v8 种子数据一致的 14 个内置分类（id + label 对齐 seed_data.dart）。
const List<CategoryItem> _kFourteenCategories = [
  CategoryItem(id: 'digital', label: '数码电子', emoji: '📱', isBuiltIn: true, sortOrder: 0),
  CategoryItem(id: 'appliance', label: '家电', emoji: '🔌', isBuiltIn: true, sortOrder: 1),
  CategoryItem(id: 'clothing', label: '衣物鞋包', emoji: '👔', isBuiltIn: true, sortOrder: 2),
  CategoryItem(id: 'toiletry', label: '个人洗护', emoji: '🧼', isBuiltIn: true, sortOrder: 3),
  CategoryItem(id: 'kitchen', label: '餐厨用品', emoji: '🍚', isBuiltIn: true, sortOrder: 4),
  CategoryItem(id: 'home_living', label: '家居生活', emoji: '🏠', isBuiltIn: true, sortOrder: 5),
  CategoryItem(id: 'sports', label: '运动户外', emoji: '🏋️', isBuiltIn: true, sortOrder: 6),
  CategoryItem(id: 'books', label: '书籍', emoji: '📚', isBuiltIn: true, sortOrder: 7),
  CategoryItem(id: 'stationery', label: '文具办公', emoji: '✏️', isBuiltIn: true, sortOrder: 8),
  CategoryItem(id: 'toy', label: '玩具兴趣', emoji: '🧸', isBuiltIn: true, sortOrder: 9),
  CategoryItem(id: 'tools', label: '工具五金', emoji: '🔧', isBuiltIn: true, sortOrder: 10),
  CategoryItem(id: 'jewelry', label: '饰品贵重', emoji: '💍', isBuiltIn: true, sortOrder: 11),
  CategoryItem(id: 'decoration', label: '家居装饰', emoji: '🖼️', isBuiltIn: true, sortOrder: 12),
  CategoryItem(id: 'other', label: '其他', emoji: '📦', isBuiltIn: true, sortOrder: 13),
];

class _FakeItems extends Items {
  @override
  Future<List<Item>> build() async => const [];
}

/// 只匹配展示用 Text，不误伤输入框（find.text 会把 EditableText 也算上）。
Finder _label(String s) => find.byWidgetPredicate((w) => w is Text && w.data == s);

void main() {
  testWidgets('物品库分类列表：14 个内置分类全部一屏可见（多行 Wrap，不横滑）', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.reset);

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

    // 「全部」+ 14 个内置分类，共 15 个芯片必须全部实际构建出来。
    // 旧实现是单行横向 ListView，视口外的芯片根本不会 build（find 落空）；
    // 改成 Wrap 多行流式后全部可见。
    expect(_label('全部'), findsOneWidget);
    for (final cat in _kFourteenCategories) {
      expect(_label(cat.label), findsOneWidget, reason: '分类「${cat.label}」未展示在一屏内');
    }

    // 选中某个分类应正常过滤（抽查一个）
    await tester.tap(_label('饰品贵重'));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is Text && w.data == '饰品贵重'), findsOneWidget);
  });
}
