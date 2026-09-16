import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/home_metrics.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/providers/profile_provider.dart';
import 'package:jia_cang/widgets/gradient_background.dart';
import 'package:jia_cang/widgets/section_title.dart';
import 'package:jia_cang/widgets/toast_utils.dart';
import 'category_circles_section.dart';
import 'reminder_section.dart';
import 'stat_minis_section.dart';

/// 首页（高保真稿 V2.6 定稿）。
///
/// 自上而下：水彩头部（问候 + 线描房子）→ 46pt 大搜索胶囊 →
/// 四张竖排统计高卡（线性图标 / 数字 / 标签）→ 分类大圆一行 4 个 →
/// 提醒卡组（行间细分割线 + 右侧日期）。
///
/// 背景走全局那一片（[GradientBackground]，V2.2/V2.3 起 S1~S5 共用，
/// 内容滚动时固定不动），页面自身不再画光晕。
///
/// 所有尺寸经 [HomeMetrics] 按设计稿（320 机型 / 内容宽 292）等比换算——
/// 设计值是绝对值，运行时容器却是流式的，不换算就会在宽视口下失真。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Future<void> _onRefresh() async {
    // 真正刷新：invalidate itemsProvider 触发重新从数据库读取
    ref.invalidate(itemsProvider);
    // 等待数据加载完成，使 RefreshIndicator 的 spinner 保持到数据就绪
    await ref.read(itemsProvider.future).catchError((_) => <Item>[]);
    if (mounted) {
      ToastUtils.show(context, '数据已刷新 \u{1F389}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = HomeMetrics.of(context);

    return Scaffold(
      // 透明：透出 MainShell 那一片全局背景
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.coral,
            onRefresh: _onRefresh,
            child: ListView(
              // 底部 12：滚到底时最后一张卡与悬浮导航条之间的呼吸位（V2.5）。
              // 这条与悬浮条 `bottomGap 8 + 条高 60` 是配套的固定值，**不参与缩放**。
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              children: [
                _buildHeaderContent(k),
                SizedBox(height: 10 * k),
                _buildSearchBar(k),
                SizedBox(height: 10 * k),
                const StatMinisSection(),
                SizedBox(height: 10 * k),
                SectionTitle(
                  title: '分类',
                  titleSize: 13 * k,
                  moreSize: 11 * k,
                  titleColor: AppColors.blushInk,
                  showMore: true,
                  moreText: '全部 ›',
                  moreColor: AppColors.coralDeep,
                  onMoreTap: () => context.push('/categories'),
                ),
                SizedBox(height: 10 * k),
                const CategoryCirclesSection(),
                SizedBox(height: 10 * k),
                SectionTitle(
                  title: '提醒',
                  titleSize: 13 * k,
                  moreSize: 11 * k,
                  titleColor: AppColors.blushInk,
                  showMore: true,
                  moreText: '全部 ›',
                  moreColor: AppColors.coralDeep,
                  onMoreTap: () => context.go('/inventory'),
                ),
                SizedBox(height: 10 * k),
                const ReminderSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 搜索条大胶囊（46pt，V2.1 参考图规格）：假输入框，点击进物品库
  Widget _buildSearchBar(double k) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeMetrics.pageMargin),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go('/inventory'),
        child: Container(
          height: 46 * k,
          padding: EdgeInsets.symmetric(horizontal: 16 * k),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.floatHairline),
            boxShadow: [
              BoxShadow(
                color: AppColors.floatCardShadow,
                blurRadius: 12 * k,
                offset: Offset(0, 3 * k),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 17 * k, color: AppColors.blushInk3),
              SizedBox(width: 9 * k),
              Text(
                '搜索物品名称 / 位置',
                style: TextStyle(fontSize: 12.5 * k, color: AppColors.blushInk3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent(double k) {
    final profile = ref.watch(profileManagerProvider);
    final nickname = profile.asData?.value['nickname'] ?? '小橘';
    final hour = DateTime.now().hour;
    final String greeting;
    final String subtitle;
    if (hour < 5) {
      greeting = '凌晨好';
      subtitle = '夜深了，注意休息';
    } else if (hour < 11) {
      greeting = '早上好';
      subtitle = '新的一天，从整理开始';
    } else if (hour < 13) {
      greeting = '中午好';
      subtitle = '午间时光，轻松盘点';
    } else if (hour < 18) {
      greeting = '傍晚好';
      subtitle = '夕阳西下，整理收尾';
    } else {
      greeting = '晚上好';
      subtitle = '晚安前，回顾今日';
    }

    final now = DateTime.now();
    final dateText = '${now.month} 月 ${now.day} 日';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeMetrics.pageMargin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$greeting，$nickname',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 21 * k,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greetInk,
                          letterSpacing: 0.5 * k,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(width: 6 * k),
                    Icon(
                      Icons.favorite,
                      size: 15 * k,
                      color: AppColors.greetHeart,
                    ),
                  ],
                ),
                SizedBox(height: 4 * k),
                Text(
                  '$dateText · $subtitle',
                  style: TextStyle(fontSize: 11 * k, color: AppColors.greetSub),
                ),
              ],
            ),
          ),
          SizedBox(width: 12 * k),
          // 头部右侧：线描房子（V2.1 参考图，替换原来的珊瑚渐变小房子头像）
          Icon(
            Icons.home_outlined,
            size: 30 * k,
            color: AppColors.homeHouseIcon,
          ),
        ],
      ),
    );
  }
}
