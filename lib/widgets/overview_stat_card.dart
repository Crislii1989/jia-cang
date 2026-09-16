import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'emoji_text.dart';

/// 统计概览卡（高保真稿 V1.5 定稿形态，全局统一组件）。
///
/// 结构：左侧 40×40 圆角色块图标 + 右侧两行文字——
/// 上行「数字 + 单位」（18/800，视觉主体），下行标签（10.5 次级色）。
/// 靠左排布、内容自然撑满，禁止居中排（内容宽度不一致会显得散）。
///
/// ⚠️ 现状（V2.6 复审）：**当前没有生产调用方** —— 首页概览已改由
/// `screen/home/stat_minis_section.dart` 的竖排高卡承担，「我的」页数据概览自带
/// `data_stats_section.dart` 的 `_buildCell`（彩色图标底 / 圆角 18）。本组件仅由
/// `test/widgets/overview_stat_card_test.dart` 覆盖。
/// 处置待定：下一轮统一「我的」等页面时优先复用它，或明确退役并连测试一起删。
/// （旧 [StatCard] 为竖排大卡，首页改版完成后退役。）
class OverviewStatCard extends StatelessWidget {
  /// 图标 emoji（经 [EmojiText] 渲染，遵循项目 emoji 规范）
  final String emoji;

  /// 标签（下行小字，如「物品总数」）
  final String label;

  /// 数值（上行主体）
  final int value;

  /// 单位（如 件/个/间），默认「件」
  final String unit;

  /// hot 态：浅金底 + 金色描边（用于即将到期 / 长期闲置等需要突显的卡）
  final bool highlighted;

  final VoidCallback? onTap;

  const OverviewStatCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    this.unit = '件',
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: AppDimensions.statCardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.goldSoft : AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(
          color: highlighted ? AppColors.goldSoftBorder : AppColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: AppDimensions.shadowBlurSmall,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.statCardTileSize,
            height: AppDimensions.statCardTileSize,
            decoration: BoxDecoration(
              color: highlighted ? AppColors.goldTile : AppColors.neutralTile,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusMedium),
            ),
            alignment: Alignment.center,
            child: EmojiText(emoji: emoji, fontSize: 19),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}
