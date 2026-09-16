part of '../database.dart';

class Items extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get location => text().withDefault(const Constant('未知'))();
  TextColumn get status => text().withDefault(const Constant('safe'))();
  TextColumn get categoryKey => text().withDefault(const Constant(''))();
  // 所属房间：物品可直接归属房间（不指定柜体/格子），也可经柜体/格子间接归属。
  // 冗余存储而非每次 JOIN 柜体推导，使「房间物品数 / 房间内直接存放数」可单表统计。
  TextColumn get roomId => text().nullable()();
  TextColumn get cabinetId => text().nullable()();
  TextColumn get slotId => text().nullable()();
  // 照片路径列表（JSON 数组）。
  // 真机存本地文件绝对路径；Web 无文件系统，存 data URL（base64 内联）。
  TextColumn get photos => text().withDefault(const Constant('[]'))();
  // 到期日（可为空）：食品/药品等有保质期的物品才有值。
  // 历史库中的 brand 列采用「逻辑删除」保留但不再读写（见 database.dart 迁移注释）。
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  // 登记时间（自动记录，替代 purchaseDate，支撑「本周/本月新增」统计与排序）
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}
