import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/app_text_styles.dart';
import 'package:jia_cang/constants/app_dimensions.dart';
import 'package:jia_cang/widgets/base_page.dart';
import 'package:jia_cang/widgets/card_container.dart';
import 'package:jia_cang/widgets/emoji_text.dart';
import 'package:jia_cang/widgets/floating_bar.dart';
import 'package:jia_cang/widgets/info_cell.dart';
import 'package:jia_cang/widgets/photo_carousel.dart';
import 'package:jia_cang/widgets/center_sheet.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/models/category.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/providers/storage_providers.dart';
import 'package:jia_cang/services/photo_service.dart';

class ItemDetailPage extends ConsumerWidget {
  final String itemId;

  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the items provider to ensure data is loaded
    final itemsState = ref.watch(itemsProvider);
    if (itemsState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final item = ref.watch(itemByIdProvider(itemId));

    if (item == null) {
      return Scaffold(body: Center(child: Text('未找到物品')));
    }

    return BasePage(
      // 操作条固定在屏幕底部（V2.6 悬浮圆角白条），内容区独立滚动
      useScrollView: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppDimensions.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: AppDimensions.spacingLarge),
                  _buildImageGallery(item),
                  const SizedBox(height: AppDimensions.spacingExtraLarge),
                  _buildItemHeader(item),
                  const SizedBox(height: AppDimensions.spacingExtraLarge),
                  _buildInfoSection(context, ref, item),
                  const SizedBox(height: AppDimensions.spacingExtraLarge),
                ],
              ),
            ),
          ),
          _buildBottomActions(context, ref, item),
        ],
      ),
    );
  }

  // ─── 顶部导航（随内容滚动）──────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '物品详情',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(Item item) {
    // 无照片：显示物品 emoji 作为占位
    if (item.photos.isEmpty) {
      return CardContainer(
        padding: const EdgeInsets.all(AppDimensions.spacingMedium),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusMedium,
            ),
          ),
          child: Center(child: EmojiText(emoji: '📦', fontSize: 96)),
        ),
      );
    }
    // 有照片：轮播组件
    return PhotoCarousel(photos: item.photos);
  }

  /// 底部操作条（V2.6）：与底部导航同一套悬浮圆角白条语言，
  /// 条内托两颗 40pt 胶囊按钮——编辑物品（主按钮）/ 删除物品（危险次要按钮）。
  Widget _buildBottomActions(BuildContext context, WidgetRef ref, Item item) {
    return FloatingBar(
      background: AppColors.actionBarBg,
      child: Row(
        children: [
          Expanded(
            child: FloatingBarButton(
              label: '编辑物品',
              icon: Icons.edit,
              tone: FloatingBarTone.primary,
              onTap: () => context.push('/edit_item/${item.id}'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FloatingBarButton(
              label: '删除物品',
              icon: Icons.delete_outline,
              tone: FloatingBarTone.danger,
              onTap: () => _confirmDelete(context, ref, item),
            ),
          ),
        ],
      ),
    );
  }

  /// 删除确认弹窗：二次确认后清理通知/照片并从数据库删除，最后返回上一页
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除物品'),
        content: Text('确定要删除「${item.name}」吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 清理物品照片文件
    for (final photo in item.photos) {
      PhotoService.instance.deleteFile(photo);
    }

    // 从数据库删除
    await ref.read(itemsProvider.notifier).removeItem(item.id);

    if (context.mounted) {
      context.pop();
    }
  }

  Widget _buildItemHeader(Item item) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: AppTextStyles.titleLarge),
          if (item.expiryDate != null) ...[
            const SizedBox(height: AppDimensions.spacingSmall),
            Text(
              '到期日: ${_formatDate(item.expiryDate!)}'
              '${_expiryHint(item.expiryDate!)}',
              style: AppTextStyles.subtitleText,
            ),
          ],
          const SizedBox(height: AppDimensions.spacingSmall),
          Text('位置: ${item.location}', style: AppTextStyles.subtitleText),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            '登记时间 ${_formatDate(item.createdAt)}',
            style: AppTextStyles.subtitleText,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// 到期提醒后缀：已过期 / 今天到期 / 还剩 N 天（30 天内才提示）。
  String _expiryHint(DateTime expiry) {
    final today = DateTime.now();
    final days = DateTime(expiry.year, expiry.month, expiry.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (days < 0) return '（已过期 ${-days} 天）';
    if (days == 0) return '（今天到期）';
    if (days <= 30) return '（还剩 $days 天）';
    return '';
  }

  Widget _buildInfoSection(BuildContext context, WidgetRef ref, Item item) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('详情', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacingMedium),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppDimensions.spacingMedium,
            crossAxisSpacing: AppDimensions.spacingLarge,
            childAspectRatio: 2.5,
            children: [
              // 库里存的是 key（sports），展示成中文名（运动），
              // 分类被删掉时退回显示原 key，不显示空白
              InfoCell(
                label: '分类',
                value: categoryLabelOf(
                  ref.watch(availableCategoriesProvider),
                  item.categoryKey,
                ),
              ),
              _LocationCell(
                label: '收纳位置',
                value: item.location,
                onTap: () => _changeLocation(context, ref, item),
              ),
              InfoCell(
                label: '添加时间',
                value:
                    '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')}',
              ),
            ],
          ),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingMedium),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimensions.spacingMedium),
            Text('备注', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppDimensions.spacingSmall),
            Text(
              item.note,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 修改物品收纳位置（联动柜体/格子）
  void _changeLocation(BuildContext context, WidgetRef ref, Item item) {
    // 在 await 之前取到 messenger：位置更新是异步的，跨异步间隙再用
    // 外层 BuildContext 会被 lint 判为 use_build_context_synchronously，
    // 弹窗关闭后该 context 还有失效风险。
    final messenger = ScaffoldMessenger.of(context);
    showCenterSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final asyncNodes = ref.watch(storageLocationTreeProvider);
            final allNodes = asyncNodes.value ?? const [];
            // 同时展示柜体与格子作为可选收纳位置
            final nodes = allNodes;
            // 当前选中的节点：格子 > 柜体 > 房间
            StorageLocationNode? current;
            if (item.slotId != null) {
              current = nodes
                  .where((n) => n.isSlot && n.id == item.slotId)
                  .cast<StorageLocationNode?>()
                  .firstWhere((_) => true, orElse: () => null);
            }
            current ??= item.cabinetId != null
                ? nodes
                      .where(
                        (n) => !n.isSlot && !n.isRoom && n.id == item.cabinetId,
                      )
                      .cast<StorageLocationNode?>()
                      .firstWhere((_) => true, orElse: () => null)
                : null;
            current ??= item.roomId != null
                ? nodes
                      .where((n) => n.isRoom && n.id == item.roomId)
                      .cast<StorageLocationNode?>()
                      .firstWhere((_) => true, orElse: () => null)
                : null;
            return _DetailLocationSheet(
              nodes: nodes,
              isLoading: asyncNodes.isLoading,
              selectedNode: current,
              onPick: (node) async {
                await ref
                    .read(itemsProvider.notifier)
                    .updateLocation(
                      id: item.id,
                      roomId: node.roomId,
                      cabinetId: node.cabinetId,
                      slotId: node.isSlot ? node.id : null,
                      locationLabel: node.pathLabel,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('已更新收纳位置：${node.pathLabel}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              onClear: () async {
                await ref
                    .read(itemsProvider.notifier)
                    .updateLocation(
                      id: item.id,
                      roomId: null,
                      cabinetId: null,
                      slotId: null,
                      locationLabel: '未指定',
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }
}

/// 详情页的位置单元格（可点击）
class _LocationCell extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LocationCell({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.labelMedium),
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 11, color: AppColors.coralDeep),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.infoValue(isAccent: true),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 详情页用的位置选择弹窗
class _DetailLocationSheet extends StatelessWidget {
  final List<StorageLocationNode> nodes;
  final bool isLoading;
  final StorageLocationNode? selectedNode;
  final ValueChanged<StorageLocationNode> onPick;
  final VoidCallback onClear;

  const _DetailLocationSheet({
    required this.nodes,
    required this.isLoading,
    required this.selectedNode,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSheetHeight = screenHeight * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '修改收纳位置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: '清除位置',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.coral,
                      ),
                    ),
                  )
                : nodes.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        '暂无可用格子区域\n请先在收纳页面添加柜体和格子',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: nodes.length,
                    itemBuilder: (ctx, i) {
                      final node = nodes[i];
                      final isSelected = selectedNode?.id == node.id;
                      return InkWell(
                        onTap: () => onPick(node),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.coralSoft
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.coral
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: node.isRoom
                                      ? const Color(0xFFD4F5D9)
                                      : node.isSlot
                                      ? const Color(0xFFE8F0FE)
                                      : const Color(0xFFFFF3CC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: EmojiText(
                                    emoji: node.emoji,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      node.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      node.subLabel,
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
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.coral,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
