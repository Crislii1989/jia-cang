import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum SortType {
  /// 新增时间（最新优先）
  newest,

  /// 新增时间（最早优先）
  oldest,

  /// 名称（字典序升序）
  nameAsc,

  /// 到期时间（近到期优先，无到期日的排最后）
  expiryAsc,

  /// 分类（按分类标签排序，同类内按名称）
  categoryAsc,
}

/// 排序 chip 上的短标签
const Map<SortType, String> kSortLabels = {
  SortType.newest: '新增时间',
  SortType.oldest: '最早添加',
  SortType.nameAsc: '名称',
  SortType.expiryAsc: '到期时间',
  SortType.categoryAsc: '分类',
};

/// 排序下拉里的完整标签
const Map<SortType, String> kSortFullLabels = {
  SortType.newest: '新增时间（最新优先）',
  SortType.oldest: '新增时间（最早优先）',
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
