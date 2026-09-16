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
      ),
    );
  }

  Future<int> countAll() async {
    final result = await customSelect(
      'SELECT COUNT(*) AS total FROM items',
    ).get();
    return result.first.read<int>('total');
  }
}
