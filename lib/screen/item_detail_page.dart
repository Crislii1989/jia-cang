import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/app_dimensions.dart';
import 'package:jia_cang/constants/design_metrics.dart';
import 'package:jia_cang/models/category.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/providers/storage_providers.dart';
import 'package:jia_cang/services/photo_service.dart';
import 'package:jia_cang/widgets/base_page.dart';
import 'package:jia_cang/widgets/center_sheet.dart';
import 'package:jia_cang/widgets/emoji_text.dart';
import 'package:jia_cang/widgets/floating_bar.dart';
import 'package:jia_cang/widgets/photo_carousel.dart';
import 'package:jia_cang/widgets/toast_utils.dart';

/// 物品详情页（高保真稿 S3，2026-09-16 按稿改版）。
///
/// 结构（自上而下）：沉浸大图（珊瑚渐变底 + 白色返回钮 + 底部圆点）→
/// 大标题 + 状态/分类徽标 → 到期日条（珊瑚浅底，可点改日期）→
/// 信息组（存放位置 / 登记时间 / 备注 三行，仅存放位置可点）。
/// 删除是**左下角贴边固定旋钮**；底部悬浮条只留「出借 / 编辑」两颗胶囊。
///
/// 所有尺寸经 [DesignMetrics] 按设计稿（320 机型 / 内容宽 292）等比换算；
/// 例外：删除旋钮与底部条 —— 它们是固定 chrome，保持原尺寸才不会与条脱节。
class ItemDetailPage extends ConsumerWidget {
  final String itemId;

  const ItemDetailPage({super.key, required this.itemId});

  /// 状态 → 中文（与物品库 `_statusLabels` 同一套文案，别各写各的）
  static const Map<String, String> _statusLabels = {
    'safe': '在库',
    'lent': '借出',
    'lost': '丢失',
    'used': '已用',
  };

  /// 状态 → 徽标配色（对应稿子 `.badge` 的四档 `.bg-*`）
  static const Map<String, List<Color>> _statusBadgeColors = {
    'safe': [AppColors.statGreen, AppColors.statGreenBg],
    'lent': [AppColors.statBlue, AppColors.statBlueBg],
    'lost': [AppColors.alertRed, AppColors.alertRedBg],
    'used': [AppColors.blushInk2, AppColors.statPeachBg],
  };

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

    final k = DesignMetrics.of(context);

