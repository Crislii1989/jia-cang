import 'dart:ui';

import 'package:drift/drift.dart' hide Column;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart' as db;
import '../models/storage.dart' as model;
import 'database_provider.dart';
import 'item_providers.dart';

part 'generated/storage_providers.g.dart';

// ─── Rooms ───────────────────────────────────────────

@riverpod
Future<List<model.Room>> rooms(Ref ref) async {
  // 依赖物品列表：物品增删改移后 itemsProvider 失效，触发本 provider 重建，
  // 从而实时刷新各房间物品数。
  ref.watch(itemsProvider);
  final dao = ref.watch(roomDaoProvider);
  final rows = await dao.getAllRooms();

  final result = <model.Room>[];
  for (final row in rows) {
    final cabinetCount = await dao.cabinetCount(row.id);
    final itemCount = await dao.itemCount(row.id);
    final directCount = await dao.directItemCount(row.id);
    result.add(
      model.Room(
        id: row.id,
        name: row.name,
        emoji: row.emoji,
        color: Color(row.color),
        items: itemCount,
        storageCount: cabinetCount,
        directItems: directCount,
      ),
    );
  }
  return result;
}

/// 新增房间
/// 使用 keepAlive 是因为：调用方（收纳页）只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。
@Riverpod(keepAlive: true)
class RoomActions extends _$RoomActions {
  @override
  Future<void> build() async {}

  Future<void> addRoom({
    required String id,
    required String name,
    required String emoji,
    required Color color,
  }) async {
    final dao = ref.read(roomDaoProvider);
    await dao.insertRoom(
      db.RoomsCompanion.insert(
        id: id,
        name: name,
        emoji: emoji,
        color: color.toARGB32(),
      ),
    );
    ref.invalidate(roomsProvider);
  }

  /// 更新房间
  Future<void> updateRoom({
    required String id,
    required String name,
    required String emoji,
  }) async {
    final dao = ref.read(roomDaoProvider);
    await dao.updateRoom(
      db.RoomsCompanion(id: Value(id), name: Value(name), emoji: Value(emoji)),
    );
    ref.invalidate(roomsProvider);
  }

  /// 删除房间（级联删除其下柜体/格子/物品）
  Future<void> deleteRoom(String id) async {
    final dao = ref.read(roomDaoProvider);
    await dao.deleteRoom(id);
    ref.invalidate(roomsProvider);
  }

  /// 删除前置检查：返回首个含物品的子单元信息，null 表示可删除。
  /// 遍历 房间 → 柜体 → 格子，定位最深层含物品的子单元以便精确提示。
  Future<DeletionBlocker?> checkRoomDeletion(String roomId) async {
    final roomDao = ref.read(roomDaoProvider);
    final cabinetDao = ref.read(cabinetDaoProvider);
    final slotDao = ref.read(slotDaoProvider);

    final room = await roomDao.getById(roomId);
    final roomName = room?.name ?? '';

    // 房间内直接存放的物品（不归属任何柜体）
    final directCount = await roomDao.directItemCount(roomId);
    if (directCount > 0) {
      return DeletionBlocker(path: '$roomName（散放在房间）', count: directCount);
    }

    final cabinets = await cabinetDao.getByRoom(roomId);
    for (final cab in cabinets) {
      final slots = await slotDao.getByCabinet(cab.id);
      for (final slot in slots) {
        final count = await slotDao.itemCount(slot.id);
        if (count > 0) {
          return DeletionBlocker(
            path: '$roomName / ${cab.name} / ${slot.name}',
            count: count,
          );
        }
      }
      // 无 slot 含物品，但仍有直接归属该柜体的主物品
      final cabCount = await cabinetDao.itemCount(cab.id);
      if (cabCount > 0) {
        return DeletionBlocker(
          path: '$roomName / ${cab.name}',
          count: cabCount,
        );
      }
    }
    return null;
  }
}

// ─── Cabinets ────────────────────────────────────────

@riverpod
Future<List<model.Cabinet>> cabinetsByRoom(Ref ref, String roomId) async {
  // 依赖物品列表：物品变化后实时刷新柜体物品数。
  ref.watch(itemsProvider);
  final dao = ref.watch(cabinetDaoProvider);
  final rows = await dao.getByRoom(roomId);

  final result = <model.Cabinet>[];
  for (final row in rows) {
    final itemCount = await dao.itemCount(row.id);
    result.add(
      model.Cabinet(
        id: row.id,
        name: row.name,
        emoji: row.emoji,
        color: Color(row.color),
        items: itemCount,
        hasPhoto: row.hasPhoto,
        photoPath: row.photoPath,
      ),
    );
  }
  return result;
}

/// 新增柜子
/// 使用 keepAlive 是因为：调用方只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。
@Riverpod(keepAlive: true)
class CabinetActions extends _$CabinetActions {
  @override
  Future<void> build() async {}

