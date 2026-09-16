import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'generated/item.freezed.dart';
part 'generated/item.g.dart';

@freezed
abstract class Item with _$Item {
  const Item._();

  const factory Item({
    required String id,
    required String name,
    @Default('未知') String location,
    @Default('safe') String status,
    @Default('') String categoryKey,
    /// 所属房间：物品可直接归属房间（cabinetId/slotId 为 null），
    /// 也可经 cabinetId/slotId 间接归属——三种情况下 roomId 都有值。
    String? roomId,
    String? cabinetId,
    String? slotId,
    @Default([]) List<String> photos,
    /// 到期日：食品/药品/耗材等有保质期的物品才有值
    DateTime? expiryDate,
    @Default('') String note,
    /// 登记时间：物品入库时按系统时间自动录入，同时作为「新增时间」排序依据
    required DateTime createdAt,
  }) = _Item;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  factory Item.create({
    required String name,
    String location = '未知',
    String status = 'safe',
    String categoryKey = '',
    String? roomId,
    String? cabinetId,
    String? slotId,
    List<String> photos = const [],
    DateTime? expiryDate,
    String note = '',
    DateTime? createdAt,
  }) {
    return Item(
      id: const Uuid().v4(),
      name: name,
      location: location,
      status: status,
      categoryKey: categoryKey,
      roomId: roomId,
      cabinetId: cabinetId,
      slotId: slotId,
      photos: photos,
      expiryDate: expiryDate,
      note: note,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
