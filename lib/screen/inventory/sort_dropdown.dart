import 'package:flutter/material.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/app_dimensions.dart';
import 'package:jia_cang/models/enums/sort_type.dart';

/// Sort dropdown overlay widget.
class SortDropdown extends StatelessWidget {
  final SortType currentSort;
  final ValueChanged<SortType> onSortSelected;

  const SortDropdown({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageMarginHorizontal,
        4,
        AppDimensions.pageMarginHorizontal,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusExtraLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.14),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: SortType.values.map((type) {
              final isActive = currentSort == type;
              return GestureDetector(
                onTap: () => onSortSelected(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.coralSoft : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        kSortFullLabels[type]!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? AppColors.coralDeep
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isActive)
                        const Icon(
                          Icons.check,
                          size: 18,
                          color: AppColors.coralDeep,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