    return BasePage(
      // 操作条固定在屏幕底部（V2.6 悬浮圆角白条），内容区独立滚动
      useScrollView: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    DesignMetrics.pageMargin,
                    8,
                    DesignMetrics.pageMargin,
                    AppDimensions.spacingMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(context, ref, item, k),
                      SizedBox(height: 10 * k),
                      _buildTitleAndBadges(context, ref, item, k),
                      SizedBox(height: 10 * k),
                      if (item.expiryDate != null) ...[
                        _buildExpiryRow(context, ref, item, k),
                        SizedBox(height: 10 * k),
                      ],
                      _buildInfoGroup(context, ref, item, k),
                    ],
                  ),
                ),
              ),
              _buildBottomActions(context, ref, item),
            ],
          ),
          // 删除旋钮：贴左、悬浮条上方（稿子 .delknob left:14 / bottom:76）
          Positioned(
            left: AppDimensions.delKnobInset,
            bottom: AppDimensions.delKnobBottom,
            child: _DeleteKnob(onTap: () => _confirmDelete(context, ref, item)),
          ),
        ],
      ),
    );
  }

  // ─── 沉浸大图 ──────────────────────────────────────────

  Widget _buildHero(BuildContext context, WidgetRef ref, Item item, double k) {
    // 无照片：用所属分类的 emoji 当占位图形（稿子画的就是分类那颗 🎮）
    final emoji = categoryEmojiOf(
      ref.watch(availableCategoriesProvider),
      item.categoryKey,
    );
    const gradient = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(-0.3, -1),
        end: Alignment(0.3, 1),
        colors: AppColors.heroGradient,
      ),
    );

    final body = item.photos.isEmpty
        ? DecoratedBox(
            decoration: gradient,
            child: Center(child: EmojiText(emoji: emoji, fontSize: 64 * k)),
          )
        : PhotoCarousel(
            photos: item.photos,
            height: AppDimensions.heroHeight * k,
            background: gradient,
            dotIndicator: true,
            showNavButtons: false,
          );

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.heroRadius * k),
          child: SizedBox(
            width: double.infinity,
            height: AppDimensions.heroHeight * k,
            child: body,
          ),
        ),
        // 白色圆形返回钮（稿子 .icon-btn 30 + top/left 10）
        Positioned(
          top: AppDimensions.heroBackInset * k,
          left: AppDimensions.heroBackInset * k,
          child: _BackButton(k: k),
        ),
      ],
    );
  }

  // ─── 标题 + 徽标 ───────────────────────────────────────

  Widget _buildTitleAndBadges(
    BuildContext context,
    WidgetRef ref,
    Item item,
    double k,
  ) {
    final categoryLabel = categoryLabelOf(
      ref.watch(availableCategoriesProvider),
      item.categoryKey,
    );
    final badgeColors =
        _statusBadgeColors[item.status] ?? _statusBadgeColors['safe']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: TextStyle(
            fontSize: 18 * k,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: AppColors.blushInk,
          ),
        ),
        SizedBox(height: 6 * k),
        Row(
          children: [
            _Badge(
              text: _statusLabels[item.status] ?? item.status,
              fg: badgeColors[0],
              bg: badgeColors[1],
              k: k,
            ),
            SizedBox(width: 6 * k),
            _Badge(
              text: categoryLabel,
              fg: AppColors.blushInk2,
              bg: AppColors.statPeachBg,
              k: k,
            ),
          ],
        ),
      ],
    );
  }

  // ─── 到期日条 ──────────────────────────────────────────

  Widget _buildExpiryRow(
    BuildContext context,
    WidgetRef ref,
    Item item,
    double k,
  ) {
    final expiry = item.expiryDate!;
    final hint = _expiryHint(expiry);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _editExpiry(context, ref, item),
      child: Container(
        height: 60 * k,
        padding: EdgeInsets.symmetric(horizontal: 16 * k),
        decoration: BoxDecoration(
          color: AppColors.coralSoft,
          borderRadius: BorderRadius.circular(12 * k),
          border: Border.all(color: AppColors.expiryRowBorder),
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            EmojiText(emoji: '⏰', fontSize: 14 * k),
            SizedBox(width: 10 * k),
            Text(
              '到期日',
              style: TextStyle(
                fontSize: 13 * k,
                fontWeight: FontWeight.w700,
                color: AppColors.blushInk,
              ),
            ),
            SizedBox(width: 6 * k),
            // 日期是本行的关键信息：空间不够时整体缩一点（scaleDown），
            // 不做省略截断；提示短句放不下才省略
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _formatDate(expiry),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13 * k,
                    fontWeight: FontWeight.w700,
                    color: AppColors.coralDeep,
                  ),
                ),
              ),
            ),
            if (hint.isNotEmpty) ...[
              SizedBox(width: 6 * k),
              Text(
                '· $hint',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12 * k,
                  fontWeight: FontWeight.w700,
                  color: AppColors.expiryHint,
                ),
              ),
            ],
            const Spacer(),
            Icon(Icons.chevron_right, size: 15 * k, color: AppColors.blushInk3),
          ],
        ),
      ),
    );
  }

  // ─── 信息组 ────────────────────────────────────────────

  Widget _buildInfoGroup(
    BuildContext context,
    WidgetRef ref,
    Item item,
    double k,
  ) {
    Widget row(
      String emoji,
      String label,
      String value, {
      bool showChevron = false,
      VoidCallback? onTap,
    }) {
      return _InfoRow(
        emoji: emoji,
        label: label,
        value: value,
        k: k,
        showChevron: showChevron,
        onTap: onTap,
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias, // 圆角卡片有子内容顶边，必须显式裁剪
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12 * k),
        border: Border.all(color: AppColors.blushLine),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          row(
            '📍',
            '存放位置',
            item.location,
            showChevron: true,
            onTap: () => _changeLocation(context, ref, item),
          ),
          Container(height: 1, color: AppColors.cellDivider),
          row('🗓', '登记时间', _formatDate(item.createdAt)),
          Container(height: 1, color: AppColors.cellDivider),
          row('📝', '备注', item.note.isEmpty ? '暂无备注' : item.note),
        ],
      ),
    );
  }

  // ─── 底部操作条 + 删除旋钮 ─────────────────────────────

  /// 底部操作条（V2.6 悬浮圆角白条）：出借（ghost，点了在 在库↔借出 间切换）+
  /// 编辑（primary）。删除不在条里——它已经搬到左下角的固定旋钮上。
  Widget _buildBottomActions(BuildContext context, WidgetRef ref, Item item) {
    final isLent = item.status == 'lent';
    return FloatingBar(
      background: AppColors.actionBarBg,
      child: Row(
        children: [
          Expanded(
            child: FloatingBarButton(
              label: isLent ? '归还' : '出借',
              icon: isLent ? Icons.undo : Icons.upload_outlined,
              tone: FloatingBarTone.ghost,
              onTap: () => _toggleLend(context, ref, item),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FloatingBarButton(
              label: '编辑',
              icon: Icons.edit_outlined,
              tone: FloatingBarTone.primary,
              onTap: () => context.push('/edit_item/${item.id}'),
            ),
          ),
        ],
      ),
    );
  }

  /// 出借 / 归还：只做状态切换（用户拍板：不加借用人字段、不动 schema）
  Future<void> _toggleLend(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final next = item.status == 'lent' ? 'safe' : 'lent';
    await ref.read(itemsProvider.notifier).updateItem(
          item.copyWith(status: next),
        );
    if (context.mounted) {
      // 与添加页同一套顶部 Toast（系统 SnackBar 黑条与全局视觉不符）
      ToastUtils.show(context, next == 'lent' ? '已标记为「借出」' : '已标记为「在库」');
    }
  }

  /// 点到期日条直接改日期（复用通用的 updateItem，不用另开编辑页）
  Future<void> _editExpiry(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: item.expiryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    await ref
        .read(itemsProvider.notifier)
        .updateItem(item.copyWith(expiryDate: picked));
  }

  /// 删除确认弹窗：二次确认后清理通知/照片并从数据库删除，最后返回上一页
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final confirmed = await showCenterSheet<bool>(
      context: context,
      builder: (ctx) => CenterSheetSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '删除物品',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.blushInk,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '确定要删除「${item.name}」吗？此操作无法撤销。',
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.blushLine,
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blushInk,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.btnDangerBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.delKnobBorder),
                      ),
                      child: const Text(
                        '删除',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.alertRed,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// 到期提示短句：已过期 N 天 / 今天到期 / 还剩 N 天（30 天内才提示）。
  /// 空串表示不需要提示（30 天外）。
  String _expiryHint(DateTime expiry) {
    final today = DateTime.now();
    final days = DateTime(expiry.year, expiry.month, expiry.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (days < 0) return '已过期 ${-days} 天';
    if (days == 0) return '今天到期';
    if (days <= 30) return '还剩 $days 天';
    return '';
  }

  /// 修改物品收纳位置（联动柜体/格子）
  void _changeLocation(BuildContext context, WidgetRef ref, Item item) {
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
                if (context.mounted) {
                  ToastUtils.show(context, '已更新收纳位置：${node.pathLabel}');
                }
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

// ═══════════════════════ 私有小组件 ═══════════════════════

/// 大图左上角的白色圆形返回钮
class _BackButton extends StatelessWidget {
  final double k;

  const _BackButton({required this.k});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: AppDimensions.heroBackSize * k,
        height: AppDimensions.heroBackSize * k,
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.chevron_left,
          size: 18 * k,
          color: AppColors.blushInk,
        ),
      ),
    );
  }
}

