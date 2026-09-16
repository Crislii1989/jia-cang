import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/providers/profile_provider.dart';

/// 数据概览网格
class DataStatsSection extends ConsumerWidget {
  const DataStatsSection({super.key});

  /// 网格顺序即展示顺序（2 列，按行从左到右填充）：
  /// 第一行 物品总数 / 分类数量，第二行 房间 / 收纳区。
  ///
  /// 每项自带 [key]（profileStatsProvider 的字段名），不再用「下标硬编码对应
  /// data 的哪个字段」——那样只要调整顺序就可能把数字接到错误的标签上。
  static const _entries = [
    _StatEntry(
      key: 'itemCount',
      icon: Icons.inventory_2_outlined,
      label: '物品总数',
      color: AppColors.primary,
    ),
    _StatEntry(
      key: 'categoryCount',
      icon: Icons.category_outlined,
      label: '分类数量',
      color: AppColors.warning,
    ),
    _StatEntry(
      key: 'roomCount',
      icon: Icons.meeting_room_outlined,
      label: '房间',
      color: AppColors.success,
    ),
    _StatEntry(
      key: 'storageAreaCount',
      icon: Icons.grid_view_outlined,
      label: '收纳区',
      color: AppColors.info,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider);

    return stats.when(
      skipLoadingOnReload: true,
      skipError: true,
      loading: () => _buildSkeleton(),
      error: (_, __) => _buildSkeleton(),
      data: (data) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // 单行「图标 + 数字 + 标签」的实际高度约 44，卡宽约 154；
          // 原来的 1.1 会让每张卡片高到 140，正文之外多出一大片空白。
          // 3.5 是反复调过的比例：卡片高约 44+32=76，刚好包住内容。
          childAspectRatio: 3.5,
          children: [
            for (final entry in _entries)
              _buildCell(entry, data[entry.key] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(_StatEntry entry, num value) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: const Cubic(0.34, 1.56, 0.64, 1),
      builder: (context, t, child) {
        return Transform.scale(
          scale: 0.85 + 0.15 * t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, size: 19, color: entry.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatValue(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(num value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}万';
    }
    return value.toString();
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.5,
        children: List.generate(
          4,
          (i) => Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatEntry {
  /// profileStatsProvider 返回 Map 中对应的字段名
  final String key;
  final IconData icon;
  final String label;
  final Color color;

  const _StatEntry({
    required this.key,
    required this.icon,
    required this.label,
    required this.color,
  });
}
