import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_skin.dart';
import '../services/skin_store.dart';

/// 皮肤系统的状态：
/// - [active]：当前生效的皮肤
/// - [custom]：用户自定义皮肤
/// - [revision]：变更计数，**每次应用皮肤都自增**
///
/// 内置皮肤是常量、永远存在；自定义皮肤存 SharedPreferences（见 [SkinStore]）。
///
/// [revision] 存在的理由：全局换色是靠「重建路由页面」触发的，而重建的
/// 入口是 `MyApp` 监听皮肤后的重建（`main.dart`）+ 路由页面 key 里的皮肤
/// 版本号（`app_router.dart` 的 `_skinKeyed`）。所以这里必须有一个**每次变更
/// 都会变**的值——只比 id 的话，**编辑当前正在使用的那套自定义皮肤**
/// 时 id 没变，全应用就不会重建，改了颜色却看不到变化。
@immutable
class SkinState {
  final AppSkin active;
  final List<AppSkin> custom;
  final int revision;

  const SkinState({
    required this.active,
    required this.custom,
    this.revision = 0,
  });

  /// 界面上要展示的全部皮肤（内置在前，自定义在后）
  List<AppSkin> get all => [...AppSkins.builtIns, ...custom];
}

/// 皮肤管理。
///
/// ⚠️ 这个 provider 是**手写**的（没用 `@riverpod` 代码生成）：
/// 为一个 provider 触发一次全量 build_runner，会连带重写所有 .g.dart
/// （drift/freezed/riverpod 生成物），改动面远大于收益。
/// 行为与代码生成的 Notifier 一致，后续若要统一风格可随时迁移。
class SkinManager extends Notifier<SkinState> {
  @override
  SkinState build() =>
      SkinState(active: SkinStore.active, custom: SkinStore.custom);

  /// 应用一套已有皮肤
  Future<void> select(AppSkin skin) async {
    await SkinStore.setActive(skin);
    _sync();
  }

  /// 新建或保存一套自定义皮肤。
  ///
  /// [activate] 为 true 时保存后立即切换到它（新建流程用；用户刚捏完
  /// 一套配色，当然想马上看到全应用的样子）。编辑一套**不是当前**的皮肤时
  /// 传 false，只更新列表，不打断用户当前的配色。
  Future<void> saveCustom(AppSkin skin, {bool activate = false}) async {
    await SkinStore.upsertCustom(skin);
    if (activate) await SkinStore.setActive(skin);
    _sync();
  }

  /// 删除一套自定义皮肤（若为当前皮肤则回落到默认）
  Future<void> removeCustom(String id) async {
    await SkinStore.deleteCustom(id);
    _sync();
  }

  /// 把存储里的最新状态同步进 UI，并推进 [SkinState.revision]
  /// —— revision 只增不减，保证每次变更都会让根节点换 key 重建。
  void _sync() {
    state = SkinState(
      active: SkinStore.active,
      custom: SkinStore.custom,
      revision: state.revision + 1,
    );
  }
}

final skinManagerProvider = NotifierProvider<SkinManager, SkinState>(
  SkinManager.new,
);
