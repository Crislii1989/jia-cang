import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_metrics.dart';

/// 外观功能的页面顶栏（列表页与新建/编辑页共用）。
///
/// 沿用全库统一的「38 圆角白卡返回钮 + 标题」，不用 AppBar。
class AppearanceTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppearanceTopBar({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final k = DesignMetrics.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignMetrics.pageMargin,
        8 * k,
        DesignMetrics.pageMargin,
        0,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38 * k,
              height: 38 * k,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12 * k),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.floatCardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.chevron_left,
                size: 20 * k,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: 12 * k),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18 * k,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 1 * k),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11 * k,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
