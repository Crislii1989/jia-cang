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

/// 首页统计卡 → 物品库 的预筛请求（消费方应用后应置回 null）。

@ProviderFor(PendingInventoryFilterRequest)
final pendingInventoryFilterRequestProvider =
    PendingInventoryFilterRequestProvider._();

/// 首页统计卡 → 物品库 的预筛请求（消费方应用后应置回 null）。
final class PendingInventoryFilterRequestProvider
    extends
        $NotifierProvider<
          PendingInventoryFilterRequest,
          PendingInventoryFilter?
        > {
  /// 首页统计卡 → 物品库 的预筛请求（消费方应用后应置回 null）。
  PendingInventoryFilterRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingInventoryFilterRequestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingInventoryFilterRequestHash();

  @$internal
  @override
  PendingInventoryFilterRequest create() => PendingInventoryFilterRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingInventoryFilter? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingInventoryFilter?>(value),
    );
  }
}

String _$pendingInventoryFilterRequestHash() =>
    r'd21ac0276a9de6264e1da711b9dc5d92809fc9d1';

/// 首页统计卡 → 物品库 的预筛请求（消费方应用后应置回 null）。

abstract class _$PendingInventoryFilterRequest
    extends $Notifier<PendingInventoryFilter?> {
  PendingInventoryFilter? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<PendingInventoryFilter?, PendingInventoryFilter?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PendingInventoryFilter?, PendingInventoryFilter?>,
              PendingInventoryFilter?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 首页搜索胶囊 → 物品库 的「自动聚焦搜索框」请求（消费方应用后应置回 false）。

@ProviderFor(PendingSearchFocus)
final pendingSearchFocusProvider = PendingSearchFocusProvider._();

/// 首页搜索胶囊 → 物品库 的「自动聚焦搜索框」请求（消费方应用后应置回 false）。
final class PendingSearchFocusProvider
    extends $NotifierProvider<PendingSearchFocus, bool> {
  /// 首页搜索胶囊 → 物品库 的「自动聚焦搜索框」请求（消费方应用后应置回 false）。
  PendingSearchFocusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSearchFocusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSearchFocusHash();

  @$internal
  @override
  PendingSearchFocus create() => PendingSearchFocus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$pendingSearchFocusHash() =>
    r'fd0d23ec55ab1a83e5425fde0e037c8a72fa2b1c';

/// 首页搜索胶囊 → 物品库 的「自动聚焦搜索框」请求（消费方应用后应置回 false）。

abstract class _$PendingSearchFocus extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
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

String _$itemsHash() => r'48dd757dac015bfe08406b386ab305f74bc2d6d3';

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

/// 已过期的物品（到期日早于今天，且未标记为已用完/已丢失）

@ProviderFor(overdueItems)
final overdueItemsProvider = OverdueItemsProvider._();

/// 已过期的物品（到期日早于今天，且未标记为已用完/已丢失）

final class OverdueItemsProvider
    extends $FunctionalProvider<List<Item>, List<Item>, List<Item>>
    with $Provider<List<Item>> {
  /// 已过期的物品（到期日早于今天，且未标记为已用完/已丢失）
  OverdueItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overdueItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overdueItemsHash();

  @$internal
  @override
  $ProviderElement<List<Item>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Item> create(Ref ref) {
    return overdueItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Item> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Item>>(value),
    );
  }
}

String _$overdueItemsHash() => r'750dd36ebe2a43001fe298d889d8b6256520bae8';

/// 即将到期的物品（今天起 [kExpiringSoonDays] 天内到期，含今天，不含已过期）

@ProviderFor(expiringSoonItems)
final expiringSoonItemsProvider = ExpiringSoonItemsProvider._();

/// 即将到期的物品（今天起 [kExpiringSoonDays] 天内到期，含今天，不含已过期）

final class ExpiringSoonItemsProvider
    extends $FunctionalProvider<List<Item>, List<Item>, List<Item>>
    with $Provider<List<Item>> {
  /// 即将到期的物品（今天起 [kExpiringSoonDays] 天内到期，含今天，不含已过期）
  ExpiringSoonItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expiringSoonItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expiringSoonItemsHash();

  @$internal
  @override
  $ProviderElement<List<Item>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Item> create(Ref ref) {
    return expiringSoonItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Item> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Item>>(value),
    );
  }
}

