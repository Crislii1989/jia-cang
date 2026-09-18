import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

// 表定义（part files）
part 'tables/items_table.dart';
part 'tables/rooms_table.dart';
part 'tables/cabinets_table.dart';
part 'tables/slots_table.dart';
part 'tables/import_history_table.dart';
part 'tables/categories_table.dart';
part 'tables/settings_table.dart';

// 种子数据
part 'seed_data.dart';

// 代码生成
part 'generated/database.g.dart';

@DriftDatabase(
  tables: [
    Items,
    Rooms,
    Cabinets,
    Slots,
    ImportHistory,
    Categories,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 9;

  /// 本地数据库名。Web 端 drift 会以这个名字在 OPFS / IndexedDB 中保存
  /// 数据库文件，名字不一致会导致「清理本地数据」清错对象，因此统一在这里声明。
  static const String databaseName = 'jiacang';

  /// 首版种子数据自动创建的柜体 id（v5 起不再写入，并在 v5 迁移里清理历史库残留）。
  static const List<String> _seededCabinetIds = [
    'cab_bedroom_wardrobe',
    'cab_kitchen_upper',
    'cab_living_tvstand',
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedDefaultData();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // v2: 曾新增 items.isBorrowed（借出标记），后续 v3 已将其整体移除。
      // v3: 简化物品存储信息，移除 14 个字段 + 新增 createdAt（替代 purchaseDate）。
      //     出于 SQLite DROP COLUMN 在旧 Android 设备（< SQLite 3.35）不支持的考虑，
      //     采用「逻辑删除」：表定义中移除字段、代码不再读写，物理列保留在旧库中，
      //     不影响 drift 的正常读写（drift 只操作表定义中声明的列）。
      //     因此 v2/v3 均无需执行任何 DDL。
      // v4: items 新增 roomId —— 物品可直接归属房间，不必再挂到某个柜体上。
      if (from < 4) {
        await m.addColumn(items, items.roomId);
        // 回填：已有物品按其所属柜体反查房间 id
        await customStatement(
          'UPDATE items SET room_id = '
          '(SELECT room_id FROM cabinets WHERE cabinets.id = items.cabinet_id) '
          'WHERE room_id IS NULL AND cabinet_id IS NOT NULL',
        );
        // 清理历史「新增房间时自动创建」的默认柜体，使其中的物品改为直接归属房间
        await _dissolveCabinets(idLike: 'cabinet_%_default');
      }
      // v5: 清理首版种子数据自动创建的「主柜体 / 主区域」。
      //     这些柜体不是用户主动创建的，却会出现在房间与收纳位置选择器里，
      //     与「房间可独立存在、柜体由用户按需创建」的模型冲突。
      if (from < 5) {
        await _dissolveCabinets(ids: _seededCabinetIds);
        // 房间级物品的位置文案统一收敛为房间名（旧数据里是「卧室（房间内）」）
        await customStatement(
          'UPDATE items SET location = '
          '(SELECT name FROM rooms WHERE rooms.id = items.room_id) '
          'WHERE room_id IS NOT NULL '
          "AND (cabinet_id IS NULL OR cabinet_id = '')",
        );
      }
      // v6: items 新增 expiryDate（到期日），取代原来的 brand（品牌）。
      //     brand 同样是「逻辑删除」：表定义中移除、代码不再读写，物理列留在旧库中。
      if (from < 6) {
        await m.addColumn(items, items.expiryDate);
      }
      // v7: 精简内置分类，只保留生活中常见的家居物品分类。
      //     - 移除「钥匙」（并入收纳 storage）；
      //     - 将「护肤」合并为「洗护」（toiletry），覆盖洗护/美妆/护肤；
      //     - 修正「家电」图标（🏠 → 🔌）。
      // 先重映射引用旧分类的物品，再清理旧内置分类，最后用 seed 数据 upsert
      // （INSERT OR REPLACE）刷入新分类集合：新分类被插入、已有分类的图标/名称被
      // 更新，用户自建分类（is_built_in = 0）不受影响。
      if (from < 7) {
        // 1) 物品分类重映射
        await customStatement(
          "UPDATE items SET category_key = 'toiletry' WHERE category_key = 'skincare'",
        );
        await customStatement(
          "UPDATE items SET category_key = 'storage' WHERE category_key = 'keys'",
        );
        // 1b) 防御性清理：历史「品类模版」写入过的非实物虚拟分类
        //     （会员订阅 / 网卡流量 / 数字许可证 / 礼品卡）已随本次精简移除，
        //     若仍有物品引用，统一回退为「未分类」，避免显示成裸 id。
        await customStatement(
          "UPDATE items SET category_key = '' WHERE category_key IN "
          "('membership', 'sim_card', 'license', 'gift_card')",
        );
        // 2) 清理已移除的旧内置分类
        await customStatement(
          "DELETE FROM categories WHERE is_built_in = 1 AND id IN ('skincare', 'keys')",
        );
        // 3) upsert 新内置分类集合（修正图标/名称 + 插入新分类）
        await batch((b) {
          b.insertAll(
            categories,
            SeedData.categories,
            mode: InsertMode.insertOrReplace,
          );
        });
      }
      // v8: 内置分类调整为 14 个「用户定义清单」。
      //     - 「收纳 storage」移除，原属物品并入「家居生活 home_living」；
      //     - 新增「饰品贵重 jewelry」「家居装饰 decoration」「其他 other」；
      //     - 其余分类仅改名/换图标（数码→数码电子、洗护→个人洗护、厨房→餐厨用品、
      //       衣物→衣物鞋包、运动→运动户外、文具→文具办公、玩具→玩具兴趣、工具→工具五金）。
      //     沿用 v7 的三步模式：先重映射物品引用 → 清理移除的内置分类行 →
      //     upsert 新分类集合（改名/换图标 + 插入新增），用户自建分类不受影响。
      if (from < 8) {
        // 1) 物品分类重映射：收纳 → 家居生活
        await customStatement(
          "UPDATE items SET category_key = 'home_living' WHERE category_key = 'storage'",
        );
        // 2) 清理已移除的旧内置分类
        await customStatement(
          "DELETE FROM categories WHERE is_built_in = 1 AND id = 'storage'",
        );
        // 3) upsert 新内置分类集合（改名/换图标 + 插入新增分类）
        await batch((b) {
          b.insertAll(
            categories,
            SeedData.categories,
            mode: InsertMode.insertOrReplace,
          );
        });
      }
      // v9: items 新增 lastTouchedAt（最近接触时间）——「长期闲置」口径从
      //     「登记满 N 天」改为「N 天未接触」。历史数据回填为各自登记时间
      //     （迁移后行为与旧口径一致，之后由编辑/出借/移动等操作刷新）。
      if (from < 9) {
        await m.addColumn(items, items.lastTouchedAt);
        await customStatement(
          'UPDATE items SET last_touched_at = created_at',
        );
      }
    },
  );

  /// 清理不再需要的柜体（及它们的格子），其中若已有物品，
  /// 一并改为「房间内直接存放」（roomId 指向原房间、cabinetId/slotId 置空），
  /// 并同步把展示用的 location 改为房间名，避免出现指向已删除位置的文案。
  ///
  /// [ids] 精确匹配柜体 id；[idLike] 用 LIKE 模式匹配（用于历史自动创建的同族柜体）。
  ///
  /// 实现刻意**只用 `customStatement` 写语句、不读取任何查询结果**：
  /// 迁移是在数据库「打开过程中」执行的，此时 drift 的语句执行器尚处于初始化阶段，
  /// 需要拿到返回值的查询（`customSelect(...).get()`）会等待打开完成，
  /// 而打开又要等迁移结束，形成死锁 —— 于是数据库永远打不开、界面一直转圈。
  /// 因此这里把「先查出要清理的柜体、再逐个处理」改写为带子查询的单条 UPDATE/DELETE。
  Future<void> _dissolveCabinets({
    List<String> ids = const [],
    String? idLike,
  }) async {
    if (ids.isEmpty && idLike == null) return;

    final conditions = <String>[];
    final variables = <Variable<Object>>[];
    if (ids.isNotEmpty) {
      conditions.add('id IN (${List.filled(ids.length, '?').join(', ')})');
      variables.addAll(ids.map(Variable.withString));
    }
    if (idLike != null) {
      conditions.add('id LIKE ?');
      variables.add(Variable.withString(idLike));
    }
    final where = conditions.join(' OR ');
    // 待清理柜体 id 集合（作为子查询复用）
    final targetCabinets = 'SELECT id FROM cabinets WHERE $where';
    // 物品改挂房间时使用的房间 id：优先取物品自身 room_id，为空则回查其柜体
    const resolvedRoomId =
        'COALESCE(items.room_id, '
        '(SELECT room_id FROM cabinets WHERE cabinets.id = items.cabinet_id))';

    // 1) 把待清理柜体（含其格子）里的物品改为「房间内直接存放」
    await customStatement(
      'UPDATE items SET '
      'room_id = $resolvedRoomId, '
      'cabinet_id = NULL, '
      'slot_id = NULL, '
      'location = (SELECT name FROM rooms WHERE rooms.id = $resolvedRoomId) '
      'WHERE cabinet_id IN ($targetCabinets) '
      'OR slot_id IN (SELECT id FROM slots WHERE cabinet_id IN ($targetCabinets))',
      [...variables, ...variables, ...variables],
    );
    // 2) 删除这些柜体下的格子
    await customStatement(
      'DELETE FROM slots WHERE cabinet_id IN ($targetCabinets)',
      variables,
    );
    // 3) 删除这些柜体
    await customStatement('DELETE FROM cabinets WHERE $where', variables);
  }

  /// 首次安装时写入默认种子数据：
  /// - 14 个内置分类
  /// - 2 项默认用户设置
  /// - 3 个默认房间（不含柜体/格子，柜体由用户按需创建）
  ///
  /// 不预置任何物品（Items）或导入历史（ImportHistory）。
  Future<void> _seedDefaultData() async {
    await batch((b) {
      b.insertAll(categories, SeedData.categories);
      b.insertAll(settings, SeedData.settings);
      b.insertAll(rooms, SeedData.defaultRooms);
    });
  }

  static QueryExecutor _openConnection() {
    return DatabaseConnection.delayed(Future(() {
      return driftDatabase(
        name: databaseName,
        native: const DriftNativeOptions(
          databaseDirectory: getApplicationSupportDirectory,
        ),
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      ) as DatabaseConnection;
    }));
  }
}
