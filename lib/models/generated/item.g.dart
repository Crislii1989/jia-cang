// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Item _$ItemFromJson(Map<String, dynamic> json) => _Item(
  id: json['id'] as String,
  name: json['name'] as String,
  location: json['location'] as String? ?? '未知',
  status: json['status'] as String? ?? 'safe',
  categoryKey: json['categoryKey'] as String? ?? '',
  roomId: json['roomId'] as String?,
  cabinetId: json['cabinetId'] as String?,
  slotId: json['slotId'] as String?,
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  expiryDate: json['expiryDate'] == null
      ? null
      : DateTime.parse(json['expiryDate'] as String),
  note: json['note'] as String? ?? '',
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ItemToJson(_Item instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'location': instance.location,
  'status': instance.status,
  'categoryKey': instance.categoryKey,
  'roomId': instance.roomId,
  'cabinetId': instance.cabinetId,
  'slotId': instance.slotId,
  'photos': instance.photos,
  'expiryDate': instance.expiryDate?.toIso8601String(),
  'note': instance.note,
  'createdAt': instance.createdAt.toIso8601String(),
};
