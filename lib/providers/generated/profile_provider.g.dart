// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 用户资料（昵称 + 头像 emoji）

@ProviderFor(ProfileManager)
final profileManagerProvider = ProfileManagerProvider._();

/// 用户资料（昵称 + 头像 emoji）
final class ProfileManagerProvider
    extends $AsyncNotifierProvider<ProfileManager, Map<String, String>> {
  /// 用户资料（昵称 + 头像 emoji）
  ProfileManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileManagerHash();

  @$internal
  @override
  ProfileManager create() => ProfileManager();
}

String _$profileManagerHash() => r'6c77444b7df98439604cbd165001b5e6d15dd1ca';

/// 用户资料（昵称 + 头像 emoji）

abstract class _$ProfileManager extends $AsyncNotifier<Map<String, String>> {
  FutureOr<Map<String, String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, String>>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, String>>, Map<String, String>>,
              AsyncValue<Map<String, String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 个人中心数据统计
///
/// 通过监听 itemsProvider / roomsProvider / categoryManagerProvider，
/// 使「数据概览」随数据库变化实时刷新，避免展示过期或空数据。
/// 物品数量直接复用 [itemCountProvider]
/// （派生自内存中的 itemsProvider，免去额外 SQL，并与首页口径一致）。
///
/// 「房间」与「收纳区」是两个不同维度的口径：
/// - 房间：用户建立的房间个数；
/// - 收纳区：除房间本身以外的全部收纳空间，即柜体 + 箱子（格子）。
///   刻意不把房间算进去 —— 房间是「容器」，收纳区是房间内部的具体落点，
///   两者相加没有意义，分开统计才能看出收纳密度。

@ProviderFor(profileStats)
final profileStatsProvider = ProfileStatsProvider._();

/// 个人中心数据统计
///
/// 通过监听 itemsProvider / roomsProvider / categoryManagerProvider，
/// 使「数据概览」随数据库变化实时刷新，避免展示过期或空数据。
/// 物品数量直接复用 [itemCountProvider]
/// （派生自内存中的 itemsProvider，免去额外 SQL，并与首页口径一致）。
///
/// 「房间」与「收纳区」是两个不同维度的口径：
/// - 房间：用户建立的房间个数；
/// - 收纳区：除房间本身以外的全部收纳空间，即柜体 + 箱子（格子）。
///   刻意不把房间算进去 —— 房间是「容器」，收纳区是房间内部的具体落点，
///   两者相加没有意义，分开统计才能看出收纳密度。

final class ProfileStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  /// 个人中心数据统计
  ///
  /// 通过监听 itemsProvider / roomsProvider / categoryManagerProvider，
  /// 使「数据概览」随数据库变化实时刷新，避免展示过期或空数据。
  /// 物品数量直接复用 [itemCountProvider]
  /// （派生自内存中的 itemsProvider，免去额外 SQL，并与首页口径一致）。
  ///
  /// 「房间」与「收纳区」是两个不同维度的口径：
  /// - 房间：用户建立的房间个数；
  /// - 收纳区：除房间本身以外的全部收纳空间，即柜体 + 箱子（格子）。
  ///   刻意不把房间算进去 —— 房间是「容器」，收纳区是房间内部的具体落点，
  ///   两者相加没有意义，分开统计才能看出收纳密度。
  ProfileStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileStatsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return profileStats(ref);
  }
}

String _$profileStatsHash() => r'a0da7cdbf58cdeba00171baf8f8c5ebd9df9bc3e';

/// 多 AI Provider 配置管理
///
/// 支持同一供应商下保存多个不同模型配置，每个配置有唯一ID
/// 所有敏感配置（API Key、Secret Key、模型名、BaseURL）均使用 AES-256-CBC 加密存储
/// 加密前缀 enc: 区分加密数据与旧版明文数据（自动兼容迁移）

@ProviderFor(AiConfigManager)
final aiConfigManagerProvider = AiConfigManagerProvider._();

