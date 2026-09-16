import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// 状态徽标类型（对应高保真稿状态四色 + 中性）
enum BadgeType { ok, warn, danger, info, muted }

/// 状态徽标（全局统一组件）。
///
/// 在库→[BadgeType.ok]、出借→[BadgeType.info]、临期→[BadgeType.warn]、
/// 逾期→[BadgeType.danger]、闲置等中性信息→[BadgeType.muted]。
/// 颜色令牌取自 AppColors 的 UI 改版段，禁止页面内写死色值。
///
/// ⚠️ 现状（V2.6 复审）：**当前没有生产调用方** —— 物品库用的是页面内私有
/// `_buildStatusBadge`，首页提醒卡用 `AppColors.reminder*` 三档色直接画文字。
/// 本组件仅由 `test/widgets/overview_stat_card_test.dart` 覆盖。
/// 处置待定：下一轮统一徽标样式时收敛到它，或明确退役并连测试一起删。
class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = BadgeType.muted,
  });

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (type) {
      BadgeType.ok => (AppColors.safeGreen, AppColors.safeGreenBg),
      BadgeType.warn => (AppColors.coralDeep, AppColors.coralSoft),
      BadgeType.danger => (AppColors.alertRed, AppColors.alertRedBg),
      BadgeType.info => (AppColors.lendBlue, AppColors.lendBlueBg),
      BadgeType.muted => (AppColors.blushInk2, AppColors.statPeachBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
