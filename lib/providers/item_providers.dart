import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart' as db;
import '../daos/item_dao.dart';
import '../models/item.dart';
import 'database_provider.dart';

part 'generated/item_providers.g.dart';

/// 跨页面共享的"待选分类"——例如从分类管理页跳转到物品库时，传递需要选中的分类 key。
/// 读取方应用后应清空，避免下次进入时重复生效。
/// 使用 keepAlive 是因为：设置方（来源页）只用 ref.read 写入、不监听，
/// autoDispose 会在写入后立即销毁 provider，导致目标页 initState 读到 null。
@Riverpod(keepAlive: true)
class PendingCategory extends _$PendingCategory {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

/// 核心 Items Provider —— AsyncNotifier，从数据库读写
@riverpod
class Items extends _$Items {
  late ItemDao _dao;

  @override
  Future<List<Item>> build() async {
    _dao = ref.watch(itemDaoProvider);
    final rows = await _dao.getAllItems();
    return rows.map<Item>(toModel).toList();
  }

  Future<void> addItem(Item item) async {
    await _dao.insertItem(_toCompanion(item));
    ref.invalidateSelf();
  }

  /// 编辑模式下全量更新物品
  Future<void> updateItem(Item item) async {
    await _dao.updateItem(_toCompanion(item, forUpdate: true));
    ref.invalidateSelf();
  }

  Future<void> removeItem(String id) async {
    await _dao.deleteItem(id);
    ref.invalidateSelf();
  }

  /// 批量添加物品（订单导入用）
  Future<void> addItems(List<Item> newItems) async {
    final companions = newItems.map(_toCompanion).toList();
    await _dao.db.batch((b) {
      b.insertAll(_dao.items, companions);
    });
    ref.invalidateSelf();
  }

  /// 更新物品收纳位置（与收纳页面联动）
  Future<void> updateLocation({
    required String id,
    String? roomId,
    String? cabinetId,
    String? slotId,
    required String locationLabel,
  }) async {
    await _dao.updateLocation(
      id: id,
      roomId: roomId,
      cabinetId: cabinetId,
      slotId: slotId,
      locationLabel: locationLabel,
    );
    ref.invalidateSelf();
  }

  /// 批量迁移物品到新的收纳位置（供收纳页"批量迁移"使用）。
  ///
  /// 在单个事务内执行所有 updateLocation，任一失败回滚整批操作，
  /// 避免半成功状态（部分物品已迁移、部分仍在原位）。
  /// 完成后单次 invalidate，避免逐条更新引发多次重建。
  Future<void> migrateItems(
    List<String> ids, {
    String? roomId,
    String? cabinetId,
    String? slotId,
    required String locationLabel,
  }) async {
    if (ids.isEmpty) return;
    await _dao.db.transaction(() async {
      for (final id in ids) {
        await _dao.updateLocation(
          id: id,
          roomId: roomId,
          cabinetId: cabinetId,
          slotId: slotId,
          locationLabel: locationLabel,
        );
      }
    });
    ref.invalidateSelf();
  }

  /// 批量删除物品（供收纳页"批量删除"使用）。
  ///
  /// 在单个事务内执行所有 deleteItem，任一失败回滚整批操作，
  /// 避免半成功状态（部分物品已删、部分仍残留）。
  Future<void> removeItems(List<String> ids) async {
    if (ids.isEmpty) return;
    await _dao.db.transaction(() async {
      for (final id in ids) {
        await _dao.deleteItem(id);
      }
    });
    ref.invalidateSelf();
  }

  /// 将 drift 行记录转换为 Item 模型（公开方法，供备份恢复等场景使用）
  static Item toModel(db.Item row) => Item(
    id: row.id,
    name: row.name,
    location: row.location,
    status: row.status,
    categoryKey: row.categoryKey,
    roomId: row.roomId,
    cabinetId: row.cabinetId,
    slotId: row.slotId,
    photos: _decodeList(row.photos),
    expiryDate: row.expiryDate,
    note: row.note,
    createdAt: row.createdAt,
  );

  /// Item → drift Companion（insert/update 复用）
  static db.ItemsCompanion _toCompanion(Item item, {bool forUpdate = false}) {
    return db.ItemsCompanion(
      id: Value(item.id),
      name: Value(item.name),
      location: Value(item.location),
      status: Value(item.status),
      categoryKey: Value(item.categoryKey),
      roomId: Value(item.roomId),
      cabinetId: Value(item.cabinetId),
      slotId: Value(item.slotId),
      photos: Value(jsonEncode(item.photos)),
      expiryDate: Value(item.expiryDate),
      note: Value(item.note),
      createdAt: Value(item.createdAt),
    );
  }

  static List<String> _decodeList(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final l = jsonDecode(raw);
      if (l is List) return l.map((e) => e.toString()).toList();
    } catch (_) {}
    return const [];
  }
}

// ─── 派生 Providers ───────────────────────────────────

@riverpod
int itemCount(Ref ref) {
  return ref
      .watch(itemsProvider)
      .maybeWhen(data: (items) => items.length, orElse: () => 0);
}

@riverpod
List<Item> recentItems(Ref ref) {
  return ref
      .watch(itemsProvider)
      .maybeWhen(
        data: (items) {
          final sorted = [...items]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sorted;
        },
        orElse: () => [],
      );
}

/// 本周新增物品数量（周一 00:00 至今）
/// 数据口径：Items.createdAt >= 本周一，与 drift 表 created_at 字段一致。
@riverpod
int weeklyNewCount(Ref ref) {
  return ref
      .watch(itemsProvider)
      .maybeWhen(
        data: (items) {
          final now = DateTime.now();
          final monday = DateTime(
            now.year,
            now.month,
            now.day - (now.weekday - DateTime.monday),
          );
          return items.where((i) => !i.createdAt.isBefore(monday)).length;
        },
        orElse: () => 0,
      );
}

/// 本月新增物品数量（1 日 00:00 至今）
/// 数据口径：Items.createdAt >= 本月 1 日。
@riverpod
int monthlyNewCount(Ref ref) {
  return ref
      .watch(itemsProvider)
      .maybeWhen(
        data: (items) {
          final now = DateTime.now();
          final firstOfMonth = DateTime(now.year, now.month, 1);
          return items
              .where((i) => !i.createdAt.isBefore(firstOfMonth))
              .length;
        },
        orElse: () => 0,
      );
}

@riverpod
Item? itemById(Ref ref, String id) {
  return ref
      .watch(itemsProvider)
      .maybeWhen(
        data: (items) {
          try {
            return items.firstWhere((item) => item.id == id);
          } catch (_) {
            return null;
          }
        },
        orElse: () => null,
      );
}
