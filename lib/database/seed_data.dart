part of 'database.dart';

/// 种子数据 —— 仅在数据库首次创建时插入。
///
/// 包含：
/// - 14 个内置分类（isBuiltIn = true）
/// - 2 项默认用户设置（昵称、头像）
/// - 3 个默认房间（卧室、厨房、客厅）
///
/// 注意：**不再预置任何柜体/格子**。
/// 收纳模型里房间可以独立存在（柜体数 = 0），物品也能直接放在房间内；
/// 自动生成的「主柜体 / 主区域」既不是用户创建的，又会让收纳位置选择器里
/// 全是同名占位项，因此 v5 起彻底不再写入（历史库由 v5 迁移清理）。
class SeedData {
  // ────────────────────────────────────────────────
  // 分类（内置，isBuiltIn = true）
  // ────────────────────────────────────────────────

  static List<CategoriesCompanion> get categories => [
    CategoriesCompanion.insert(
      id: 'digital',
      label: '数码电子',
      emoji: '📱',
      isBuiltIn: const Value(true),
      sortOrder: const Value(0),
    ),
    CategoriesCompanion.insert(
      id: 'appliance',
      label: '家电',
      emoji: '🔌',
      isBuiltIn: const Value(true),
      sortOrder: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: 'clothing',
      label: '衣物鞋包',
      emoji: '👔',
      isBuiltIn: const Value(true),
      sortOrder: const Value(2),
    ),
    CategoriesCompanion.insert(
      id: 'toiletry',
      label: '个人洗护',
      emoji: '🧼',
      isBuiltIn: const Value(true),
      sortOrder: const Value(3),
    ),
    CategoriesCompanion.insert(
      id: 'kitchen',
      label: '餐厨用品',
      emoji: '🍚',
      isBuiltIn: const Value(true),
      sortOrder: const Value(4),
    ),
    CategoriesCompanion.insert(
      id: 'home_living',
      label: '家居生活',
      emoji: '🏠',
      isBuiltIn: const Value(true),
      sortOrder: const Value(5),
    ),
    CategoriesCompanion.insert(
      id: 'sports',
      label: '运动户外',
      emoji: '🏋️',
      isBuiltIn: const Value(true),
      sortOrder: const Value(6),
    ),
    CategoriesCompanion.insert(
      id: 'books',
      label: '书籍',
      emoji: '📚',
      isBuiltIn: const Value(true),
      sortOrder: const Value(7),
    ),
    CategoriesCompanion.insert(
      id: 'stationery',
      label: '文具办公',
      emoji: '✏️',
      isBuiltIn: const Value(true),
      sortOrder: const Value(8),
    ),
    CategoriesCompanion.insert(
      id: 'toy',
      label: '玩具兴趣',
      emoji: '🧸',
      isBuiltIn: const Value(true),
      sortOrder: const Value(9),
    ),
    CategoriesCompanion.insert(
      id: 'tools',
      label: '工具五金',
      emoji: '🔧',
      isBuiltIn: const Value(true),
      sortOrder: const Value(10),
    ),
    CategoriesCompanion.insert(
      id: 'jewelry',
      label: '饰品贵重',
      emoji: '💍',
      isBuiltIn: const Value(true),
      sortOrder: const Value(11),
    ),
    CategoriesCompanion.insert(
      id: 'decoration',
      label: '家居装饰',
      emoji: '🖼️',
      isBuiltIn: const Value(true),
      sortOrder: const Value(12),
    ),
    CategoriesCompanion.insert(
      id: 'other',
      label: '其他',
      emoji: '📦',
      isBuiltIn: const Value(true),
      sortOrder: const Value(13),
    ),
  ];

  // ────────────────────────────────────────────────
  // 用户设置（默认值）
  // ────────────────────────────────────────────────

  static List<SettingsCompanion> get settings => [
    SettingsCompanion.insert(key: 'nickname', value: const Value('小橘')),
    SettingsCompanion.insert(key: 'avatar_emoji', value: const Value('🧑')),
  ];

  // ────────────────────────────────────────────────
  // 默认房间（3 个，不含任何柜体/格子）
  // ────────────────────────────────────────────────

  static List<RoomsCompanion> get defaultRooms => [
    RoomsCompanion.insert(
      id: 'room_bedroom',
      name: '卧室',
      emoji: '🛏️',
      color: 0xFFE8F5E9,
    ),
    RoomsCompanion.insert(
      id: 'room_kitchen',
      name: '厨房',
      emoji: '🍳',
      color: 0xFFFFD4D4,
    ),
    RoomsCompanion.insert(
      id: 'room_living',
      name: '客厅',
      emoji: '🛋️',
      color: 0xFFFFE8CC,
    ),
  ];

  // Items、ImportHistory 不再预置种子数据，首次安装后为空表。
  static List<ItemsCompanion> get items => [];
  static List<ImportHistoryCompanion> get importHistory => [];
}
