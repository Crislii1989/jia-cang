import 'package:flutter/material.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/models/platform_data.dart';
import 'package:jia_cang/widgets/emoji_text.dart';

/// Bottom sheet tutorial widget for a given platform.
class PlatformTutorialSheet extends StatelessWidget {
  final PlatformData platform;
  final VoidCallback onConfirm;

  const PlatformTutorialSheet({
    super.key,
    required this.platform,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    EmojiText(emoji: platform.emoji, fontSize: 24),
                    const SizedBox(width: 10),
                    Text(
                      '${platform.name}授权导入',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Steps
            ...List.generate(platform.steps.length, (i) {
              final step = platform.steps[i];
              final isLast = i == platform.steps.length - 1;
              return _TutorialStepWidget(
                index: i + 1,
                step: step,
                isLast: isLast,
              );
            }),
            const SizedBox(height: 6),
            // Confirm button
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  // 主按钮 = 实心珊瑚（稿子 `.btn.primary` 无渐变）
                  color: AppColors.btnPrimaryBg,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.btnPrimaryShadow,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    platform.connected ? '📱 重新授权并导入' : '🔑 授权并开始导入',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.btnPrimaryFg,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Dismiss button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.background,
                ),
                child: Center(
                  child: Text(
                    '暂不导入',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single tutorial step widget with index badge and connecting line.
class _TutorialStepWidget extends StatelessWidget {
  final int index;
  final TutorialStep step;
  final bool isLast;

  const _TutorialStepWidget({
    required this.index,
    required this.step,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index + connector line
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.btnPrimaryBg,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.btnPrimaryFg,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
