import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../models/enums/tab_type.dart';
import 'floating_bar.dart';

/// 底部导航（高保真稿 V2.6 定稿：悬浮白色圆角条 + 线性图标 + 中央珊瑚圆钮）。
///
/// 几何全部来自 [FloatingBar]：比内容卡**每侧宽出 6**、高 60、圆角 20、
/// 距屏幕底部 8（再叠系统安全区）；**无顶部分割线、无激活指示线**；
/// 条底是半透明白 .86（透出全局背景）——**不用毛玻璃，无 BackdropFilter**。
///
/// 槽位：首页 / 物品库 / ＋添加（不属于 Tab，点击 push /add_item）/ 收纳 / 我的。
/// 图标用 Material 的「描边 ↔ 实心」两态，语义对齐设计稿里的线性 SVG：
/// 房子 / 收纳盒 / 收纳格 / 人像；选中态＝实心图标 + 珊瑚粉文字（#E8807F），
/// 未选中＝描边图标 + 暖棕文字（#9A7C5C）。中央圆钮缩到 40px 并落回条内。
class BottomNavBar extends StatelessWidget {
  final TabType currentTab;
  final ValueChanged<TabType> onTabChanged;

  const BottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingBar(
      background: AppColors.navBarBg,
      padding: FloatingBar.navBarPadding,
      child: Row(
        children: [
          _buildNavItem(
            TabType.home,
            '首页',
            Icons.home_outlined,
            Icons.home,
          ),
          _buildNavItem(
            TabType.inventory,
            '物品库',
            Icons.inventory_2_outlined,
            Icons.inventory_2,
          ),
          _buildCenterAddButton(context),
          _buildNavItem(
            TabType.stats,
            '收纳',
            Icons.archive_outlined,
            Icons.archive,
          ),
          _buildNavItem(TabType.me, '我的', Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

  /// 中央添加钮：占一个固定 40 槽位，保证 4 Tab 均匀分布；
  /// 40px 圆钮仍落在 60 高的条内（只整体上提 6，不探出条外）。
  Widget _buildCenterAddButton(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Center(
        child: GestureDetector(
          onTap: () => context.push('/add_item'),
          child: Container(
            width: 40,
            height: 40,
            transform: Matrix4.translationValues(0, -6, 0),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.addFab,
              boxShadow: [
                BoxShadow(
                  color: AppColors.addFabShadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    TabType tab,
    String label,
    IconData inactiveIcon,
    IconData activeIcon,
  ) {
    final isActive = currentTab == tab;
    final color = isActive ? AppColors.navActive : AppColors.navInactive;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabChanged(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : inactiveIcon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
