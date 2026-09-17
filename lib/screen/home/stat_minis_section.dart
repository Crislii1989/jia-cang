import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/design_metrics.dart';
import 'package:jia_cang/providers/item_providers.dart';

/// 首页概览：一行四张**竖排统计高卡**（高保真稿 V2.6 定稿）。
///
/// 每张卡三段：线性图标（25）→ 数字（20/800，带「件」小单位）→ 标签（10.5）；
/// 卡底是各自色系的水彩渐变（粉 / 绿 / 蓝 / 紫），一眼区分四个维度。
/// 四个维度固定为：物品总数 / 即将到期 / 出借中 / 长期闲置。
/// 点击进物品库并按对应条件预筛（「物品总数」不带条件），
/// 预筛在物品库顶部显示为可一键清除的过滤 chip。
///
/// **尺寸全部经 [DesignMetrics] 等比换算**：设计稿是 320 机型（内容宽 292），
/// 直接写死绝对值会在宽视口下把卡片拉成横版、数字相对变小
/// （见 `design_metrics.dart` 的说明）。
class StatMinisSection extends ConsumerWidget {
  const StatMinisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = DesignMetrics.of(context);
    final total = ref.watch(itemCountProvider);
    final expiring = ref.watch(expiringSoonCountProvider);
    final lent = ref.watch(lentCountProvider);
    final idle = ref.watch(idleCountProvider);

    // 点击统一进物品库；除「物品总数」外都带上对应的预筛条件，
    // 由物品库消费（pendingInventoryFilterRequestProvider，应用后自清）。
    void goInventory() => context.go('/inventory');
    void goWithFilter(PendingInventoryFilter filter) {
      ref.read(pendingInventoryFilterRequestProvider.notifier).set(filter);
      // 预筛与分类预选互斥：带上预筛时清掉可能残留的分类请求
      ref.read(pendingCategoryProvider.notifier).set(null);
      context.go('/inventory');
    }

    final cards = <Widget>[
      _StatHighCard(
        value: total,
        label: '物品总数',
        icon: Icons.inventory_2_outlined,
        fg: AppColors.statHighPinkFg,
        bg: AppColors.statHighPink,
        onTap: goInventory,
      ),
      _StatHighCard(
        value: expiring,
        label: '即将到期',
        icon: Icons.schedule,
        fg: AppColors.statHighGreenFg,
        bg: AppColors.statHighGreen,
        onTap: () =>
            goWithFilter(const PendingInventoryFilter(special: 'expiring')),
      ),
      _StatHighCard(
        value: lent,
        label: '出借中',
        icon: Icons.send_outlined,
        fg: AppColors.statHighBlueFg,
        bg: AppColors.statHighBlue,
        onTap: () =>
            goWithFilter(const PendingInventoryFilter(status: 'lent')),
      ),
      _StatHighCard(
        value: idle,
        label: '长期闲置',
        icon: Icons.dark_mode_outlined,
        fg: AppColors.statHighPurpleFg,
        bg: AppColors.statHighPurple,
        onTap: () =>
            goWithFilter(const PendingInventoryFilter(special: 'idle')),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Row(
        // 不用 stretch：本 Row 位于 ListView 内，交叉轴高度无界，
        // stretch 会要求无限高度。四张卡结构完全一致，自然高度即相等。
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(width: 7 * k),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }
}

/// 竖排统计高卡：水彩渐变底 + 线性图标 / 数字 / 标签三段。
class _StatHighCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color fg;
  final List<Color> bg;
  final VoidCallback onTap;

  const _StatHighCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final k = DesignMetrics.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(5 * k, 10 * k, 5 * k, 11 * k),
        decoration: BoxDecoration(
          // 158deg：近似「自上而下略斜」的水彩渐变
          gradient: LinearGradient(
            begin: const Alignment(-0.4, -1),
            end: const Alignment(0.4, 1),
            colors: bg,
          ),
          borderRadius: BorderRadius.circular(15 * k),
          border: Border.all(color: AppColors.floatHairlineSoft),
          boxShadow: [
            BoxShadow(
              color: AppColors.floatCardShadow,
              blurRadius: 10 * k,
              offset: Offset(0, 3 * k),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 25 * k, color: fg),
            SizedBox(height: 7 * k),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$value',
                    style: TextStyle(
                      fontSize: 20 * k,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6 * k,
                      height: 1.05,
                      color: fg,
                    ),
                  ),
                  TextSpan(
                    text: '件',
                    style: TextStyle(
                      fontSize: 11 * k,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8 * k),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5 * k,
                color: AppColors.statHighLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
