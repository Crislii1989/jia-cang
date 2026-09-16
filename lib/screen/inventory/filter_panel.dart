import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide DatePickerTheme;
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/app_dimensions.dart';
import 'package:jia_cang/widgets/center_sheet.dart';
import 'package:jia_cang/widgets/pill_content.dart';

/// Callback signature for when filters are applied.
typedef FilterApplyCallback = void Function(String? location);

/// Standalone filter panel shown as a modal bottom sheet.
class FilterPanel extends StatefulWidget {
  final String? initialLocation;
  final FilterApplyCallback onApply;
  final VoidCallback onReset;

  /// 外部关闭信号：值每次自增表示请求关闭弹窗。
  /// 用于跨分支跳转场景（首页快捷入口 → 物品库）：宿主页（InventoryPage）
  /// 的 build context 解析到的 Navigator 未必是承载弹窗的那个（showModalBottomSheet
  /// 默认 useRootNavigator=false，弹窗 push 到最近层导航器），因此由宿主页通过
  /// 此信号通知弹窗用【自身 context】执行 pop，确保命中正确的 Navigator。
  final ValueListenable<int>? dismissSignal;

  const FilterPanel({
    super.key,
    this.initialLocation,
    required this.onApply,
    required this.onReset,
    this.dismissSignal,
  });

  /// Convenience method to show the filter panel as a bottom sheet.
  /// 返回的 Future 在弹窗关闭时完成，调用方可据此感知关闭时机。
  static Future<void> show(
    BuildContext context, {
    String? initialLocation,
    required FilterApplyCallback onApply,
    required VoidCallback onReset,
    ValueListenable<int>? dismissSignal,
  }) async {
    await showCenterSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterPanel(
        initialLocation: initialLocation,
        onApply: onApply,
        onReset: onReset,
        dismissSignal: dismissSignal,
      ),
    );
  }

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late String? _selectedLocation = widget.initialLocation;

  /// 收到关闭信号时，用弹窗自身 context 关闭自己。
  /// 此处 context 处于 showModalBottomSheet 创建的 modal route 内，
  /// Navigator.of(context) 必然命中承载该弹窗的导航器，pop 一定生效。
  void _onDismissSignal() {
    if (!mounted) return;
    final signal = widget.dismissSignal;
    if (signal != null && signal.value > 0) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.dismissSignal?.addListener(_onDismissSignal);
  }

  @override
  void dispose() {
    widget.dismissSignal?.removeListener(_onDismissSignal);
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedLocation = null;
    });
    widget.onReset();
  }

  void _applyFilters() {
    Navigator.of(context).pop(); // close bottom sheet
    widget.onApply(_selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        // 这里是**居中弹窗**（showCenterSheet 用 Dialog 承载），不是贴底的
        // bottom sheet。原先只圆上沿两个角，下沿就成了直角边，和整体圆角
        // 风格以及弹窗的四角都对不上；居中弹窗四个角必须一起圆。
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXLarge),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '筛选条件',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _resetFilters,
                  child: const Text(
                    '重置',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.btnTextFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Location
            _buildFilterSection(
              label: '收纳位置',
              options: ['全部', '客厅', '卧室', '书房', '厨房', '储物间'],
              selected: _selectedLocation,
              onSelect: (v) => setState(() => _selectedLocation = v),
            ),
            const SizedBox(height: 16),
            // Confirm button
            GestureDetector(
              onTap: _applyFilters,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  // 主按钮 = 实心珊瑚（稿子 `.btn.primary` 无渐变）
                  color: AppColors.btnPrimaryBg,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusExtraLarge,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.btnPrimaryShadow,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '确认筛选',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.btnPrimaryFg,
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

  Widget _buildFilterSection({
    required String label,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            // 默认（null）与重置后，首个「全部/不限」选项应显示为选中态，
            // 让用户直观看到当前未施加任何筛选。
            final isSelected = selected == null
                ? opt == options.first
                : selected == opt;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  // 选中态：实心珊瑚 + 白字（所有页面 chip 统一走 AppColors.chip* 令牌）
                  color: isSelected
                      ? AppColors.chipSelectedBg
                      : AppColors.chipBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.chipSelectedBg
                        : AppColors.chipBorder,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.btnPrimaryShadow,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Transform.translate(
                  // Web 端 CJK 回退字体墨水相对行盒偏下，光学补偿拉回居中
                  //（说明见 PillContent.kWebTextOpticalLift；原生端不挪）
                  offset: Offset(
                    0,
                    kIsWeb ? PillContent.kWebTextOpticalLift : 0.0,
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.chipSelectedFg
                          : AppColors.chipFg,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
