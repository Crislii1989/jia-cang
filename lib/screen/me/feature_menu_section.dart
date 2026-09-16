import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/design_metrics.dart';
import 'package:jia_cang/providers/profile_provider.dart';
import 'package:jia_cang/widgets/emoji_text.dart';
import 'package:jia_cang/widgets/section_title.dart';
import 'help_feedback_sheet.dart';

/// 应用管理 / 设置 两组功能入口（高保真稿 S5 `.cell-group`，2026-09-16 按稿重排）。
///
/// 行式白卡组：行内细分割线（cellDivider），每行 = 26·k emoji 底块 +
/// 标题（12.5·k）+ 右侧灰值（11.5·k）+ 箭头。
/// 旧版「私密空间 / 家庭共享（即将上线占位）」不在稿内，已随重排移除。
class FeatureMenuSection extends ConsumerWidget {
  const FeatureMenuSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = DesignMetrics.of(context);
    final stats = ref.watch(profileStatsProvider);
    final data = stats.value ?? const {};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            title: '应用管理',
            titleSize: 13 * k,
            titleColor: AppColors.blushInk,
          ),
          SizedBox(height: 10 * k),
          _CellGroup(
            k: k,
            cells: [
              _Cell(
                emoji: '📦',
                title: '收纳空间管理',
                value:
                    '${data['roomCount'] ?? 0} 房间 · ${data['storageAreaCount'] ?? 0} 收纳区',
                onTap: () => context.go('/storage'),
              ),
              _Cell(
                emoji: '🏷',
                title: '分类管理',
                value: '${data['categoryCount'] ?? 0} 个分类',
                onTap: () => context.push('/categories'),
              ),
            ],
          ),
          // 稿子：两组之间 18pt 间距
          SizedBox(height: 18 * k),
          SectionTitle(
            title: '设置',
            titleSize: 13 * k,
            titleColor: AppColors.blushInk,
          ),
          SizedBox(height: 10 * k),
          _CellGroup(
            k: k,
            cells: [
              _Cell(
                emoji: '☁️',
                title: '数据备份与恢复',
                onTap: () => context.push('/data-backup'),
              ),
              _Cell(
                emoji: '🤖',
                title: 'AI 识别设置',
                onTap: () => context.push('/ai-settings'),
              ),
              _Cell(
                emoji: '🔄',
                title: '检查更新',
                onTap: () => context.push('/check-update'),
              ),
              _Cell(
                emoji: '💬',
                title: '关于 / 反馈',
                value: 'v1.3.1',
                onTap: () => HelpFeedbackSheet.show(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 一组行式白卡：圆角卡 + 行间 1px cellDivider 细线。
class _CellGroup extends StatelessWidget {
  final double k;
  final List<_Cell> cells;

  const _CellGroup({required this.k, required this.cells});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 行分割线要顶到卡边，圆角必须显式裁子节点
      clipBehavior: Clip.antiAlias,
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
      child: Column(
        children: [
          for (int i = 0; i < cells.length; i++) ...[
            if (i > 0)
              Container(height: 1, color: AppColors.cellDivider),
            cells[i],
          ],
        ],
      ),
    );
  }
}

/// 一行入口：26·k emoji 底块 + 标题 + 右值 + 箭头（稿子 `.cell`）。
class _Cell extends StatelessWidget {
  final String emoji;
  final String title;
  final String? value;
  final VoidCallback onTap;

  const _Cell({
    required this.emoji,
    required this.title,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final k = DesignMetrics.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 40 * k),
        padding: EdgeInsets.symmetric(horizontal: 12 * k, vertical: 10 * k),
        child: Row(
          children: [
            Container(
              width: 26 * k,
              height: 26 * k,
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                borderRadius: BorderRadius.circular(8 * k),
              ),
              alignment: Alignment.center,
              child: EmojiText(emoji: emoji, fontSize: 13 * k),
            ),
            SizedBox(width: 10 * k),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5 * k,
                fontWeight: FontWeight.w600,
                color: AppColors.blushInk,
              ),
            ),
            const Spacer(),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5 * k,
                    color: AppColors.blushInk3,
                  ),
                ),
              ),
            SizedBox(width: 4 * k),
            Icon(
              Icons.chevron_right,
              size: 14 * k,
              color: AppColors.blushInk3,
            ),
          ],
        ),
      ),
    );
  }
}
