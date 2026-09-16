import 'dart:ui';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'color_converter.dart';

part 'generated/storage.freezed.dart';
part 'generated/storage.g.dart';

@freezed
abstract class Room with _$Room {
  const factory Room({
    required String id,
    required String name,
    required String emoji,
    @ColorConverter() required Color color,
    required int items,
    required int storageCount,
    /// 房间内「直接存放」的物品数：归属房间但不归属任何柜体/格子。
    @Default(0) int directItems,
  }) = _Room;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}

@freezed
abstract class Cabinet with _$Cabinet {
  const factory Cabinet({
    required String id,
    required String name,
    required String emoji,
    @ColorConverter() required Color color,
    required int items,
    required bool hasPhoto,
    String? photoPath,
  }) = _Cabinet;

  factory Cabinet.fromJson(Map<String, dynamic> json) =>
      _$CabinetFromJson(json);
}

@freezed
abstract class Slot with _$Slot {
  const factory Slot({
    required String id,
    required String name,
    required String emoji,
    @ColorConverter() required Color color,
    required int items,
  }) = _Slot;

  factory Slot.fromJson(Map<String, dynamic> json) => _$SlotFromJson(json);
}
