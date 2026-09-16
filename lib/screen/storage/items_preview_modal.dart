import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/item.dart';
import '../../widgets/center_sheet.dart';
import '../../widgets/emoji_text.dart';

/// 物品预览模态框 — 展示某个格子/区域内的物品列表，支持批量迁移与批量删除。
/// 数据源为 items 表（主物品），按 slotId 过滤。
class ItemsPreviewModal extends StatelessWidget {
  final String title;
  final List<Item> items;
  final Set<String> selectedItemIds; // 使用 Item.id（UUID 字符串）
  final VoidCallback onClose;
  final ValueChanged<String> onToggleItem;
  final VoidCallback onBatchMigrate;
  final VoidCallback onBatchDelete;

  const ItemsPreviewModal({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItemIds,
    required this.onClose,
    required this.onToggleItem,
    required this.onBatchMigrate,
    required this.onBatchDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 浮层居中展示（原为贴底弹窗，下面两个角是直角）。
    // 严格限制浮层最高高度为当前屏幕高度的 50%
    return CenterModalShell(
      onDismiss: onClose,
      maxHeightFactor: 0.5,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedItemIds.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '已选 ${selectedItemIds.length} 项',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.coralDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // 物品列表（可滚动，受 maxHeight 约束）
                    Flexible(
                      child: items.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  '该格子暂无物品',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: items.length,
                              itemBuilder: (ctx, i) {
                                final item = items[i];
                                final isSelected = selectedItemIds.contains(
                                  item.id,
                                );
                                return _buildItemListTile(item, isSelected);
                              },
                            ),
                    ),
                    // 批量操作按钮
                    if (selectedItemIds.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // 批量迁移
                          Expanded(
                            child: GestureDetector(
                              onTap: onBatchMigrate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  // 次要按钮走稿子 `.btn.ghost`
                                  color: AppColors.btnGhostBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.btnGhostBorder,
                                    width: AppColors.btnGhostBorderWidth,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '批量迁移',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.btnGhostFg,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // 批量删除
                          Expanded(
                            child: GestureDetector(
                              onTap: onBatchDelete,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  // 危险行动：稿子的 `--red-soft` 浅底 + `--red` 字
                                  color: AppColors.btnDangerBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.btnDangerFg.withValues(
                                      alpha: 0.35,
                                    ),
                                    width: AppColors.btnGhostBorderWidth,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    '批量删除',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.btnDangerFg,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildItemListTile(Item item, bool isSelected) {
    // 副标题：位置（位置未知时回退到备注）
    final meta = item.location == '未知' || item.location.isEmpty
        ? (item.note.isEmpty ? '未设置位置' : item.note)
        : item.location;
    return GestureDetector(
      onTap: () => onToggleItem(item.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0E4D0), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: EmojiText(emoji: String.fromCharCode(0x1F4E6), fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.chipSelectedBg : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.chipSelectedBg
                      : const Color(0xFFF0E4D0),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.chipSelectedFg,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