  Future<void> addCabinet({
    required String id,
    required String name,
    required String emoji,
    required Color color,
    required String roomId,
    String? photoPath,
  }) async {
    final dao = ref.read(cabinetDaoProvider);
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;
    await dao.insertCabinet(
      db.CabinetsCompanion.insert(
        id: id,
        name: name,
        emoji: emoji,
        color: color.toARGB32(),
        roomId: roomId,
        photoPath: photoPath != null ? Value(photoPath) : const Value.absent(),
        hasPhoto: hasPhoto ? const Value(true) : const Value.absent(),
      ),
    );
    ref.invalidate(cabinetsByRoomProvider(roomId));
    ref.invalidate(roomsProvider);
  }

  /// 更新柜体
  Future<void> updateCabinet({
    required String id,
    required String roomId,
    required String name,
    required String emoji,
  }) async {
    final dao = ref.read(cabinetDaoProvider);
    await dao.updateCabinet(
      db.CabinetsCompanion(
        id: Value(id),
        name: Value(name),
        emoji: Value(emoji),
      ),
    );
    ref.invalidate(cabinetsByRoomProvider(roomId));
    ref.invalidate(roomsProvider);
  }

  /// 删除柜体（级联删除其下格子/物品）
  Future<void> deleteCabinet(String id, String roomId) async {
    final dao = ref.read(cabinetDaoProvider);
    await dao.deleteCabinet(id);
    ref.invalidate(cabinetsByRoomProvider(roomId));
    ref.invalidate(roomsProvider);
  }

  /// 移动柜体到其他房间（仅改 roomId，柜体自身及格子内容不变）
  Future<void> moveCabinet({
    required String cabinetId,
    required String fromRoomId,
    required String toRoomId,
  }) async {
    if (fromRoomId == toRoomId) return;
    final dao = ref.read(cabinetDaoProvider);
    await dao.updateCabinet(
      db.CabinetsCompanion(
        id: Value(cabinetId),
        roomId: Value(toRoomId),
      ),
    );
    // 刷新新旧两个房间的柜体列表与全局房间统计
    ref.invalidate(cabinetsByRoomProvider(fromRoomId));
    ref.invalidate(cabinetsByRoomProvider(toRoomId));
    ref.invalidate(roomsProvider);
  }

  /// 删除前置检查：返回首个含物品的子单元信息，null 表示可删除。
  Future<DeletionBlocker?> checkCabinetDeletion(String cabinetId) async {
    final cabinetDao = ref.read(cabinetDaoProvider);
    final slotDao = ref.read(slotDaoProvider);

    final cab = await cabinetDao.getById(cabinetId);
    final cabName = cab?.name ?? '';
    final slots = await slotDao.getByCabinet(cabinetId);
    for (final slot in slots) {
      final count = await slotDao.itemCount(slot.id);
      if (count > 0) {
        return DeletionBlocker(path: '$cabName / ${slot.name}', count: count);
      }
    }
    // 无 slot 含物品，但仍有直接归属该柜体的主物品
    final cabCount = await cabinetDao.itemCount(cabinetId);
    if (cabCount > 0) {
      return DeletionBlocker(path: cabName, count: cabCount);
    }
    return null;
  }
}

// ─── Slots ───────────────────────────────────────────

@riverpod
Future<List<model.Slot>> slotsByCabinet(Ref ref, String cabinetId) async {
  // 依赖物品列表：物品变化后实时刷新格位物品数。
  ref.watch(itemsProvider);
  final dao = ref.watch(slotDaoProvider);
  final rows = await dao.getByCabinet(cabinetId);

  final result = <model.Slot>[];
  for (final row in rows) {
    final itemCount = await dao.itemCount(row.id);
    result.add(
      model.Slot(
        id: row.id,
        name: row.name,
        emoji: row.emoji,
        color: Color(row.color),
        items: itemCount,
      ),
    );
  }
  return result;
}

/// 新增格位
/// 使用 keepAlive 是因为：调用方只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。
@Riverpod(keepAlive: true)
class SlotActions extends _$SlotActions {
  @override
  Future<void> build() async {}

  Future<void> addSlot({
    required String id,
    required String name,
    required String emoji,
    required Color color,
    required String cabinetId,
  }) async {
    final dao = ref.read(slotDaoProvider);
    await dao.insertSlot(
      db.SlotsCompanion.insert(
        id: id,
        name: name,
        emoji: emoji,
        color: color.toARGB32(),
        cabinetId: cabinetId,
      ),
    );
    ref.invalidate(slotsByCabinetProvider(cabinetId));
    ref.invalidate(roomsProvider);
  }

  /// 更新格子
  Future<void> updateSlot({
    required String id,
    required String cabinetId,
    required String name,
    required String emoji,
  }) async {
    final dao = ref.read(slotDaoProvider);
    await dao.updateSlot(
      db.SlotsCompanion(
        id: Value(id),
        name: Value(name),
        emoji: Value(emoji),
      ),
    );
    ref.invalidate(slotsByCabinetProvider(cabinetId));
    ref.invalidate(roomsProvider);
  }

  /// 删除格子（级联删除其下物品）
  Future<void> deleteSlot(String id, String cabinetId) async {
    final dao = ref.read(slotDaoProvider);
    await dao.deleteSlot(id);
    ref.invalidate(slotsByCabinetProvider(cabinetId));
    ref.invalidate(roomsProvider);
  }

