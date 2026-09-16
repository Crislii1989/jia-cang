import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/daos/category_dao.dart';
import 'package:jia_cang/database/database.dart';

/// 回归测试：分类的物品计数 / 重挂必须按 `items.category_key` 匹配。
///
/// 背景：`items.category`（存中文名那一列）在 schema v3 的「逻辑删除」里已经从
/// 表定义移除 —— 老库里物理残留、全新安装的库里压根没有。早先这两条 SQL 按
/// `category` 查，结果新库直接 `no such column: category` 报错，
/// 老库则统计出偏小的数字。本测试在「当前 schema」上跑，正是新库那种情形。
void main() {
  late AppDatabase db;
  late CategoryDao dao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // DAO 是手动 new 出来的（见 lib/providers/database_provider.dart）
    dao = CategoryDao(db);
    // 建一张空表结构（onCreate 会顺带写入种子分类/房间）
    await db.customStatement('SELECT 1');
  });

  tearDown(() async => db.close());

  Future<void> addItem(String id, String name, String categoryKey) {
    return db.into(db.items).insert(ItemsCompanion.insert(
          id: id,
          name: name,
          categoryKey: Value(categoryKey),
        ));
  }

  test('itemCount 按 category_key 统计（不碰已移除的 category 列）', () async {
    await addItem('i1', '卷尺', 'sports');
    await addItem('i2', '哑铃', 'sports');
    await addItem('i3', '指甲刀', 'tools');

    expect(await dao.itemCount('sports'), 2);
    expect(await dao.itemCount('tools'), 1);
    expect(await dao.itemCount('digital'), 0);
  });

  test('unassignItems 把该分类下的物品改成未分类（空 key）', () async {
    await addItem('i1', '卷尺', 'sports');
    await addItem('i2', '哑铃', 'sports');
    await addItem('i3', '指甲刀', 'tools');

    final affected = await dao.unassignItems('sports');
    expect(affected, 2);
    expect(await dao.itemCount('sports'), 0);
    expect(await dao.itemCount('tools'), 1, reason: '别的分类不该被动到');

    final rows = await db.select(db.items).get();
    expect(rows.where((r) => r.categoryKey.isEmpty).length, 2);
  });

  test('allItemCounts 按 category_key 分组，且忽略未分类', () async {
    await addItem('i1', '卷尺', 'sports');
    await addItem('i2', '哑铃', 'sports');
    await addItem('i3', '指甲刀', 'tools');
    await addItem('i4', '杂物', '');

    final counts = await dao.allItemCounts();
    expect(counts['sports'], 2);
    expect(counts['tools'], 1);
    expect(counts.containsKey(''), isFalse);
  });
}
