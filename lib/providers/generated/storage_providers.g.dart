// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../storage_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rooms)
final roomsProvider = RoomsProvider._();

final class RoomsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<model.Room>>,
          List<model.Room>,
          FutureOr<List<model.Room>>
        >
    with $FutureModifier<List<model.Room>>, $FutureProvider<List<model.Room>> {
  RoomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomsHash();

  @$internal
  @override
  $FutureProviderElement<List<model.Room>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<model.Room>> create(Ref ref) {
    return rooms(ref);
  }
}

String _$roomsHash() => r'dce600a99da9d66a52569f1aeafcf0b6d807abe3';

/// 新增房间
/// 使用 keepAlive 是因为：调用方（收纳页）只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。

@ProviderFor(RoomActions)
final roomActionsProvider = RoomActionsProvider._();

/// 新增房间
/// 使用 keepAlive 是因为：调用方（收纳页）只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。
final class RoomActionsProvider
    extends $AsyncNotifierProvider<RoomActions, void> {
  /// 新增房间
  /// 使用 keepAlive 是因为：调用方（收纳页）只用 ref.read(...notifier) 触发操作、不监听，
  /// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。
  RoomActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomActionsHash();

  @$internal
  @override
  RoomActions create() => RoomActions();
}

String _$roomActionsHash() => r'eaaa4475e25c6a84036e30b11459f95954c2bf25';

/// 新增房间
/// 使用 keepAlive 是因为：调用方（收纳页）只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。

abstract class _$RoomActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(cabinetsByRoom)
final cabinetsByRoomProvider = CabinetsByRoomFamily._();

final class CabinetsByRoomProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<model.Cabinet>>,
          List<model.Cabinet>,
          FutureOr<List<model.Cabinet>>
        >
    with
        $FutureModifier<List<model.Cabinet>>,
        $FutureProvider<List<model.Cabinet>> {
  CabinetsByRoomProvider._({
    required CabinetsByRoomFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cabinetsByRoomProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cabinetsByRoomHash();

  @override
  String toString() {
    return r'cabinetsByRoomProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<model.Cabinet>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<model.Cabinet>> create(Ref ref) {
    final argument = this.argument as String;
    return cabinetsByRoom(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CabinetsByRoomProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cabinetsByRoomHash() => r'22fa99dd67226293b1c7f9f9a1e6a236280b5003';

final class CabinetsByRoomFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<model.Cabinet>>, String> {
  CabinetsByRoomFamily._()
    : super(
        retry: null,
        name: r'cabinetsByRoomProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CabinetsByRoomProvider call(String roomId) =>
      CabinetsByRoomProvider._(argument: roomId, from: this);

  @override
  String toString() => r'cabinetsByRoomProvider';
}

/// 新增柜子
/// 使用 keepAlive 是因为：调用方只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。

@ProviderFor(CabinetActions)
final cabinetActionsProvider = CabinetActionsProvider._();

/// 新增柜子
/// 使用 keepAlive 是因为：调用方只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。
final class CabinetActionsProvider
    extends $AsyncNotifierProvider<CabinetActions, void> {
  /// 新增柜子
  /// 使用 keepAlive 是因为：调用方只用 ref.read(...notifier) 触发操作、不监听，
  /// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。
  CabinetActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cabinetActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cabinetActionsHash();

  @$internal
  @override
  CabinetActions create() => CabinetActions();
}

String _$cabinetActionsHash() => r'309ddcb7f81159b2ce98d5d3b6ff155b00cfaedf';

/// 新增柜子
/// 使用 keepAlive 是因为：调用方只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。

abstract class _$CabinetActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(slotsByCabinet)
final slotsByCabinetProvider = SlotsByCabinetFamily._();

final class SlotsByCabinetProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<model.Slot>>,
          List<model.Slot>,
          FutureOr<List<model.Slot>>
        >
    with $FutureModifier<List<model.Slot>>, $FutureProvider<List<model.Slot>> {
  SlotsByCabinetProvider._({
    required SlotsByCabinetFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'slotsByCabinetProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$slotsByCabinetHash();

  @override
  String toString() {
    return r'slotsByCabinetProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<model.Slot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<model.Slot>> create(Ref ref) {
    final argument = this.argument as String;
    return slotsByCabinet(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SlotsByCabinetProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$slotsByCabinetHash() => r'92170cbf11215c764d716cbd48be2bd32b3fb9c1';

final class SlotsByCabinetFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<model.Slot>>, String> {
  SlotsByCabinetFamily._()
    : super(
        retry: null,
        name: r'slotsByCabinetProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SlotsByCabinetProvider call(String cabinetId) =>
      SlotsByCabinetProvider._(argument: cabinetId, from: this);

  @override
  String toString() => r'slotsByCabinetProvider';
}

/// 新增格位
/// 使用 keepAlive 是因为：调用方只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。

@ProviderFor(SlotActions)
final slotActionsProvider = SlotActionsProvider._();

/// 新增格位
/// 使用 keepAlive 是因为：调用方只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。
final class SlotActionsProvider
    extends $AsyncNotifierProvider<SlotActions, void> {
  /// 新增格位
  /// 使用 keepAlive 是因为：调用方只用 ref.read(...notifier) 触发操作、不监听，
  /// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。
  SlotActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slotActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slotActionsHash();

  @$internal
  @override
  SlotActions create() => SlotActions();
}

String _$slotActionsHash() => r'37461c6472b14441c27766c1b08f7826bfd07e5f';

/// 新增格位
/// 使用 keepAlive 是因为：调用方只用 ref.read(...notifier) 触发操作、不监听，
/// autoDispose 会在异步操作 await 期间销毁 provider，导致后续 ref.invalidate 抛 UnmountedRefException。

abstract class _$SlotActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(storageStats)
final storageStatsProvider = StorageStatsProvider._();

final class StorageStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          FutureOr<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  StorageStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageStatsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    return storageStats(ref);
  }
}

String _$storageStatsHash() => r'9018d51b74b935f946921209de4a76a8872d68a4';

/// 查询所有房间 + 柜体 + 格子，扁平化为节点列表（供选择器使用）
///
/// 节点按「房间 → 其下柜体 → 柜体下格子」的顺序生成，房间节点排在所属房间分组首位。

@ProviderFor(storageLocationTree)
final storageLocationTreeProvider = StorageLocationTreeProvider._();

/// 查询所有房间 + 柜体 + 格子，扁平化为节点列表（供选择器使用）
///
/// 节点按「房间 → 其下柜体 → 柜体下格子」的顺序生成，房间节点排在所属房间分组首位。

final class StorageLocationTreeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StorageLocationNode>>,
          List<StorageLocationNode>,
          FutureOr<List<StorageLocationNode>>
        >
    with
        $FutureModifier<List<StorageLocationNode>>,
        $FutureProvider<List<StorageLocationNode>> {
  /// 查询所有房间 + 柜体 + 格子，扁平化为节点列表（供选择器使用）
  ///
  /// 节点按「房间 → 其下柜体 → 柜体下格子」的顺序生成，房间节点排在所属房间分组首位。
  StorageLocationTreeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageLocationTreeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageLocationTreeHash();

  @$internal
  @override
  $FutureProviderElement<List<StorageLocationNode>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StorageLocationNode>> create(Ref ref) {
    return storageLocationTree(ref);
  }
}

String _$storageLocationTreeHash() =>
    r'6c731f983f4f9425efcaeb4664943f813a2c2ece';
