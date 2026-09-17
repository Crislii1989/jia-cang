import 'package:drift/drift.dart';
import '../database/database.dart';

part 'generated/item_dao.g.dart';

@DriftAccessor(tables: [Items])
class ItemDao extends DatabaseAccessor<AppDatabase> with _$ItemDaoMixin {
  ItemDao(super.db);

  Future<List<Item>> getAllItems() => select(items).get();

  Stream<List<Item>> watchAllItems() => select(items).watch();

  Future<Item?> getById(String id) =>
      (select(items)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Item?> watchById(String id) =>
      (select(items)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> insertItem(ItemsCompanion item) => into(items).insert(item);

  Future<bool> updateItem(ItemsCompanion item) => update(items).replace(item);

  Future<int> deleteItem(String id) =>
      (delete(items)..where((t) => t.id.equals(id))).go();

  /// 更新物品的收纳位置（房间/柜体/格子）
  ///
  /// [roomId] 为物品所属房间 —— 物品可以直接归属房间（此时 cabinetId/slotId 为 null）。
  /// 同时刷新 lastTouchedAt（移动位置算一次「接触」）。
  Future<int> updateLocation({
    required String id,
    String? roomId,
    String? cabinetId,
    String? slotId,
    required String locationLabel,
  }) {
    return (update(items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(
        roomId: Value(roomId),
        cabinetId: Value(cabinetId),
        slotId: Value(slotId),
        location: Value(locationLabel),
        lastTouchedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 批量修改物品状态（如闲置物品批量标记为「已用」），并刷新接触时间。
  /// 调用方需要事务包裹时自行包（ItemDao 无事务上下文）。
  Future<void> updateStatuses(
    List<String> ids, {
    required String status,
  }) async {
    if (ids.isEmpty) return;
    for (final id in ids) {
      await (update(items)..where((t) => t.id.equals(id))).write(
        ItemsCompanion(
          status: Value(status),
          lastTouchedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<int> countAll() async {
    final result = await customSelect(
      'SELECT COUNT(*) AS total FROM items',
    ).get();
    return result.first.read<int>('total');
  }
}