  /// 删除前置检查：返回含物品信息，null 表示可删除。
  Future<DeletionBlocker?> checkSlotDeletion(String slotId) async {
    final slotDao = ref.read(slotDaoProvider);
    final slot = await slotDao.getById(slotId);
    final slotName = slot?.name ?? '';
    final count = await slotDao.itemCount(slotId);
    if (count > 0) {
      return DeletionBlocker(path: slotName, count: count);
    }
    return null;
  }
}

// ─── 删除前置检查 ─────────────────────────────────────

/// 删除收纳单元的前置检查结果：非空表示存在阻塞，不可删除。
class DeletionBlocker {
  final String path; // 显示路径，如 "卧室 / 床头柜 / 第一层"
  final int count; // 该阻塞子单元中的物品数

  const DeletionBlocker({required this.path, required this.count});
}


// ─── 全局统计 ─────────────────────────────────────────

@riverpod
Future<Map<String, int>> storageStats(Ref ref) async {
  // 依赖 roomsProvider：房间/柜体/格子的增删改及物品变化都会使 roomsProvider 失效，
  // 从而触发本 provider 重建，保证顶部统计实时刷新。
  // roomsProvider 已为每个房间计算了 storageCount 与 items，直接复用避免重复查询 DAO。
  final rooms = await ref.watch(roomsProvider.future);
  int totalRooms = rooms.length;
  int totalCabinets = rooms.fold(0, (sum, r) => sum + r.storageCount);
  int totalItems = rooms.fold(0, (sum, r) => sum + r.items);

  return {'rooms': totalRooms, 'cabinets': totalCabinets, 'items': totalItems};
}

// ─── 收纳位置选择树（供新增/编辑物品选位置用） ─────────

/// 收纳位置节点（房间 / 柜体 / 格子）
///
/// 房间本身也是一个合法的收纳位置：物品可以只绑定 roomId 而不绑定 cabinetId。
class StorageLocationNode {
  final String id;
  final String name;
  final String emoji;
  final bool isRoom; // true = 房间本身（物品直接存放于房间）
  final bool isSlot; // false = 柜体, true = 格子
  final String roomId; // 所属房间 id（三种节点都有）
  final String? cabinetId; // 所属柜体 id（房间节点为 null）
  final String? cabinetName; // 所属柜体名（房间节点为 null）
  final String roomName; // 所属房间名

  const StorageLocationNode({
    required this.id,
    required this.name,
    required this.emoji,
    this.isRoom = false,
    required this.isSlot,
    required this.roomId,
    this.cabinetId,
    this.cabinetName,
    required this.roomName,
  });

  /// 存储用位置标签：写入 items.location，并在物品库/详情页作为位置文案展示。
  /// 房间 → "卧室"；柜体 → "卧室 / 衣柜"；格子 → "卧室 / 衣柜 / 上层"
  String get pathLabel {
    if (isRoom) return roomName;
    if (isSlot) return '$roomName / $cabinetName / $name';
    return '$roomName / $name';
  }

  /// 选择器里的副标题：说明这个节点代表什么收纳含义。
  /// 房间节点表示「直接放进房间、不指定柜体」，不额外说明很容易被误当成房间下的柜体。
  String get subLabel {
    if (isRoom) return '整个房间 · 不指定柜体';
    return pathLabel;
  }
}

/// 查询所有房间 + 柜体 + 格子，扁平化为节点列表（供选择器使用）
///
/// 节点按「房间 → 其下柜体 → 柜体下格子」的顺序生成，房间节点排在所属房间分组首位。
@riverpod
Future<List<StorageLocationNode>> storageLocationTree(Ref ref) async {
  final roomDao = ref.watch(roomDaoProvider);
  final cabinetDao = ref.watch(cabinetDaoProvider);
  final slotDao = ref.watch(slotDaoProvider);

  final rooms = await roomDao.getAllRooms();
  final nodes = <StorageLocationNode>[];

  for (final room in rooms) {
    // 房间本身：物品可直接存放于房间，不归属任何柜体
    nodes.add(
      StorageLocationNode(
        id: room.id,
        name: room.name,
        emoji: room.emoji,
        isRoom: true,
        isSlot: false,
        roomId: room.id,
        cabinetId: null,
        cabinetName: null,
        roomName: room.name,
      ),
    );

    final cabinets = await cabinetDao.getByRoom(room.id);
    for (final cab in cabinets) {
      // 柜体节点
      nodes.add(
        StorageLocationNode(
          id: cab.id,
          name: cab.name,
          emoji: cab.emoji,
          isSlot: false,
          roomId: room.id,
          cabinetId: cab.id,
          cabinetName: cab.name,
          roomName: room.name,
        ),
      );
      // 格子节点
      final slots = await slotDao.getByCabinet(cab.id);
      for (final slot in slots) {
        nodes.add(
          StorageLocationNode(
            id: slot.id,
            name: slot.name,
            emoji: slot.emoji,
            isSlot: true,
            roomId: room.id,
            cabinetId: cab.id,
            cabinetName: cab.name,
            roomName: room.name,
          ),
        );
      }
    }
  }
  return nodes;
}
