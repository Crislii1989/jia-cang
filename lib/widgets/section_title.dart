import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final bool showMore;
  final VoidCallback? onMoreTap;
  final String moreText;

  /// 标题字号（默认 17；V2.6 首页区块标题用 13 更轻）
  final double titleSize;

  /// 标题颜色（默认主文字色；V2.x 页面传入新版深暖棕 blushInk）
  final Color? titleColor;

  /// 右侧「更多」文字颜色（默认三级文字；V2.6 首页传珊瑚深 coralDeep）
  final Color? moreColor;

  /// 右侧「更多」文字字号（默认 13；V2.6 首页用 11 更轻）
  final double moreSize;

  const SectionTitle({
    super.key,
    required this.title,
    this.showMore = false,
    this.onMoreTap,
    this.moreText = '查看全部 ›',
    this.titleSize = 17,
    this.titleColor,
    this.moreColor,
    this.moreSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: titleColor ?? AppColors.textPrimary,
            ),
          ),
          if (showMore)
            GestureDetector(
              onTap: onMoreTap,
              child: Text(
                moreText,
                style: TextStyle(
                  fontSize: moreSize,
                  color: moreColor ?? AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}