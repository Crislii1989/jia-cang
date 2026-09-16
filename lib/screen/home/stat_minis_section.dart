import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/providers/item_providers.dart';

/// 首页概览：一行四张**竖排统计高卡**（高保真稿 V2.6 定稿）。
///
/// 每张卡三段：线性图标（25）→ 数字（20/800，带「件」小单位）→ 标签（10.5）；
/// 卡底是各自色系的水彩渐变（粉 / 绿 / 蓝 / 紫），一眼区分四个维度。
/// 四个维度固定为：物品总数 / 即将到期 / 出借中 / 长期闲置。
/// 点击统一进物品库——后续接入「按条件预筛」时只需在这里改跳转参数。
class StatMinisSection extends ConsumerWidget {
  const StatMinisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(itemCountProvider);
    final expiring = ref.watch(expiringSoonCountProvider);
    final lent = ref.watch(lentCountProvider);
    final idle = ref.watch(idleCountProvider);

    void goInventory() => context.go('/inventory');

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
        onTap: goInventory,
      ),
      _StatHighCard(
        value: lent,
        label: '出借中',
        icon: Icons.send_outlined,
        fg: AppColors.statHighBlueFg,
        bg: AppColors.statHighBlue,
        onTap: goInventory,
      ),
      _StatHighCard(
        value: idle,
        label: '长期闲置',
        icon: Icons.dark_mode_outlined,
        fg: AppColors.statHighPurpleFg,
        bg: AppColors.statHighPurple,
        onTap: goInventory,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        // 不用 stretch：本 Row 位于 ListView 内，交叉轴高度无界，
        // stretch 会要求无限高度。四张卡结构完全一致，自然高度即相等。
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 7),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 11),
        decoration: BoxDecoration(
          // 158deg：近似「自上而下略斜」的水彩渐变
          gradient: LinearGradient(
            begin: const Alignment(-0.4, -1),
            end: const Alignment(0.4, 1),
            colors: bg,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.floatHairlineSoft),
          boxShadow: const [
            BoxShadow(
              color: AppColors.floatCardShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 25, color: fg),
            const SizedBox(height: 7),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$value',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.05,
                      color: fg,
                    ),
                  ),
                  TextSpan(
                    text: '件',
                    style: TextStyle(
                      fontSize: 11,
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
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.statHighLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
