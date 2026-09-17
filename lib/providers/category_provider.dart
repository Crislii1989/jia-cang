import 'package:drift/drift.dart' hide Column;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart' as db;
import '../daos/category_dao.dart';
import '../models/category.dart';
import '../models/category_item.dart';
import 'database_provider.dart';

part 'generated/category_provider.g.dart';

// ─── Provider ─────────────────────────────────────────

/// 物品库 tab 与新增物品页分类选择器共用的分类列表。
/// 派生自 [CategoryManager]（数据库分类，含内置系统分类与用户自定义分类）。
/// 用户在分类管理页的新增/编辑/删除会通过此 provider 实时反映到所有使用方。
@riverpod
List<Category> availableCategories(Ref ref) {
  final asyncDb = ref.watch(categoryManagerProvider);
  final dbCats = asyncDb.value ?? const <CategoryItem>[];
  // 数据库分类：id 作为 key（与物品 categoryKey 一致），label/emoji 来自数据库
  return [for (final c in dbCats) Category(c.id, c.label, emoji: c.emoji)];
}

@riverpod
class CategoryManager extends _$CategoryManager {
  @override
  Future<List<CategoryItem>> build() async {
    final dao = ref.watch(categoryDaoProvider);
    final rows = await dao.getAllCategories();
    return rows
        .map((r) => CategoryItem(
              id: r.id,
              label: r.label,
              emoji: r.emoji,
              isBuiltIn: r.isBuiltIn,
              sortOrder: r.sortOrder,
            ))
        .toList();
  }

  CategoryDao get _dao => ref.read(categoryDaoProvider);

  /// 新增分类
  Future<void> addCategory({
    required String label,
    required String emoji,
  }) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final nextOrder = await _dao.nextSortOrder();
    await _dao.insertCategory(db.CategoriesCompanion.insert(
      id: id,
      label: label,
      emoji: emoji,
      sortOrder: Value(nextOrder),
    ));
    ref.invalidateSelf();
  }

  /// 更新分类（标签、emoji）
  Future<void> updateCategory(
    String id, {
    String? label,
    String? emoji,
  }) async {
    final existing = await _dao.getById(id);
    if (existing == null) return;
    await _dao.updateCategory(existing.copyWith(
      label: label ?? existing.label,
      emoji: emoji ?? existing.emoji,
    ).toCompanion(false));
    ref.invalidateSelf();
  }

  /// 删除分类（同时将该分类下的物品改为「未分类」）
  ///
  /// 物品是通过 `category_key` 引用分类的，而 `category_key` 存的就是分类的
  /// **id**（见 [availableCategories] 把 `c.id` 当 key）。因此重挂/计数都必须用
  /// `id`；早先用 `label`（中文名）去匹配 `items.category`，在新库上会直接抛
  /// `no such column: category`。
  Future<void> deleteCategory(String id) async {
    final existing = await _dao.getById(id);
    if (existing == null) return;
    await _dao.unassignItems(existing.id);
    await _dao.deleteCategory(id);
    ref.invalidateSelf();
  }

  /// 重排自定义分类。
  ///
  /// [newIndex] 语义与 `ReorderableListView.onReorderItem` 一致：
  /// 已为「移除 oldIndex 处元素」调整过的最终插入位置，**不要再手动 -1**
  /// （此前 onReorder 时代的手动调整已随 API 迁移移除，重复调整会错位）。
  Future<void> reorderCustom(int oldIndex, int newIndex) async {
    final all = state.value ?? [];
    final customs = all.where((c) => !c.isBuiltIn).toList();

    final item = customs.removeAt(oldIndex);
    customs.insert(newIndex, item);

    // 从内置分类数量开始编号
    final builtInCount = all.where((c) => c.isBuiltIn).length;
    final Map<String, int> orderMap = {};
    for (int i = 0; i < customs.length; i++) {
      orderMap[customs[i].id] = builtInCount + i;
    }
    await _dao.updateSortOrder(orderMap);
    ref.invalidateSelf();
  }

  /// 统计某分类下的物品数量（入参为分类 id，即物品的 `categoryKey`）
  Future<int> itemCountForCategory(String categoryId) =>
      _dao.itemCount(categoryId);

  /// 获取所有分类的物品计数映射
  Future<Map<String, int>> allItemCounts() => _dao.allItemCounts();
}