/// 状态 / 分类徽标（稿子 `.badge`：10pt / 2×8 内距 / 全圆角）
class _Badge extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  final double k;

  const _Badge({required this.text, required this.fg, required this.bg, required this.k});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * k, vertical: 2 * k),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10 * k,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

/// 信息组里的一行（稿子 `.cell`：26 图标块 + 文案 + 右对齐值，内距 10×12）
class _InfoRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final double k;
  final bool showChevron;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.k,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * k,
        vertical: 10 * k,
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.cellIconTile * k,
            height: AppDimensions.cellIconTile * k,
            decoration: BoxDecoration(
              color: AppColors.coralSoft,
              borderRadius: BorderRadius.circular(AppDimensions.cellIconTileRadius * k),
            ),
            alignment: Alignment.center,
            child: EmojiText(emoji: emoji, fontSize: 13 * k),
          ),
          SizedBox(width: 10 * k),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5 * k,
              fontWeight: FontWeight.w600,
              color: AppColors.blushInk,
            ),
          ),
          SizedBox(width: 10 * k),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5 * k,
                color: AppColors.blushInk3,
              ),
            ),
          ),
          if (showChevron) ...[
            SizedBox(width: 6 * k),
            Icon(Icons.chevron_right, size: 13 * k, color: AppColors.blushInk3),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

/// 删除旋钮（稿子 `.delknob`：40 圆 / 红浅底 / 1.5 粉边 / 3px 白内环）。
/// **不缩放**：与底部条同属固定 chrome，尺寸脱钩会看着散。
class _DeleteKnob extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteKnob({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.delKnobSize,
        height: AppDimensions.delKnobSize,
        padding: const EdgeInsets.all(3), // 白色内环
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.delKnobBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.delKnobShadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const DecoratedBox(
          decoration: BoxDecoration(color: AppColors.alertRedBg, shape: BoxShape.circle),
          child: Center(
            child: Icon(Icons.delete_outline, size: 17, color: AppColors.alertRed),
          ),
        ),
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
