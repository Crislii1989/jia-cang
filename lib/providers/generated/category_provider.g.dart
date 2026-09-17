// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../category_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 物品库 tab 与新增物品页分类选择器共用的分类列表。
/// 派生自 [CategoryManager]（数据库分类，含内置系统分类与用户自定义分类）。
/// 用户在分类管理页的新增/编辑/删除会通过此 provider 实时反映到所有使用方。

@ProviderFor(availableCategories)
final availableCategoriesProvider = AvailableCategoriesProvider._();

/// 物品库 tab 与新增物品页分类选择器共用的分类列表。
/// 派生自 [CategoryManager]（数据库分类，含内置系统分类与用户自定义分类）。
/// 用户在分类管理页的新增/编辑/删除会通过此 provider 实时反映到所有使用方。

final class AvailableCategoriesProvider
    extends $FunctionalProvider<List<Category>, List<Category>, List<Category>>
    with $Provider<List<Category>> {
  /// 物品库 tab 与新增物品页分类选择器共用的分类列表。
  /// 派生自 [CategoryManager]（数据库分类，含内置系统分类与用户自定义分类）。
  /// 用户在分类管理页的新增/编辑/删除会通过此 provider 实时反映到所有使用方。
  AvailableCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableCategoriesHash();

  @$internal
  @override
  $ProviderElement<List<Category>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Category> create(Ref ref) {
    return availableCategories(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Category> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Category>>(value),
    );
  }
}

String _$availableCategoriesHash() =>
    r'558e2f5b729976cce9d9f53240b69130e16bf2b3';

@ProviderFor(CategoryManager)
final categoryManagerProvider = CategoryManagerProvider._();

final class CategoryManagerProvider
    extends $AsyncNotifierProvider<CategoryManager, List<CategoryItem>> {
  CategoryManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryManagerHash();

  @$internal
  @override
  CategoryManager create() => CategoryManager();
}

String _$categoryManagerHash() => r'5eafcfa41f5384c37b7e89b1c15c1f70832af829';

abstract class _$CategoryManager extends $AsyncNotifier<List<CategoryItem>> {
  FutureOr<List<CategoryItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CategoryItem>>, List<CategoryItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CategoryItem>>, List<CategoryItem>>,
              AsyncValue<List<CategoryItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
