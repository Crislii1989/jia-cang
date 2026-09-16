import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/app_dimensions.dart';
import 'package:jia_cang/constants/design_metrics.dart';
import 'package:jia_cang/providers/profile_provider.dart';
import 'package:jia_cang/widgets/emoji_text.dart';

/// 资料卡（高保真稿 S5 `.row-c` + `.avatar`，2026-09-16 按稿重排）。
///
/// 稿子结构：46 圆头像（珊瑚渐变底 + emoji）→ 昵称（15/800）+
/// 副标「记录让生活有数」（11/ink2）→ 右侧箭头。**整卡可点**进编辑资料。
class ProfileHeaderSection extends ConsumerWidget {
  final VoidCallback onEdit;

  const ProfileHeaderSection({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = DesignMetrics.of(context);
    final profile = ref.watch(profileManagerProvider);

    return profile.when(
      skipLoadingOnReload: true,
      loading: () => _buildSkeleton(k),
      error: (_, __) => _buildSkeleton(k),
      data: (data) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onEdit,
          child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * k,
            vertical: 14 * k,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.floatCardShadow,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // 头像：稿子 .avatar 46 圆 + 珊瑚渐变底
              Container(
                width: 46 * k,
                height: 46 * k,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment(-0.6, -1),
                    end: Alignment(0.6, 1),
                    colors: AppColors.heroGradient,
                  ),
                ),
                alignment: Alignment.center,
                child: EmojiText(
                  emoji: data['avatar_emoji'] ?? '🧑',
                  fontSize: 22 * k,
                ),
              ),
              SizedBox(width: 10 * k),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['nickname'] ?? '小橘',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15 * k,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blushInk,
                      ),
                    ),
                    SizedBox(height: 2 * k),
                    Text(
                      '记录让生活有数',
                      style: TextStyle(
                        fontSize: 11 * k,
                        color: AppColors.blushInk2,
                      ),
                    ),
                  ],
                ),
              ),
              // 稿子右侧是箭头（编辑入口改为整卡可点）
              Icon(
                Icons.chevron_right,
                size: 16 * k,
                color: AppColors.blushInk3,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSkeleton(double k) {
    return Container(
      height: 74 * k,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.coral,
          ),
        ),
      ),
    );
  }
}
