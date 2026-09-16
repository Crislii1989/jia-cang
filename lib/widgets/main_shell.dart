import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/widgets/bottom_nav_bar.dart';
import 'package:jia_cang/models/enums/tab_type.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 悬浮导航条周围的底色（各 Tab 页自己铺全局背景，这里只托住条四周的缝）
      backgroundColor: AppColors.blushBg,
      body: navigationShell,
      // UI 改版（V2.4~V2.6）：导航条改为悬浮圆角白条，中央添加钮内置在其中，
      // 不再用 Stack 浮层叠加，添加入口唯一收敛到导航栏中央。
      bottomNavigationBar: BottomNavBar(
        currentTab: TabType.values[navigationShell.currentIndex],
        onTabChanged: (tab) {
          navigationShell.goBranch(
            tab.index,
            initialLocation: tab.index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
