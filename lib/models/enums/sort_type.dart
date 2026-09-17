import 'package:json_annotation/json_annotation.dart';

/// 枚举顺序 = 排序下拉的展示顺序（sort_dropdown 直接遍历 values）。
/// 2026-09-17 反馈：「名称」放最底下；持久化按 name 解析，
/// 与枚举顺序无关，重排不影响已保存的偏好。
enum SortType {
  /// 登记时间（最新优先）
  newest,

  /// 登记时间（最早优先）
  oldest,

  /// 到期时间（近到期优先，无到期日的排最后）
  expiryAsc,

  /// 分类（按分类标签排序，同类内按名称）
  categoryAsc,

  /// 名称（字典序升序）——按反馈固定在最后
  nameAsc,
}

/// 排序 chip 上的短标签
const Map<SortType, String> kSortLabels = {
  SortType.newest: '登记时间',
  SortType.oldest: '最早登记',
  SortType.nameAsc: '名称',
  SortType.expiryAsc: '到期时间',
  SortType.categoryAsc: '分类',
};

/// 排序下拉里的完整标签
const Map<SortType, String> kSortFullLabels = {
  SortType.newest: '登记时间（最新优先）',
  SortType.oldest: '登记时间（最早优先）',
  SortType.nameAsc: '名称（A → Z）',
  SortType.expiryAsc: '到期时间（近到期优先）',
  SortType.categoryAsc: '分类（同分类内按名称）',
};

/// 从持久化字符串解析（未知/缺失回退 newest）
SortType sortTypeFromName(String? name) {
  for (final t in SortType.values) {
    if (t.name == name) return t;
  }
  return SortType.newest;
}
