import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/design_metrics.dart';
import 'package:jia_cang/models/category.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/widgets/emoji_text.dart';

/// 首页分类入口：大圆形图标，**一行 4 个**（高保真稿 V2.6 定稿）。
///
/// 展示规则（2026-09-17 拍板）：**按分类下的物品数取前 [_maxVisible] 个**——
/// 常用品类自动浮上来，零配置；物品数相同的按 sortOrder 原顺序稳定排序
/// （全 0 时等于维持原顺序）。一屏只展示前 4 个，圆底用四色 pastel 水彩
/// 渐变轮转（粉 / 蓝 / 绿 / 紫，保证相邻不撞色）；圆形直径 56，标签 11。
/// 点击某个分类 → 写入「待选分类」并切到物品库 Tab，由物品库在挂载/兜底
/// 逻辑里消费（见 `pendingCategoryProvider`）。
///
/// 圆直径与间距经 [DesignMetrics] 等比换算：设计稿的内容宽 292 下，
/// 四格槽位是 68.5、圆占 56；写死 56 的话视口一宽槽位就涨到 110+，
/// 每个圆两侧多出几十像素空白，整行看着又小又散。
class CategoryCirclesSection extends ConsumerWidget {
  const CategoryCirclesSection({super.key});

  static const int _maxVisible = 4;

  /// 圆形图标底色轮转（水彩渐变；图标本身是彩色 emoji，故底色保持柔和）
  static const List<List<Color>> _circleGradients = [
    AppColors.catPink,
    AppColors.catBlue,
    AppColors.catGreen,
    AppColors.catPurple,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = DesignMetrics.of(context);
    final categories = ref.watch(availableCategoriesProvider);
    final items = ref
        .watch(itemsProvider)
        .maybeWhen(data: (list) => list, orElse: () => const <Item>[]);

    // 每个分类的物品数（一次遍历统计），随后按「物品数多者优先」稳定排序。
    // List.sort 在 Dart 里不是稳定排序，所以用「计数取负 + 原索引」组合排序
    // 保证同数分类维持 sortOrder 原顺序。
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.categoryKey] = (counts[item.categoryKey] ?? 0) + 1;
    }
    final indexed = categories.asMap().entries.toList()
      ..sort((a, b) {
        final ca = counts[a.value.key] ?? 0;
        final cb = counts[b.value.key] ?? 0;
        if (ca != cb) return cb - ca; // 多者优先
        return a.key.compareTo(b.key); // 同数维持原顺序
      });
    final visible = indexed.take(_maxVisible).map((e) => e.value).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            if (i > 0) SizedBox(width: 6 * k),
            Expanded(
              child: _CategoryCircle(
                category: visible[i],
                circleGradient:
                    _circleGradients[i % _circleGradients.length],
                onTap: () {
                  ref.read(pendingCategoryProvider.notifier).set(visible[i].key);
                  context.go('/inventory');
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  final Category category;
  final List<Color> circleGradient;
  final VoidCallback onTap;

  const _CategoryCircle({
    required this.category,
    required this.circleGradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final k = DesignMetrics.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56 * k,
            height: 56 * k,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: const Alignment(-0.5, -1),
                end: const Alignment(0.5, 1),
                colors: circleGradient,
              ),
              border: Border.all(color: AppColors.floatHairline),
              boxShadow: [
                BoxShadow(
                  color: AppColors.floatCardShadowStrong,
                  blurRadius: 9 * k,
                  offset: Offset(0, 3 * k),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: category.emoji.isEmpty
                ? Text(
                    category.label.isEmpty
                        ? '?'
                        : category.label.characters.first,
                    style: TextStyle(
                      fontSize: 20 * k,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blushInk,
                    ),
                  )
                : EmojiText(emoji: category.emoji, fontSize: 25 * k),
          ),
          SizedBox(height: 6 * k),
          Text(
            category.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11 * k, color: AppColors.catLabel),
          ),
        ],
      ),
    );
  }
}
