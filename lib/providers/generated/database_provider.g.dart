// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 数据库实例 Provider
///
/// 必须 keepAlive：数据库连接的生命周期应与整个 App 一致，而不是跟着页面走。
/// 若使用 autoDispose，当某个页面（如收纳页按浏览维度分支 watch 不同 provider）
/// 切换视图导致依赖链短暂失效时，本 provider 会被销毁并 close()，随后又被重建、
/// 重新打开同一个数据库文件。在 Web 端（drift 降级到 sharedIndexedDb 时尤其明显）
/// 「上一个连接尚未完全释放就重开」会互相锁死，所有查询永久挂起，
/// 界面表现为一直转圈、写入成功也不刷新。

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// 数据库实例 Provider
///
/// 必须 keepAlive：数据库连接的生命周期应与整个 App 一致，而不是跟着页面走。
/// 若使用 autoDispose，当某个页面（如收纳页按浏览维度分支 watch 不同 provider）
/// 切换视图导致依赖链短暂失效时，本 provider 会被销毁并 close()，随后又被重建、
/// 重新打开同一个数据库文件。在 Web 端（drift 降级到 sharedIndexedDb 时尤其明显）
/// 「上一个连接尚未完全释放就重开」会互相锁死，所有查询永久挂起，
/// 界面表现为一直转圈、写入成功也不刷新。

final class DatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// 数据库实例 Provider
  ///
  /// 必须 keepAlive：数据库连接的生命周期应与整个 App 一致，而不是跟着页面走。
  /// 若使用 autoDispose，当某个页面（如收纳页按浏览维度分支 watch 不同 provider）
  /// 切换视图导致依赖链短暂失效时，本 provider 会被销毁并 close()，随后又被重建、
  /// 重新打开同一个数据库文件。在 Web 端（drift 降级到 sharedIndexedDb 时尤其明显）
  /// 「上一个连接尚未完全释放就重开」会互相锁死，所有查询永久挂起，
  /// 界面表现为一直转圈、写入成功也不刷新。
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$databaseHash() => r'6df78b735a49938a882122e5473bc420d002fb08';

/// 数据库可用性探测（带超时）。
///
/// 存在的意义是「把静默挂起变成看得见的问题」：
/// 一旦 Web 端 drift 的连接挂起（多标签页抢同一份 IndexedDB、
/// 或历史版本遗留的悬挂连接），所有查询都不会返回也不报错 ——
/// 界面永远转圈、点新增没有任何反应，用户完全无从判断。
/// 启动闸门 DbGate 依赖本 provider，超时后给出重连 / 重建的入口。

@ProviderFor(databaseReady)
final databaseReadyProvider = DatabaseReadyProvider._();

/// 数据库可用性探测（带超时）。
///
/// 存在的意义是「把静默挂起变成看得见的问题」：
/// 一旦 Web 端 drift 的连接挂起（多标签页抢同一份 IndexedDB、
/// 或历史版本遗留的悬挂连接），所有查询都不会返回也不报错 ——
/// 界面永远转圈、点新增没有任何反应，用户完全无从判断。
/// 启动闸门 DbGate 依赖本 provider，超时后给出重连 / 重建的入口。

final class DatabaseReadyProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// 数据库可用性探测（带超时）。
  ///
  /// 存在的意义是「把静默挂起变成看得见的问题」：
  /// 一旦 Web 端 drift 的连接挂起（多标签页抢同一份 IndexedDB、
  /// 或历史版本遗留的悬挂连接），所有查询都不会返回也不报错 ——
  /// 界面永远转圈、点新增没有任何反应，用户完全无从判断。
  /// 启动闸门 DbGate 依赖本 provider，超时后给出重连 / 重建的入口。
  DatabaseReadyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseReadyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseReadyHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return databaseReady(ref);
  }
}

String _$databaseReadyHash() => r'd26949c123dfc1aa0fccfe846e934efd4853baae';

/// 数据库异常时的恢复操作（供 DbGate 的出错界面调用）。

@ProviderFor(DatabaseRecovery)
final databaseRecoveryProvider = DatabaseRecoveryProvider._();

/// 数据库异常时的恢复操作（供 DbGate 的出错界面调用）。
final class DatabaseRecoveryProvider
    extends $AsyncNotifierProvider<DatabaseRecovery, void> {
  /// 数据库异常时的恢复操作（供 DbGate 的出错界面调用）。
  DatabaseRecoveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseRecoveryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseRecoveryHash();

  @$internal
  @override
  DatabaseRecovery create() => DatabaseRecovery();
}

