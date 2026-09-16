import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/models/category.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/widgets/emoji_text.dart';

/// 首页分类入口：大圆形图标，**一行 4 个**（高保真稿 V2.6 定稿）。
///
/// 一屏只展示前 [_maxVisible] 个分类，圆底用四色 pastel 水彩渐变轮转
/// （粉 / 蓝 / 绿 / 紫，保证相邻不撞色）；圆形直径 56，标签 11。
/// 点击某个分类 → 写入「待选分类」并切到物品库 Tab，由物品库在挂载/兜底
/// 逻辑里消费（见 `pendingCategoryProvider`）。
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
    final categories = ref.watch(availableCategoriesProvider);
    final visible = categories.take(_maxVisible).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: const Alignment(-0.5, -1),
                end: const Alignment(0.5, 1),
                colors: circleGradient,
              ),
              border: Border.all(color: AppColors.floatHairline),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.floatCardShadowStrong,
                  blurRadius: 9,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: category.emoji.isEmpty
                ? Text(
                    category.label.isEmpty
                        ? '?'
                        : category.label.characters.first,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blushInk,
                    ),
                  )
                : EmojiText(emoji: category.emoji, fontSize: 25),
          ),
          const SizedBox(height: 6),
          Text(
            category.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.catLabel),
          ),
        ],
      ),
    );
  }
}
