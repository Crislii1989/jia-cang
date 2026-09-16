import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/design_metrics.dart';
import 'package:jia_cang/providers/profile_provider.dart';
import 'package:jia_cang/widgets/emoji_text.dart';

/// 数据概览（高保真稿 S5 `.stat` / `.grid2`，2026-09-16 按稿重排）。
///
/// 2×2 网格，每张卡：40·k 圆角 emoji 底块 +「数字 + 单位」（18·k/800）+
/// 标签（10.5·k）。稿子注明「与首页同规格」——底块、字号与全局统计卡同一套。
///
/// 每项自带 [key]（profileStatsProvider 的字段名），不用「下标硬编码对应
/// data 的哪个字段」——那样只要调整顺序就可能把数字接到错误的标签上。
class DataStatsSection extends ConsumerWidget {
  const DataStatsSection({super.key});

  static const _entries = [
    _StatEntry(
      key: 'itemCount',
      emoji: '📦',
      label: '物品总数',
      unit: '件',
    ),
    _StatEntry(key: 'categoryCount', emoji: '🏷', label: '分类', unit: '个'),
    _StatEntry(key: 'roomCount', emoji: '🏠', label: '房间', unit: '间'),
    _StatEntry(key: 'storageAreaCount', emoji: '🗄', label: '收纳区', unit: '个'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = DesignMetrics.of(context);
    final stats = ref.watch(profileStatsProvider);

    return stats.when(
      skipLoadingOnReload: true,
      skipError: true,
      loading: () => _buildSkeleton(k),
      error: (_, __) => _buildSkeleton(k),
      data: (data) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
        child: Column(
          children: [
            for (int i = 0; i < _entries.length; i += 2) ...[
              if (i > 0) SizedBox(height: 8 * k),
              Row(
                // 两张卡结构一致，自然高度即相等（ListView 内不能 stretch）
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCard(
                      k,
                      _entries[i],
                      data[_entries[i].key] ?? 0,
                    ),
                  ),
                  SizedBox(width: 8 * k),
                  Expanded(
                    child: _buildCard(
                      k,
                      _entries[i + 1],
                      data[_entries[i + 1].key] ?? 0,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(double k, _StatEntry entry, num value) {
    return Container(
      height: 60 * k,
      padding: EdgeInsets.symmetric(horizontal: 16 * k),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14 * k),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.floatCardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 底块：稿子 .tile 40 / r12 / peach-soft
          Container(
            width: 40 * k,
            height: 40 * k,
            decoration: BoxDecoration(
              color: AppColors.coralSoft,
              borderRadius: BorderRadius.circular(12 * k),
            ),
            alignment: Alignment.center,
            child: EmojiText(emoji: entry.emoji, fontSize: 19 * k),
          ),
          SizedBox(width: 14 * k),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _formatValue(value),
                        style: TextStyle(
                          fontSize: 18 * k,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.3 * k,
                          color: AppColors.blushInk,
                        ),
                      ),
                      TextSpan(
                        text: ' ${entry.unit}',
                        style: TextStyle(
                          fontSize: 10 * k,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blushInk2,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1 * k),
                Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5 * k,
                    color: AppColors.blushInk2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(num value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}万';
    }
    return value.toString();
  }

  Widget _buildSkeleton(double k) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Column(
        children: [
          for (int i = 0; i < 2; i++) ...[
            if (i > 0) SizedBox(height: 8 * k),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60 * k,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14 * k),
                    ),
                  ),
                ),
                SizedBox(width: 8 * k),
                Expanded(
                  child: Container(
                    height: 60 * k,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14 * k),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatEntry {
  /// profileStatsProvider 返回 Map 中对应的字段名
  final String key;
  final String emoji;
  final String label;
  final String unit;

  const _StatEntry({
    required this.key,
    required this.emoji,
    required this.label,
    required this.unit,
  });
}