String _$databaseRecoveryHash() => r'cf70067cabe048e5507f8a46d87988bdd459a688';

/// 数据库异常时的恢复操作（供 DbGate 的出错界面调用）。

abstract class _$DatabaseRecovery extends $AsyncNotifier<void> {
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

/// DAO Providers

@ProviderFor(itemDao)
final itemDaoProvider = ItemDaoProvider._();

/// DAO Providers

final class ItemDaoProvider
    extends $FunctionalProvider<ItemDao, ItemDao, ItemDao>
    with $Provider<ItemDao> {
  /// DAO Providers
  ItemDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'itemDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$itemDaoHash();

  @$internal
  @override
  $ProviderElement<ItemDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ItemDao create(Ref ref) {
    return itemDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ItemDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ItemDao>(value),
    );
  }
}

String _$itemDaoHash() => r'367ecb104815b072531e6886861952a0fe4ea447';

@ProviderFor(roomDao)
final roomDaoProvider = RoomDaoProvider._();

final class RoomDaoProvider
    extends $FunctionalProvider<RoomDao, RoomDao, RoomDao>
    with $Provider<RoomDao> {
  RoomDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomDaoHash();

  @$internal
  @override
  $ProviderElement<RoomDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RoomDao create(Ref ref) {
    return roomDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomDao>(value),
    );
  }
}

String _$roomDaoHash() => r'47de92928b067bf155950ea95c5a0bda91940d6c';

@ProviderFor(cabinetDao)
final cabinetDaoProvider = CabinetDaoProvider._();

final class CabinetDaoProvider
    extends $FunctionalProvider<CabinetDao, CabinetDao, CabinetDao>
    with $Provider<CabinetDao> {
  CabinetDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cabinetDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cabinetDaoHash();

  @$internal
  @override
  $ProviderElement<CabinetDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CabinetDao create(Ref ref) {
    return cabinetDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CabinetDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CabinetDao>(value),
    );
  }
}

String _$cabinetDaoHash() => r'fba7020f300a9f4e3b17de6c75146d8a8a03c5ee';

@ProviderFor(slotDao)
final slotDaoProvider = SlotDaoProvider._();

final class SlotDaoProvider
    extends $FunctionalProvider<SlotDao, SlotDao, SlotDao>
    with $Provider<SlotDao> {
  SlotDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slotDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slotDaoHash();

  @$internal
  @override
  $ProviderElement<SlotDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SlotDao create(Ref ref) {
    return slotDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SlotDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SlotDao>(value),
    );
  }
}

String _$slotDaoHash() => r'bbd02a177796147dc78fb3531db2e302790eaa6d';

@ProviderFor(importHistoryDao)
final importHistoryDaoProvider = ImportHistoryDaoProvider._();

final class ImportHistoryDaoProvider
    extends
        $FunctionalProvider<
          ImportHistoryDao,
          ImportHistoryDao,
          ImportHistoryDao
        >
    with $Provider<ImportHistoryDao> {
  ImportHistoryDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importHistoryDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importHistoryDaoHash();

  @$internal
  @override
  $ProviderElement<ImportHistoryDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImportHistoryDao create(Ref ref) {
    return importHistoryDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportHistoryDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportHistoryDao>(value),
    );
  }
}

String _$importHistoryDaoHash() => r'1e78d5621e767aca35ccd44767324c1516e2a331';

@ProviderFor(categoryDao)
final categoryDaoProvider = CategoryDaoProvider._();

final class CategoryDaoProvider
    extends $FunctionalProvider<CategoryDao, CategoryDao, CategoryDao>
    with $Provider<CategoryDao> {
  CategoryDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryDaoHash();

  @$internal
  @override
  $ProviderElement<CategoryDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CategoryDao create(Ref ref) {
    return categoryDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryDao>(value),
    );
  }
}

String _$categoryDaoHash() => r'b9320ecc692e08efff3d09ced42cba69f287275f';

@ProviderFor(settingsDao)
final settingsDaoProvider = SettingsDaoProvider._();

final class SettingsDaoProvider
    extends $FunctionalProvider<SettingsDao, SettingsDao, SettingsDao>
    with $Provider<SettingsDao> {
  SettingsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsDaoHash();

  @$internal
  @override
  $ProviderElement<SettingsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsDao create(Ref ref) {
    return settingsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsDao>(value),
    );
  }
}

String _$settingsDaoHash() => r'cfd216ec1b0d4c806e7a9a5ff6aca473ea425c91';
