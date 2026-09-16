import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:jia_cang/constants/app_colors.dart';
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
    return Scaffold(
      // 透明：透出 MainShell 那一片全局背景
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.coral,
            onRefresh: _onRefresh,
            child: ListView(
              // 底部 12：滚到底时最后一张卡与悬浮导航条之间的呼吸位（V2.5）
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              children: [
                _buildHeaderContent(),
                const SizedBox(height: 10),
                _buildSearchBar(),
                const SizedBox(height: 10),
                const StatMinisSection(),
                const SizedBox(height: 10),
                SectionTitle(
                  title: '分类',
                  titleSize: 13,
                  moreSize: 11,
                  titleColor: AppColors.blushInk,
                  showMore: true,
                  moreText: '全部 ›',
                  moreColor: AppColors.coralDeep,
                  onMoreTap: () => context.push('/categories'),
                ),
                const SizedBox(height: 10),
                const CategoryCirclesSection(),
                const SizedBox(height: 10),
                SectionTitle(
                  title: '提醒',
                  titleSize: 13,
                  moreSize: 11,
                  titleColor: AppColors.blushInk,
                  showMore: true,
                  moreText: '全部 ›',
                  moreColor: AppColors.coralDeep,
                  onMoreTap: () => context.go('/inventory'),
                ),
                const SizedBox(height: 10),
                const ReminderSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 搜索条大胶囊（46pt，V2.1 参考图规格）：假输入框，点击进物品库
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go('/inventory'),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.floatHairline),
            boxShadow: const [
              BoxShadow(
                color: AppColors.floatCardShadow,
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 17, color: AppColors.blushInk3),
              SizedBox(width: 9),
              Text(
                '搜索物品名称 / 位置',
                style: TextStyle(fontSize: 12.5, color: AppColors.blushInk3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greetInk,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.favorite,
                      size: 15,
                      color: AppColors.greetHeart,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateText · $subtitle',
                  style: const TextStyle(fontSize: 11, color: AppColors.greetSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 头部右侧：线描房子（V2.1 参考图，替换原来的珊瑚渐变小房子头像）
          const Icon(
            Icons.home_outlined,
            size: 30,
            color: AppColors.homeHouseIcon,
          ),
        ],
      ),
    );
  }
}