/// 多 AI Provider 配置管理
///
/// 支持同一供应商下保存多个不同模型配置，每个配置有唯一ID
/// 所有敏感配置（API Key、Secret Key、模型名、BaseURL）均使用 AES-256-CBC 加密存储
/// 加密前缀 enc: 区分加密数据与旧版明文数据（自动兼容迁移）
final class AiConfigManagerProvider
    extends $AsyncNotifierProvider<AiConfigManager, AiProviderConfig> {
  /// 多 AI Provider 配置管理
  ///
  /// 支持同一供应商下保存多个不同模型配置，每个配置有唯一ID
  /// 所有敏感配置（API Key、Secret Key、模型名、BaseURL）均使用 AES-256-CBC 加密存储
  /// 加密前缀 enc: 区分加密数据与旧版明文数据（自动兼容迁移）
  AiConfigManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiConfigManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiConfigManagerHash();

  @$internal
  @override
  AiConfigManager create() => AiConfigManager();
}

String _$aiConfigManagerHash() => r'1c72219a002cd0870543d2720bffcedc51d7be05';

/// 多 AI Provider 配置管理
///
/// 支持同一供应商下保存多个不同模型配置，每个配置有唯一ID
/// 所有敏感配置（API Key、Secret Key、模型名、BaseURL）均使用 AES-256-CBC 加密存储
/// 加密前缀 enc: 区分加密数据与旧版明文数据（自动兼容迁移）

abstract class _$AiConfigManager extends $AsyncNotifier<AiProviderConfig> {
  FutureOr<AiProviderConfig> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AiProviderConfig>, AiProviderConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AiProviderConfig>, AiProviderConfig>,
              AsyncValue<AiProviderConfig>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 当前生效的 [AiProvider] 实例（基于 [AiConfigManager] 配置动态解析）

@ProviderFor(activeAiProvider)
final activeAiProviderProvider = ActiveAiProviderProvider._();

/// 当前生效的 [AiProvider] 实例（基于 [AiConfigManager] 配置动态解析）

final class ActiveAiProviderProvider
    extends $FunctionalProvider<AiProvider, AiProvider, AiProvider>
    with $Provider<AiProvider> {
  /// 当前生效的 [AiProvider] 实例（基于 [AiConfigManager] 配置动态解析）
  ActiveAiProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeAiProviderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeAiProviderHash();

  @$internal
  @override
  $ProviderElement<AiProvider> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AiProvider create(Ref ref) {
    return activeAiProvider(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiProvider value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiProvider>(value),
    );
  }
}

String _$activeAiProviderHash() => r'f472661dbb290d446abe68095cc23e979ec6ff70';

/// 所有已保存的模型配置（用于扫描页模型选择器）

@ProviderFor(SavedAiConfigs)
final savedAiConfigsProvider = SavedAiConfigsProvider._();

/// 所有已保存的模型配置（用于扫描页模型选择器）
final class SavedAiConfigsProvider
    extends $AsyncNotifierProvider<SavedAiConfigs, List<AiProviderConfig>> {
  /// 所有已保存的模型配置（用于扫描页模型选择器）
  SavedAiConfigsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedAiConfigsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedAiConfigsHash();

  @$internal
  @override
  SavedAiConfigs create() => SavedAiConfigs();
}

String _$savedAiConfigsHash() => r'2ffc187e26aa86a821b5f5d064c4277466a45eae';

/// 所有已保存的模型配置（用于扫描页模型选择器）

abstract class _$SavedAiConfigs extends $AsyncNotifier<List<AiProviderConfig>> {
  FutureOr<List<AiProviderConfig>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<AiProviderConfig>>, List<AiProviderConfig>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<AiProviderConfig>>,
                List<AiProviderConfig>
              >,
              AsyncValue<List<AiProviderConfig>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 性能监控：在内存中累积最近 50 次调用记录

@ProviderFor(AiCallLogs)
final aiCallLogsProvider = AiCallLogsProvider._();

/// 性能监控：在内存中累积最近 50 次调用记录
final class AiCallLogsProvider
    extends $NotifierProvider<AiCallLogs, List<AiCallLog>> {
  /// 性能监控：在内存中累积最近 50 次调用记录
  AiCallLogsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiCallLogsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiCallLogsHash();

  @$internal
  @override
  AiCallLogs create() => AiCallLogs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<AiCallLog> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<AiCallLog>>(value),
    );
  }
}

String _$aiCallLogsHash() => r'fe3ef7d54622d6b583d1fb95a5c2360c4c287f4a';

/// 性能监控：在内存中累积最近 50 次调用记录

abstract class _$AiCallLogs extends $Notifier<List<AiCallLog>> {
  List<AiCallLog> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<AiCallLog>, List<AiCallLog>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<AiCallLog>, List<AiCallLog>>,
              List<AiCallLog>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
