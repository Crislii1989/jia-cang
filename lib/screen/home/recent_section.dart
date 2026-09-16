import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/models/enums/item_tag_type.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/widgets/list_item_card.dart';

class RecentSection extends ConsumerWidget {
  const RecentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentItemsProvider);

    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: AppColors.textHint.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                '暂无物品记录',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: recent.take(4).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RecentItemCard(
              emoji: '\u{1F4E6}',
              photoPath: item.photos.isNotEmpty ? item.photos.first : null,
              name: item.name,
              meta: item.location,
              tagType: _resolveTag(item),
              onTap: () => context.push('/detail/${item.id}'),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 标签逻辑：
  /// 1. 近30天内创建 → newItem
  /// 2. 其他 → normal
  ItemTagType _resolveTag(dynamic item) {
    final daysSinceCreated = DateTime.now().difference(item.createdAt).inDays;
    if (daysSinceCreated <= 30) return ItemTagType.newItem;

    return ItemTagType.normal;
  }
}
