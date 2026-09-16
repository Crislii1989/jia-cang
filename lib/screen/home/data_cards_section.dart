import 'package:flutter/material.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/widgets/data_card.dart';

class DataCardsSection extends StatelessWidget {
  final int itemCount;
  final int weeklyNewCount;
  final int monthlyNewCount;

  const DataCardsSection({
    super.key,
    required this.itemCount,
    required this.weeklyNewCount,
    required this.monthlyNewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
        children: [
          DataCard(
            icon: Icons.inventory,
            target: itemCount,
            unit: '件',
            label: '物品总数',
            trendLabel: '$weeklyNewCount 本周新增',
            trendUp: true,
            color: AppColors.accentGold,
            decoColor: AppColors.shimmerGold,
            iconBgColor: AppColors.accentLightBg,
            iconColor: AppColors.accentGold,
            delayMs: 100,
          ),
          DataCard(
            icon: Icons.date_range,
            target: monthlyNewCount,
            unit: '件',
            label: '本月新增',
            trendLabel: '$weeklyNewCount 本周新增',
            trendUp: true,
            color: AppColors.success,
            decoColor: AppColors.shimmerGreen,
            iconBgColor: AppColors.success.withValues(alpha: 0.15),
            iconColor: AppColors.success,
            delayMs: 200,
          ),
        ],
      ),
    );
  }
}
