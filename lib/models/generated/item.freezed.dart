// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Item {

 String get id; String get name; String get location; String get status; String get categoryKey;/// 所属房间：物品可直接归属房间（cabinetId/slotId 为 null），
/// 也可经 cabinetId/slotId 间接归属——三种情况下 roomId 都有值。
 String? get roomId; String? get cabinetId; String? get slotId; List<String> get photos;/// 到期日：食品/药品/耗材等有保质期的物品才有值
 DateTime? get expiryDate; String get note;/// 登记时间：物品入库时按系统时间自动录入，同时作为「新增时间」排序依据
 DateTime get createdAt;
/// Create a copy of Item
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemCopyWith<Item> get copyWith => _$ItemCopyWithImpl<Item>(this as Item, _$identity);

  /// Serializes this Item to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Item&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.status, status) || other.status == status)&&(identical(other.categoryKey, categoryKey) || other.categoryKey == categoryKey)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.cabinetId, cabinetId) || other.cabinetId == cabinetId)&&(identical(other.slotId, slotId) || other.slotId == slotId)&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,location,status,categoryKey,roomId,cabinetId,slotId,const DeepCollectionEquality().hash(photos),expiryDate,note,createdAt);

@override
String toString() {
  return 'Item(id: $id, name: $name, location: $location, status: $status, categoryKey: $categoryKey, roomId: $roomId, cabinetId: $cabinetId, slotId: $slotId, photos: $photos, expiryDate: $expiryDate, note: $note, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ItemCopyWith<$Res>  {
  factory $ItemCopyWith(Item value, $Res Function(Item) _then) = _$ItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, String location, String status, String categoryKey, String? roomId, String? cabinetId, String? slotId, List<String> photos, DateTime? expiryDate, String note, DateTime createdAt
});




}
/// @nodoc
class _$ItemCopyWithImpl<$Res>
    implements $ItemCopyWith<$Res> {
  _$ItemCopyWithImpl(this._self, this._then);

  final Item _self;
  final $Res Function(Item) _then;

/// Create a copy of Item
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? location = null,Object? status = null,Object? categoryKey = null,Object? roomId = freezed,Object? cabinetId = freezed,Object? slotId = freezed,Object? photos = null,Object? expiryDate = freezed,Object? note = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,categoryKey: null == categoryKey ? _self.categoryKey : categoryKey // ignore: cast_nullable_to_non_nullable
as String,roomId: freezed == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String?,cabinetId: freezed == cabinetId ? _self.cabinetId : cabinetId // ignore: cast_nullable_to_non_nullable
as String?,slotId: freezed == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String?,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Item].
extension ItemPatterns on Item {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Item value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Item() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Item value)  $default,){
final _that = this;
switch (_that) {
case _Item():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Item value)?  $default,){
final _that = this;
switch (_that) {
case _Item() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String location,  String status,  String categoryKey,  String? roomId,  String? cabinetId,  String? slotId,  List<String> photos,  DateTime? expiryDate,  String note,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Item() when $default != null:
return $default(_that.id,_that.name,_that.location,_that.status,_that.categoryKey,_that.roomId,_that.cabinetId,_that.slotId,_that.photos,_that.expiryDate,_that.note,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String location,  String status,  String categoryKey,  String? roomId,  String? cabinetId,  String? slotId,  List<String> photos,  DateTime? expiryDate,  String note,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Item():
return $default(_that.id,_that.name,_that.location,_that.status,_that.categoryKey,_that.roomId,_that.cabinetId,_that.slotId,_that.photos,_that.expiryDate,_that.note,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String location,  String status,  String categoryKey,  String? roomId,  String? cabinetId,  String? slotId,  List<String> photos,  DateTime? expiryDate,  String note,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Item() when $default != null:
return $default(_that.id,_that.name,_that.location,_that.status,_that.categoryKey,_that.roomId,_that.cabinetId,_that.slotId,_that.photos,_that.expiryDate,_that.note,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Item extends Item {
  const _Item({required this.id, required this.name, this.location = '未知', this.status = 'safe', this.categoryKey = '', this.roomId, this.cabinetId, this.slotId, final  List<String> photos = const [], this.expiryDate, this.note = '', required this.createdAt}): _photos = photos,super._();
  factory _Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String location;
@override@JsonKey() final  String status;
@override@JsonKey() final  String categoryKey;
/// 所属房间：物品可直接归属房间（cabinetId/slotId 为 null），
/// 也可经 cabinetId/slotId 间接归属——三种情况下 roomId 都有值。
@override final  String? roomId;
@override final  String? cabinetId;
@override final  String? slotId;
 final  List<String> _photos;
@override@JsonKey() List<String> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

/// 到期日：食品/药品/耗材等有保质期的物品才有值
@override final  DateTime? expiryDate;
@override@JsonKey() final  String note;
/// 登记时间：物品入库时按系统时间自动录入，同时作为「新增时间」排序依据
@override final  DateTime createdAt;

/// Create a copy of Item
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemCopyWith<_Item> get copyWith => __$ItemCopyWithImpl<_Item>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Item&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location)&&(identical(other.status, status) || other.status == status)&&(identical(other.categoryKey, categoryKey) || other.categoryKey == categoryKey)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.cabinetId, cabinetId) || other.cabinetId == cabinetId)&&(identical(other.slotId, slotId) || other.slotId == slotId)&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,location,status,categoryKey,roomId,cabinetId,slotId,const DeepCollectionEquality().hash(_photos),expiryDate,note,createdAt);

@override
String toString() {
  return 'Item(id: $id, name: $name, location: $location, status: $status, categoryKey: $categoryKey, roomId: $roomId, cabinetId: $cabinetId, slotId: $slotId, photos: $photos, expiryDate: $expiryDate, note: $note, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ItemCopyWith<$Res> implements $ItemCopyWith<$Res> {
  factory _$ItemCopyWith(_Item value, $Res Function(_Item) _then) = __$ItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String location, String status, String categoryKey, String? roomId, String? cabinetId, String? slotId, List<String> photos, DateTime? expiryDate, String note, DateTime createdAt
});




}
/// @nodoc
class __$ItemCopyWithImpl<$Res>
    implements _$ItemCopyWith<$Res> {
  __$ItemCopyWithImpl(this._self, this._then);

  final _Item _self;
  final $Res Function(_Item) _then;

/// Create a copy of Item
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? location = null,Object? status = null,Object? categoryKey = null,Object? roomId = freezed,Object? cabinetId = freezed,Object? slotId = freezed,Object? photos = null,Object? expiryDate = freezed,Object? note = null,Object? createdAt = null,}) {
  return _then(_Item(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,categoryKey: null == categoryKey ? _self.categoryKey : categoryKey // ignore: cast_nullable_to_non_nullable
as String,roomId: freezed == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String?,cabinetId: freezed == cabinetId ? _self.cabinetId : cabinetId // ignore: cast_nullable_to_non_nullable
as String?,slotId: freezed == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String?,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