String _$expiringSoonItemsHash() => r'a3bb82514558302aaf28885b2ec8616caa13d694';

/// 长期闲置的物品（在库 + 最近接触已满 [kIdleDays] 天）

@ProviderFor(idleItems)
final idleItemsProvider = IdleItemsProvider._();

/// 长期闲置的物品（在库 + 最近接触已满 [kIdleDays] 天）

final class IdleItemsProvider
    extends $FunctionalProvider<List<Item>, List<Item>, List<Item>>
    with $Provider<List<Item>> {
  /// 长期闲置的物品（在库 + 最近接触已满 [kIdleDays] 天）
  IdleItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'idleItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$idleItemsHash();

  @$internal
  @override
  $ProviderElement<List<Item>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Item> create(Ref ref) {
    return idleItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Item> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Item>>(value),
    );
  }
}

String _$idleItemsHash() => r'0e5f96eb8231236a0fcff9fb3b429d2569a436e6';

/// 概览：即将到期数量

@ProviderFor(expiringSoonCount)
final expiringSoonCountProvider = ExpiringSoonCountProvider._();

/// 概览：即将到期数量

final class ExpiringSoonCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 概览：即将到期数量
  ExpiringSoonCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expiringSoonCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expiringSoonCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return expiringSoonCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$expiringSoonCountHash() => r'ce975d7195f3f39af96f22097422244d47e59c73';

/// 概览：出借中数量

@ProviderFor(lentCount)
final lentCountProvider = LentCountProvider._();

/// 概览：出借中数量

final class LentCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 概览：出借中数量
  LentCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lentCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lentCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return lentCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$lentCountHash() => r'9f01a51a3448a824eb5b3f9751eb7c28dca468bd';

/// 概览：长期闲置数量

@ProviderFor(idleCount)
final idleCountProvider = IdleCountProvider._();

/// 概览：长期闲置数量

final class IdleCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 概览：长期闲置数量
  IdleCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'idleCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$idleCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return idleCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$idleCountHash() => r'13f767fe2ddc62e15ffb683071d7d89a233a9a3e';

/// 首页「提醒」条目：已逾期 → 即将到期 → 长期闲置，按紧急度排序，
/// 每类内部按「更紧急/更久」优先，最多返回 [_maxHomeReminders] 条（首页只展示前几条）。

@ProviderFor(homeReminders)
final homeRemindersProvider = HomeRemindersProvider._();

/// 首页「提醒」条目：已逾期 → 即将到期 → 长期闲置，按紧急度排序，
/// 每类内部按「更紧急/更久」优先，最多返回 [_maxHomeReminders] 条（首页只展示前几条）。

final class HomeRemindersProvider
    extends
        $FunctionalProvider<
          List<ReminderEntry>,
          List<ReminderEntry>,
          List<ReminderEntry>
        >
    with $Provider<List<ReminderEntry>> {
  /// 首页「提醒」条目：已逾期 → 即将到期 → 长期闲置，按紧急度排序，
  /// 每类内部按「更紧急/更久」优先，最多返回 [_maxHomeReminders] 条（首页只展示前几条）。
  HomeRemindersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRemindersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRemindersHash();

  @$internal
  @override
  $ProviderElement<List<ReminderEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ReminderEntry> create(Ref ref) {
    return homeReminders(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ReminderEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ReminderEntry>>(value),
    );
  }
}

String _$homeRemindersHash() => r'4264d8ba3054a4023539969ba3a06a9293fb68b0';
