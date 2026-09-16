/// 分类数据结构，用于物品库 tab 筛选与新增物品页分类选择。
///
/// 与 DB `categories` 表（分类管理页：内置系统分类 + 用户自定义分类）配合使用，
/// 运行时由 `availableCategoriesProvider` 从数据库分类派生。
///
/// 说明：早先还有一组「虚拟物品分类」（会员订阅 / 网卡流量 / 数字许可证 / 礼品卡），
/// 由品类模版写入、不落数据库。因「系统分类只保留生活中常见的实物品类」的约定，
/// 这组非实物虚拟分类已随 schema v7 一并移除，不再出现在分类选择器与物品库 tab 里。
class Category {
  final String key;
  final String label;
  final String emoji;
  const Category(this.key, this.label, {this.emoji = ''});
}

/// 把物品的 `categoryKey` 翻成展示用的分类文案。
///
/// 物品库里存的是 key（如 `sports`），直接显示会出现「分类 = sports」这种
/// 中英混排的裸 key；统一走这里换成列表里的中文名（`运动`）。
///
/// - [key] 为空：返回 [fallback]（默认「未分类」）
/// - [cats] 里查不到该 key（分类被删掉、或数据来自旧备份）：
///   原样返回 key —— 至少还能看出它属于哪个分类，也不要显示成空。
String categoryLabelOf(
  List<Category> cats,
  String key, {
  String fallback = '未分类',
}) {
  if (key.isEmpty) return fallback;
  for (final c in cats) {
    if (c.key == key) return c.label;
  }
  return key;
}

/// 把物品的 `categoryKey` 翻成分类 emoji。
///
/// 详情页沉浸大图**没有照片**时，用所属分类的 emoji 当占位图形
/// （设计稿 S3 画的就是 🎮，即「分类 = 游戏机」的那颗）。
///
/// - [key] 为空或查不到：返回 [fallback]（默认 📦，与旧的占位一致）
String categoryEmojiOf(
  List<Category> cats,
  String key, {
  String fallback = '📦',
}) {
  if (key.isEmpty) return fallback;
  for (final c in cats) {
    if (c.key == key) {
      return c.emoji.isEmpty ? fallback : c.emoji;
    }
  }
  return fallback;
}
