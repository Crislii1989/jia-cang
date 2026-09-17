import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/app_skin.dart';

/// 皮肤配置的本地持久化。
///
/// 为什么用 SharedPreferences 而不是数据库的 settings 表：
/// 皮肤是**纯界面偏好**，且必须在 `runApp()` 之前就能读到——否则开屏会先
/// 用默认皮肤渲染一帧再跳到用户皮肤（闪一下）。数据库是异步打开、由 DbGate
/// 守卫的，赶不上首帧；SharedPreferences 在 main() 里可用。
/// 代价：皮肤不随 WebDAV 备份走（换设备需要重配一次），对自用场景可接受。
class SkinStore {
  SkinStore._();

  static const _keyActive = 'app_skin_active';
  static const _keyCustom = 'app_skin_custom';

  static SharedPreferences? _prefs;

  /// 当前生效皮肤（未加载时回落到默认，保证任何时刻都有可用皮肤）
  static AppSkin active = AppSkins.coral;

  /// 用户自定义皮肤（按创建顺序）
  static List<AppSkin> custom = [];

  /// 全部可选皮肤 = 内置 + 自定义
  static List<AppSkin> get all => [...AppSkins.builtIns, ...custom];

  /// 启动时加载。**失败不抛异常**：皮肤数据坏了也要能正常启动，
  /// 大不了回落到默认皮肤（宁可少一套皮肤，不能开不了 App）。
  static Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      custom = _decodeCustom(_prefs?.getString(_keyCustom));
      active = _findById(_prefs?.getString(_keyActive)) ?? AppSkins.coral;
    } catch (_) {
      active = AppSkins.coral;
      custom = [];
    }
    AppColors.applySkin(active);
  }

  /// 切换当前皮肤（立即写入 [AppColors]，界面刷新由 provider 触发）
  static Future<void> setActive(AppSkin skin) async {
    active = skin;
    AppColors.applySkin(skin);
    await _prefs?.setString(_keyActive, skin.id);
  }

  /// 新增或更新一套自定义皮肤；若它正是当前皮肤则同步生效
  static Future<void> upsertCustom(AppSkin skin) async {
    final index = custom.indexWhere((s) => s.id == skin.id);
    if (index >= 0) {
      custom[index] = skin;
    } else {
      custom.add(skin);
    }
    if (active.id == skin.id) {
      active = skin;
      AppColors.applySkin(skin);
    }
    await _persistCustom();
  }

  /// 删除一套自定义皮肤。若删的是当前皮肤，回落到默认皮肤
  /// （**不会**自动挑另一套：用户可能只是删掉不想要的，突然换色更突兀）。
  static Future<void> deleteCustom(String id) async {
    custom.removeWhere((s) => s.id == id);
    if (active.id == id) {
      active = AppSkins.coral;
      AppColors.applySkin(active);
      await _prefs?.setString(_keyActive, active.id);
    }
    await _persistCustom();
  }

  static Future<void> _persistCustom() async {
    await _prefs?.setString(
      _keyCustom,
      jsonEncode(custom.map((s) => s.toJson()).toList()),
    );
  }

  static AppSkin? _findById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  static List<AppSkin> _decodeCustom(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      final out = <AppSkin>[];
      for (final item in list) {
        if (item is Map) {
          out.add(AppSkin.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }
}
