import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/design_metrics.dart';
import 'package:jia_cang/models/category.dart';
import 'package:jia_cang/models/reminder_entry.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/widgets/emoji_text.dart';

/// 首页「提醒」模块（高保真稿 V2.6 定稿；标题按 V2.8 约定不加 emoji）。
///
/// 聚合三类条目：已到期（红）/ 即将到期（珊瑚）/ 长期闲置（中性），按紧急度排序。
/// V2.1 起由「每条一张独立卡片」改为**一组白卡 + 行间细分割线**，
/// 并**去掉「去处理」按钮**——整行就是入口，右侧改为显示日期
/// （到期条目显示「09-14 到期」，闲置条目显示「06-01 登记」）。
/// 无提醒时显示空态。
///
/// 字号与行距经 [DesignMetrics] 等比换算，保证宽视口下与设计稿同比例。
class ReminderSection extends ConsumerWidget {
  const ReminderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = DesignMetrics.of(context);
    final reminders = ref.watch(homeRemindersProvider);

    if (reminders.isEmpty) return const _AllClearCard();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Container(
        // 行内分割线要顶到卡片边，圆角必须显式裁子节点
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16 * k),
          boxShadow: [
            BoxShadow(
              color: AppColors.floatCardShadow,
              blurRadius: 12 * k,
              offset: Offset(0, 3 * k),
            ),
          ],
        ),
        child: Column(
          children: [
            for (int i = 0; i < reminders.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.reminderDivider,
                ),
              _ReminderRow(entry: reminders[i], index: i),
            ],
          ],
        ),
      ),
    );
  }
}

/// 全部妥当时的空态（不占大版面，一句话 + emoji）
class _AllClearCard extends StatelessWidget {
  const _AllClearCard();

  @override
  Widget build(BuildContext context) {
    final k = DesignMetrics.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16 * k),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16 * k),
          boxShadow: [
            BoxShadow(
              color: AppColors.floatCardShadow,
              blurRadius: 12 * k,
              offset: Offset(0, 3 * k),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmojiText(emoji: '✅', fontSize: 16 * k),
            SizedBox(width: 6 * k),
            Text(
              '一切妥当，暂无待处理提醒',
              style: TextStyle(fontSize: 12 * k, color: AppColors.blushInk2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends ConsumerWidget {
  final ReminderEntry entry;

  /// 行序号：决定缩略图用哪一档 pastel 渐变（粉 / 绿 / 蓝轮转）
  final int index;

  const _ReminderRow({required this.entry, required this.index});

  /// 缩略图底：与行序对应的水彩渐变
  static const List<List<Color>> _thumbGradients = [
    AppColors.catPink,
    AppColors.catGreen,
    AppColors.catBlue,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = DesignMetrics.of(context);
    final item = entry.item;

    final Color statusColor = switch (entry.kind) {
      ReminderKind.overdue => AppColors.reminderDanger,
      ReminderKind.expiring => AppColors.reminderWarn,
      ReminderKind.idle => AppColors.reminderMuted,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/item/${item.id}'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 13 * k, vertical: 11 * k),
        child: Row(
          children: [
            Container(
              width: 38 * k,
              height: 38 * k,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: const Alignment(-0.5, -1),
                  end: const Alignment(0.5, 1),
                  colors: _thumbGradients[index % _thumbGradients.length],
                ),
              ),
              alignment: Alignment.center,
              child: EmojiText(
                emoji: _emojiOf(ref, item.categoryKey),
                fontSize: 18 * k,
              ),
            ),
            SizedBox(width: 11 * k),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13 * k,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blushInk,
                    ),
                  ),
                  SizedBox(height: 3 * k),
                  Text(
                    entry.badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11 * k,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * k),
            Text(
              _rightText(),
              style: TextStyle(
                fontSize: 11 * k,
                color: AppColors.reminderDate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 右侧日期：到期类显示「MM-dd 到期」，闲置类显示「MM-dd 登记」
  String _rightText() {
    if (entry.kind == ReminderKind.idle) {
      return '${_monthDay(entry.item.createdAt)} 登记';
    }
    final expiry = entry.item.expiryDate;
    if (expiry == null) return '';
    return '${_monthDay(expiry)} 到期';
  }

  static String _monthDay(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m-$day';
  }

  /// 用物品所属分类的 emoji 当缩略图；分类缺失时退回通用盒子图标
  String _emojiOf(WidgetRef ref, String categoryKey) {
    final categories = ref.watch(availableCategoriesProvider);
    if (categoryKey.isNotEmpty) {
      for (final Category c in categories) {
        if (c.key == categoryKey && c.emoji.isNotEmpty) return c.emoji;
      }
    }
    return '📦';
  }
}
