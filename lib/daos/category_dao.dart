import 'package:drift/drift.dart';
import '../database/database.dart';

part 'generated/category_dao.g.dart';

@DriftAccessor(tables: [Categories, Items])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// 获取所有分类，按 sortOrder 排序
  Future<List<Category>> getAllCategories() =>
      (select(categories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  /// 监听分类变化
  Stream<List<Category>> watchAllCategories() =>
      (select(categories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  /// 按 id 获取
  Future<Category?> getById(String id) =>
      (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 新增分类
  Future<int> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  /// 更新分类
  Future<bool> updateCategory(CategoriesCompanion category) =>
      update(categories).replace(category);

  /// 删除分类
  Future<int> deleteCategory(String id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();

  /// 批量更新 sortOrder（用于拖拽排序后一次性写入）
  Future<void> updateSortOrder(Map<String, int> idToOrder) async {
    await batch((b) {
      idToOrder.forEach((id, order) {
        b.update(
          categories,
          CategoriesCompanion(sortOrder: Value(order)),
          where: (t) => t.id.equals(id),
        );
      });
    });
  }

  /// 获取下一个 sortOrder（自定义分类追加用）
  Future<int> nextSortOrder() async {
    final result = await customSelect(
      'SELECT COALESCE(MAX(sort_order), 0) + 1 AS next_order FROM categories',
    ).get();
    return result.first.read<int>('next_order');
  }

  /// 统计某分类（按 **categoryKey**，即分类的 id）下的物品数量。
  ///
  /// 注意：这里**必须**匹配 `category_key`，不能匹配 `category`。
  /// `items.category`（存中文名）在 schema v3 的「逻辑删除」里已从表定义移除：
  /// 老库里物理列还残留着，但 v3 起的代码再没写过它（新物品该列只剩建表默认值
  /// 「未分类」）；全新安装的库更是连这一列都没有。按 `category` 查询的后果是
  /// 新库直接 `no such column: category` 报错、老库则统计出偏小的数字。
  Future<int> itemCount(String categoryKey) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS total FROM items WHERE category_key = ?',
      variables: [Variable.withString(categoryKey)],
    ).get();
    return result.first.read<int>('total');
  }

  /// 获取所有分类的物品计数（key = categoryKey）
  Future<Map<String, int>> allItemCounts() async {
    final result = await customSelect(
      'SELECT category_key, COUNT(*) AS total FROM items '
      "WHERE category_key <> '' GROUP BY category_key",
    ).get();
    return {
      for (final row in result)
        row.read<String>('category_key'): row.read<int>('total'),
    };
  }

  /// 将某分类下的所有物品改为「未分类」（删除分类前调用）。
  ///
  /// 「未分类」在本项目里的表示就是 `category_key` 置空字符串
  /// （`categoryLabelOf` 遇到空 key 会显示「未分类」），因此只清这一列即可。
  /// 老库残留的 `category` 列不再读写，与 v3 起的做法保持一致。
  Future<int> unassignItems(String categoryKey) async {
    return await customUpdate(
      'UPDATE items SET category_key = ? WHERE category_key = ?',
      variables: [
        Variable.withString(''),
        Variable.withString(categoryKey),
      ],
      updates: {items},
    );
  }
}
