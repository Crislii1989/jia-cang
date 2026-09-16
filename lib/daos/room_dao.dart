import 'package:drift/drift.dart';
import '../database/database.dart';

part 'generated/room_dao.g.dart';

@DriftAccessor(tables: [Rooms])
class RoomDao extends DatabaseAccessor<AppDatabase> with _$RoomDaoMixin {
  RoomDao(super.db);

  Future<List<Room>> getAllRooms() => select(rooms).get();

  Stream<List<Room>> watchAllRooms() => select(rooms).watch();

  Future<Room?> getById(String id) =>
      (select(rooms)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertRoom(RoomsCompanion room) => into(rooms).insert(room);

  Future<bool> updateRoom(RoomsCompanion room) async {
    final rows = await (update(rooms)..where((t) => t.id.equals(room.id.value)))
        .write(room);
    return rows > 0;
  }

  Future<int> deleteRoom(String id) =>
      (delete(rooms)..where((t) => t.id.equals(id))).go();

  /// 统计某个房间下的柜子数量
  Future<int> cabinetCount(String roomId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS total FROM cabinets WHERE room_id = ?',
      variables: [Variable.withString(roomId)],
    ).get();
    return result.first.read<int>('total');
  }

  /// 统计某个房间下的物品总数（主物品 items）
  ///
  /// 口径：直接归属房间的物品（room_id）+ 经其下柜体/格子间接归属的物品。
  /// room_id 为空属于历史脏数据（v4 迁移前创建且从未更新过位置），
  /// 用 cabinet_id 子查询兜底，避免这部分物品在统计里凭空消失。
  Future<int> itemCount(String roomId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS total FROM items WHERE room_id = ? '
      'OR (room_id IS NULL AND cabinet_id IN '
      '(SELECT id FROM cabinets WHERE room_id = ?))',
      variables: [Variable.withString(roomId), Variable.withString(roomId)],
    ).get();
    return result.first.read<int>('total');
  }

  /// 统计房间内「直接存放」的物品数量：归属房间但不归属任何柜体/格子。
  Future<int> directItemCount(String roomId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS total FROM items '
      'WHERE room_id = ? AND cabinet_id IS NULL',
      variables: [Variable.withString(roomId)],
    ).get();
    return result.first.read<int>('total');
  }


}
