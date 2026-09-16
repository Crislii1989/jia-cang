// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../item_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 跨页面共享的"待选分类"——例如从分类管理页跳转到物品库时，传递需要选中的分类 key。
/// 读取方应用后应清空，避免下次进入时重复生效。
/// 使用 keepAlive 是因为：设置方（来源页）只用 ref.read 写入、不监听，
/// autoDispose 会在写入后立即销毁 provider，导致目标页 initState 读到 null。

@ProviderFor(PendingCategory)
final pendingCategoryProvider = PendingCategoryProvider._();

/// 跨页面共享的"待选分类"——例如从分类管理页跳转到物品库时，传递需要选中的分类 key。
/// 读取方应用后应清空，避免下次进入时重复生效。
/// 使用 keepAlive 是因为：设置方（来源页）只用 ref.read 写入、不监听，
/// autoDispose 会在写入后立即销毁 provider，导致目标页 initState 读到 null。
final class PendingCategoryProvider
    extends $NotifierProvider<PendingCategory, String?> {
  /// 跨页面共享的"待选分类"——例如从分类管理页跳转到物品库时，传递需要选中的分类 key。
  /// 读取方应用后应清空，避免下次进入时重复生效。
  /// 使用 keepAlive 是因为：设置方（来源页）只用 ref.read 写入、不监听，
  /// autoDispose 会在写入后立即销毁 provider，导致目标页 initState 读到 null。
  PendingCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingCategoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingCategoryHash();

  @$internal
  @override
  PendingCategory create() => PendingCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pendingCategoryHash() => r'aeb0c963feb512833652ef08ed57dda83af77fe7';

/// 跨页面共享的"待选分类"——例如从分类管理页跳转到物品库时，传递需要选中的分类 key。
/// 读取方应用后应清空，避免下次进入时重复生效。
/// 使用 keepAlive 是因为：设置方（来源页）只用 ref.read 写入、不监听，
/// autoDispose 会在写入后立即销毁 provider，导致目标页 initState 读到 null。

abstract class _$PendingCategory extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 核心 Items Provider —— AsyncNotifier，从数据库读写

@ProviderFor(Items)
final itemsProvider = ItemsProvider._();

/// 核心 Items Provider —— AsyncNotifier，从数据库读写
final class ItemsProvider extends $AsyncNotifierProvider<Items, List<Item>> {
  /// 核心 Items Provider —— AsyncNotifier，从数据库读写
  ItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'itemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$itemsHash();

  @$internal
  @override
  Items create() => Items();
}

String _$itemsHash() => r'4342ffb075168583f68071bf85182ea191fd447d';

/// 核心 Items Provider —— AsyncNotifier，从数据库读写

abstract class _$Items extends $AsyncNotifier<List<Item>> {
  FutureOr<List<Item>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Item>>, List<Item>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Item>>, List<Item>>,
              AsyncValue<List<Item>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(itemCount)
final itemCountProvider = ItemCountProvider._();

final class ItemCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  ItemCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'itemCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$itemCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return itemCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$itemCountHash() => r'89f231c28384a6703b16bf73c1e5cbaefd1fb9c2';

@ProviderFor(recentItems)
final recentItemsProvider = RecentItemsProvider._();

final class RecentItemsProvider
    extends $FunctionalProvider<List<Item>, List<Item>, List<Item>>
    with $Provider<List<Item>> {
  RecentItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentItemsHash();

  @$internal
  @override
  $ProviderElement<List<Item>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Item> create(Ref ref) {
    return recentItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Item> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Item>>(value),
    );
  }
}

String _$recentItemsHash() => r'd340b9075ee76e8a654b9401eeaaf277dafa1b02';

/// 本周新增物品数量（周一 00:00 至今）
/// 数据口径：Items.createdAt >= 本周一，与 drift 表 created_at 字段一致。

@ProviderFor(weeklyNewCount)
final weeklyNewCountProvider = WeeklyNewCountProvider._();

/// 本周新增物品数量（周一 00:00 至今）
/// 数据口径：Items.createdAt >= 本周一，与 drift 表 created_at 字段一致。

final class WeeklyNewCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 本周新增物品数量（周一 00:00 至今）
  /// 数据口径：Items.createdAt >= 本周一，与 drift 表 created_at 字段一致。
  WeeklyNewCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyNewCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyNewCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return weeklyNewCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$weeklyNewCountHash() => r'afeb5661f8a4efc1156d479d810e4900e3168744';

/// 本月新增物品数量（1 日 00:00 至今）
/// 数据口径：Items.createdAt >= 本月 1 日。

@ProviderFor(monthlyNewCount)
final monthlyNewCountProvider = MonthlyNewCountProvider._();

/// 本月新增物品数量（1 日 00:00 至今）
/// 数据口径：Items.createdAt >= 本月 1 日。

final class MonthlyNewCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 本月新增物品数量（1 日 00:00 至今）
  /// 数据口径：Items.createdAt >= 本月 1 日。
  MonthlyNewCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyNewCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyNewCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return monthlyNewCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$monthlyNewCountHash() => r'c921bf9f96b952ce4af0ddcdb274946dc09e5311';

@ProviderFor(itemById)
final itemByIdProvider = ItemByIdFamily._();

final class ItemByIdProvider extends $FunctionalProvider<Item?, Item?, Item?>
    with $Provider<Item?> {
  ItemByIdProvider._({
    required ItemByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'itemByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$itemByIdHash();

  @override
  String toString() {
    return r'itemByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Item?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Item? create(Ref ref) {
    final argument = this.argument as String;
    return itemById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Item? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Item?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ItemByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$itemByIdHash() => r'35d593e24f1651ed030fda7d5e7b0f036f0f5d2b';

final class ItemByIdFamily extends $Family
    with $FunctionalFamilyOverride<Item?, String> {
  ItemByIdFamily._()
    : super(
        retry: null,
        name: r'itemByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ItemByIdProvider call(String id) =>
      ItemByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'itemByIdProvider';
}
