// foundation 提供 kIsWeb（Web 端文字光学补偿用）；其 Category 注解与模型类重名，hide 掉
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/app_dimensions.dart';
import 'package:jia_cang/widgets/gradient_background.dart';
import 'package:jia_cang/widgets/emoji_text.dart';
import 'package:jia_cang/widgets/photo_image.dart';
import 'package:jia_cang/widgets/floating_bar.dart';
import 'package:jia_cang/widgets/toast_utils.dart';
import 'package:jia_cang/widgets/pill_content.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/models/category.dart';
import 'package:jia_cang/models/enums/sort_type.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/screen/inventory/sort_dropdown.dart';
import 'package:jia_cang/screen/inventory/filter_panel.dart';

// 排序文案统一放 models/enums/sort_type.dart（kSortLabels / kSortFullLabels），
// 物品库页与排序下拉共用一份，别再各写各的。

/// 排序偏好持久化 key（shared_preferences）
const String _kSortPrefKey = 'inventory_sort_type';

/// 长期闲置 / 即将到期 预筛标记（PendingInventoryFilter.special 的取值）
const String kSpecialFilterExpiring = 'expiring';
const String kSpecialFilterIdle = 'idle';

// ═════════════════════════════════════════════
// Inventory Page
// ═════════════════════════════════════════════

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  // ── 状态 ──
  String _activeCategory = 'all';
  bool _isGridView = true;
  bool _batchMode = false;
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  SortType _sortType = SortType.newest;
  bool _sortDropdownOpen = false;

  /// 分类 chip 区默认收起为单行横滑（2026-09-17 反馈：多行太占空间）
  bool _categoryExpanded = false;

  // ── 预筛（首页统计卡点击带过来的条件，可在筛选条上一键清除）──
  String? _statusFilter; // items.status 原值
  String? _specialFilter; // 'expiring' | 'idle'

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // ── 筛选面板 ──
  String? _selectedLocation;
  // 弹窗外部关闭信号：每次自增触发 FilterPanel 用自身 context 执行 pop。
  // showModalBottomSheet 默认 useRootNavigator=false，弹窗 push 到最近层导航器
  // （StatefulShellBranch 的分支导航器），而本页 build context 解析到的 Navigator
  // 未必是同一个，故通过信号让弹窗自关，保证 pop 命中正确的导航器。
  final ValueNotifier<int> _filterDismissSignal = ValueNotifier(0);

  // 标记本次 pending 分类 / 预筛 / 搜索聚焦是否已被消费，避免 build 多次触发时重复应用
  bool _pendingCategoryApplied = false;
  bool _pendingFilterApplied = false;
  bool _pendingSearchFocusApplied = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    _filterDismissSignal.dispose();
    super.dispose();
  }

  /// 重置除 _activeCategory 之外的所有筛选/排序/选择/滚动状态
  /// 用于从分类页跳转过来时，清除上一次留下的选择状态
  void _resetSecondaryState() {
    _searchQuery = '';
    _searchController.clear();
    _selectedLocation = null;
    _statusFilter = null;
    _specialFilter = null;
    _sortDropdownOpen = false;
    _batchMode = false;
    _selectedIds.clear();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  /// 应用首页统计卡带来的预筛请求（分类回「全部」，其余条件清空后叠加预筛）
  void _applyPendingFilter(PendingInventoryFilter f) {
    _resetSecondaryState();
    _activeCategory = 'all';
    _statusFilter = f.status;
    _specialFilter = f.special;
  }

  @override
  void initState() {
    super.initState();
    // 在 initState 中处理来自其他页面的 pending 筛选请求。
    // IndexedStack 首次懒加载页面时，build 中 ref.watch 改 State + postFrame
    // 清空 provider 的模式存在时序竞态，可能导致首次跳转筛选未应用。
    // initState 一定先于 build 执行，此时 provider 值刚由来源页设置，可稳定读取。
    String? pendingCat = ref.read(pendingCategoryProvider);
    final pendingFilter = ref.read(pendingInventoryFilterRequestProvider);

    if (pendingCat != null) {
      _resetSecondaryState();
      _activeCategory = pendingCat;
      // 标记已消费，避免紧随其后的 build 重复 reset
      _pendingCategoryApplied = true;
    }
    if (pendingFilter != null) {
      _applyPendingFilter(pendingFilter);
      _pendingFilterApplied = true;
    }
    // 统一在 postFrame 清空 pending provider，避免下次进入重复触发
    if (pendingCat != null || pendingFilter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(pendingCategoryProvider.notifier).set(null);
          ref.read(pendingInventoryFilterRequestProvider.notifier).set(null);
        }
      });
    }
    // 恢复持久化的排序偏好（读取是异步的，就绪后回填）
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        _sortType = sortTypeFromName(prefs.getString(_kSortPrefKey));
      });
    });
  }

  // ───────────────────────────────────────────
  // Status helpers
  // ───────────────────────────────────────────

  // ───────────────────────────────────────────
  // 过滤 & 排序逻辑 (from Riverpod provider)
  // ───────────────────────────────────────────

  /// 当前激活的筛选条件数量（用于筛选 chip 角标）
  int get _activeFilterCount {
    int count = 0;
    if (_selectedLocation != null && _selectedLocation != '全部') count++;
    if (_statusFilter != null) count++;
    if (_specialFilter != null) count++;
    return count;
  }

  List<Item> get _filteredItems {
    final allItemsAsync = ref.watch(itemsProvider);
    return allItemsAsync.maybeWhen(
      data: (allItems) {
        // 先复制再筛选/排序：`allItems` 是 itemsProvider 持有的那个列表实例，
        // 直接 sort 会**原地改掉 provider 的状态**（build 期间产生副作用），
        // 且 provider 一旦返回不可变列表就会抛
        // `Unsupported operation: Cannot modify an unmodifiable list`。
        var filtered = allItems.toList();
        if (_activeCategory != 'all') {
          filtered = filtered
              .where((i) => i.categoryKey == _activeCategory)
              .toList();
        }
        if (_searchQuery.isNotEmpty) {
          filtered = filtered
              .where(
                (i) =>
                    i.name.contains(_searchQuery) ||
                    i.location.contains(_searchQuery),
              )
              .toList();
        }
        // 收纳位置筛选（包含匹配，如「客厅」匹配「客厅收纳柜」）
        if (_selectedLocation != null && _selectedLocation != '全部') {
          filtered = filtered
              .where((i) => i.location.contains(_selectedLocation!))
              .toList();
        }
        // 状态筛选（首页「出借中」卡 / 筛选面板）
        if (_statusFilter != null) {
          filtered = filtered
              .where((i) => i.status == _statusFilter)
              .toList();
        }
        // 派生视图预筛（首页「即将到期」「长期闲置」卡）：判定口径直接复用
        // expiringSoonItems / idleItems 两个 provider，避免两处逻辑漂移。
        if (_specialFilter != null) {
          final allowed = _specialFilter == kSpecialFilterExpiring
              ? ref.watch(expiringSoonItemsProvider).map((e) => e.id).toSet()
              : ref.watch(idleItemsProvider).map((e) => e.id).toSet();
          filtered = filtered.where((i) => allowed.contains(i.id)).toList();
        }
        switch (_sortType) {
          case SortType.newest:
            filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case SortType.oldest:
            filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            break;
          case SortType.nameAsc:
            filtered.sort((a, b) => a.name.compareTo(b.name));
            break;
          case SortType.expiryAsc:
            filtered.sort((a, b) {
              // 无到期日的排最后；同为有/无时按时间升序
              final da = a.expiryDate;
              final db = b.expiryDate;
              if (da == null && db == null) return a.name.compareTo(b.name);
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });
            break;
          case SortType.categoryAsc:
            final cats = ref.watch(availableCategoriesProvider);
            String labelOf(Item i) {
              for (final c in cats) {
                if (c.key == i.categoryKey) return c.label;
              }
              return '';
            }
            filtered.sort((a, b) {
              final r = labelOf(a).compareTo(labelOf(b));
              return r != 0 ? r : a.name.compareTo(b.name);
            });
            break;
        }
        return filtered;
      },
      orElse: () => [],
    );
  }

  // ───────────────────────────────────────────
  // 操作
  // ───────────────────────────────────────────

  void _onCategoryChanged(String key) {
    setState(() => _activeCategory = key);
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _toggleBatchMode() {
    setState(() {
      _batchMode = !_batchMode;
      if (!_batchMode) _selectedIds.clear();
    });
    ToastUtils.show(context, _batchMode ? '已进入批量管理模式' : '退出批量管理模式');
  }

  void _toggleCheck(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _onItemTap(Item item) {
    if (_batchMode) {
      _toggleCheck(item.id);
      return;
    }
    context.push('/detail/${item.id}');
  }

  void _selectSort(SortType type) {
    setState(() {
      _sortType = type;
      _sortDropdownOpen = false;
    });
    // 排序偏好持久化：下次进入物品库保持上一次的选择
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_kSortPrefKey, type.name),
    );
    ToastUtils.show(context, '按${kSortFullLabels[type]}排序');
  }

  Future<void> _onRefresh() async {
    ref.invalidate(itemsProvider);
    await ref.read(itemsProvider.future);
  }

  // ───────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // 用 watch 监听待选分类：IndexedStack 切换分支不会重建已存在的页面 State，
    // 必须用 watch 让 provider 变化时强制 rebuild，才能读到其他页面设置的值。
    final pending = ref.watch(pendingCategoryProvider);
    if (pending != null) {
      // _pendingCategoryApplied 用于防止 build 多次触发时重复 reset：
      // - initState 已消费过 pending：标记为 true，build 跳过
      // - 同一 pending 值触发第二次 build：跳过
      // - 新一次跳转（pending 重新被设置）：applied 已在 provider 清空时重置为 false，正常应用
      if (!_pendingCategoryApplied) {
        _resetSecondaryState();
        _activeCategory = pending;
        _pendingCategoryApplied = true;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(pendingCategoryProvider.notifier).set(null);
        }
      });
    } else {
      // pending 已被清空，重置标记，为下一次跳转做准备
      _pendingCategoryApplied = false;
    }

    // 首页统计卡带来的预筛请求（出借中 / 即将到期 / 长期闲置）
    final pendingFilter = ref.watch(pendingInventoryFilterRequestProvider);
    if (pendingFilter != null) {
      if (!_pendingFilterApplied) {
        _applyPendingFilter(pendingFilter);
        _pendingFilterApplied = true;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(pendingInventoryFilterRequestProvider.notifier).set(null);
        }
      });
    } else {
      _pendingFilterApplied = false;
    }

    // 首页搜索胶囊带来的「聚焦搜索框」请求
    final pendingSearchFocus = ref.watch(pendingSearchFocusProvider);
    if (pendingSearchFocus && !_pendingSearchFocusApplied) {
      _pendingSearchFocusApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocus.requestFocus();
          ref.read(pendingSearchFocusProvider.notifier).set(false);
        }
      });
    }

    final items = _filteredItems;

    return Scaffold(
      body: GradientBackground(
        child: GestureDetector(
          onTap: () {
            // 点击空白关闭排序下拉
            if (_sortDropdownOpen) {
              setState(() => _sortDropdownOpen = false);
            }
          },
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildTopBar(),
                    const SizedBox(height: 12),
                    _buildCategoryTabs(),
                    const SizedBox(height: 12),
                    _buildFilterBar(),
                    const SizedBox(height: 4),
                    Expanded(child: _buildListArea(items)),
                  ],
                ),
                // 批量操作栏
                if (_batchMode)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBatchBar(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── List Area (排序下拉作为浮层，不影响列表布局) ──

  Widget _buildListArea(List<Item> items) {
    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.coral,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 结果计数
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pageMarginHorizontal,
                    4,
                    AppDimensions.pageMarginHorizontal,
                    10,
                  ),
                  child: _buildResultCount(items.length),
                ),
              ),
              // 列表内容
              if (_isGridView)
                _buildGridSliver(items)
              else
                _buildListSliver(items),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
        // 排序下拉浮层：叠在列表之上，不挤压下方内容
        if (_sortDropdownOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _sortDropdownOpen = false),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: SortDropdown(
              currentSort: _sortType,
              onSortSelected: _selectSort,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Top Bar ───────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageMarginHorizontal,
      ),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '搜索物品名称、分类…',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 批量处理按钮
          _buildBatchToggle(),
        ],
      ),
    );
  }

  /// 批量处理入口。
  ///
  /// 图标刻意不用 `edit_note`（一支笔压在几行字上）：它和「编辑」太像，
  /// 而这里的功能是「勾选多件物品再统一处理」。改用清单+对勾的
  /// `checklist_rounded`，语义直接。
  ///
  /// 高亮方式与「收纳」页右上角的 + 按钮统一：实心珊瑚 + 白色图标 + 珊瑚辉光。
  /// 未激活时是较浅一档的珊瑚，激活后加深并加强辉光，
  /// 提示「批量模式已开启」（底部同时会出现批量操作栏）。
  Widget _buildBatchToggle() {
    final active = _batchMode;
    return GestureDetector(
      onTap: _toggleBatchMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          // 稿子 `.btn.primary` 无渐变：激活 = 实心珊瑚，未激活 = 珊瑚软底
          color: active ? AppColors.btnPrimaryBg : AppColors.coralSoft,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.btnPrimaryShadow,
              blurRadius: active ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.checklist_rounded,
          size: 20,
          color: active ? AppColors.btnPrimaryFg : AppColors.btnSoftFg,
        ),
      ),
    );
  }

  // ─── Category Tabs ─────────────────────────

  Widget _buildCategoryTabs() {
    // 从 provider 动态读取分类列表：数据库分类 + 虚拟物品分类
    // 用户在分类管理页的新增/编辑/删除会实时反映到此处
    final dynamicCats = ref.watch(availableCategoriesProvider);
    // 「全部」固定在最前；其后跟随动态分类
    final tabs = <Category>[const Category('all', '全部'), ...dynamicCats];
    // 防御：若当前选中的分类已不存在（被用户删除），回退到「全部」
    if (_activeCategory != 'all' &&
        !tabs.any((c) => c.key == _activeCategory)) {
      _activeCategory = 'all';
    }
    // Wrap 多行流式布局：2026-09-17 反馈分类 chip 太占纵向空间 →
    // 默认收起为**单行横滑**，右侧箭头按钮点击后才展开为全量多行。
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageMarginHorizontal,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _categoryExpanded
                ? _buildCategoryGrid(tabs)
                // 折叠态：右端 12% 渐隐遮罩——被裁的 chip 淡出，
                // 不再出现「切一半的按钮」硬边（2026-09-17 反馈）。
                // chip 定宽 = 展开态 3 列网格的格子宽（同一 LayoutBuilder
                // 约束、同一 gap 公式），折叠/展开宽度完全一致
                // （2026-09-17 反馈「折叠态按钮宽度与展开态统一」）。
                : ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0.0, 0.88, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 8.0;
                        // 展开态 3 列、两个 8px 列缝——与 _buildCategoryGrid 同式
                        final cellWidth = (constraints.maxWidth - gap * 2) / 3;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (final cat in tabs)
                                Padding(
                                  padding: const EdgeInsets.only(right: gap),
                                  child: SizedBox(
                                    width: cellWidth,
                                    child: _buildCategoryChip(
                                      cat,
                                      centered: true,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () =>
                setState(() => _categoryExpanded = !_categoryExpanded),
            child: Container(
              // 40：与 FloatingBarButton 同高（2026-09-17 反馈分类 chip
              // 整体升一档后，箭头钮跟随对齐全局 40pt 按钮语言）
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 展开态：**3 列等宽网格**（2026-09-17 反馈 Wrap 流式布局右侧
  /// 空白太多）。每行固定 3 格、格子撑满行宽，任何一行都不会
  /// 在右边留下一大片随机空白；不足一行的位置用空占位补齐。
  Widget _buildCategoryGrid(List<Category> tabs) {
    const cols = 3;
    const gap = 8.0;
    final rows = <Widget>[];
    for (var i = 0; i < tabs.length; i += cols) {
      final cells = <Widget>[];
      for (var j = i; j < i + cols; j++) {
        if (j < tabs.length) {
          cells.add(
            Expanded(
              child: _buildCategoryChip(
                tabs[j],
                centered: true,
              ),
            ),
          );
        } else {
          cells.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      // 格与格之间留 8px 缝：在 Expanded 之间插固定宽 SizedBox
      final spaced = <Widget>[];
      for (var c = 0; c < cells.length; c++) {
        if (c > 0) spaced.add(const SizedBox(width: gap));
        spaced.add(cells[c]);
      }
      rows.add(Row(children: spaced));
      if (i + cols < tabs.length) {
        rows.add(const SizedBox(height: gap));
      }
    }
    return Column(children: rows);
  }

  Widget _buildCategoryChip(Category cat, {bool centered = false}) {
    final isActive = _activeCategory == cat.key;
    return GestureDetector(
      onTap: () => _onCategoryChanged(cat.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        // 展开态网格里 chip 撑满等宽格子，文字需显式居中
        alignment: centered ? Alignment.center : null,
        // 2026-09-17 反馈「缩放的时候按展开的尺寸设置」：折叠态 chip
        // 放大到与展开态观感一致——字号 14 / 内边距 20×9（高 ~40），
        // 与全局 40pt 按钮语言对齐。
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.chipSelectedBg : AppColors.chipBg,
          borderRadius: BorderRadius.circular(22),
          // 激活态不再叠珊瑚辉光：小尺寸 chip 上 blur14 的光晕
          // 会在浅底上晕出一团突兀的橙色渐变（2026-09-17 反馈
          // 「颜色过渡不对」），实心珊瑚本身已足够突出。
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Transform.translate(
          // Web 端 CJK 文字墨水偏下，与 filter_panel 的胶囊文字同一光学补偿
          offset: Offset(0, kIsWeb ? PillContent.kWebTextOpticalLift : 0.0),
          child: Text(
            cat.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.chipSelectedFg : AppColors.chipFg,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Filter Bar ────────────────────────────

  Widget _buildFilterBar() {
    // 可移除过滤 chip：任一状态/派生条件激活时显示（标签行已按 2026-09-17
    // 反馈取消，预筛条件统一在这里回显并可一键清除）
    final String? removableChipLabel = _specialFilter != null
        ? (_specialFilter == kSpecialFilterExpiring ? '即将到期' : '闲置中')
        : (_statusFilter != null
              ? (_statusLabels[_statusFilter] ?? _statusFilter)
              : null);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageMarginHorizontal,
      ),
      child: Row(
        children: [
          // 排序 chip：默认只显示「排序」，选择后在下拉里体现（2026-09-17 反馈）
          _buildFilterChip(
            label: '排序',
            isActive: false,
            showArrow: true,
            onTap: () {
              setState(() => _sortDropdownOpen = !_sortDropdownOpen);
            },
          ),
          const SizedBox(width: 6),
          // 筛选 chip
          _buildFilterChip(
            label: _activeFilterCount > 0 ? '筛选·$_activeFilterCount' : '筛选',
            isActive: _activeFilterCount > 0,
            showArrow: false,
            icon: Icons.tune,
            onTap: () => _showFilterPanel(),
          ),
          // 可移除过滤 chip（如「即将到期 ✕」）
          if (removableChipLabel != null) ...[
            const SizedBox(width: 6),
            _buildRemovableFilterChip(removableChipLabel),
          ],
          const Spacer(),
          // 视图切换
          _buildViewToggle(),
        ],
      ),
    );
  }

  /// 可移除过滤 chip：珊瑚实心 + 关闭钮，点击清除当前预筛条件回到全量列表。
  Widget _buildRemovableFilterChip(String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_specialFilter != null) {
            _specialFilter = null;
          } else {
            _statusFilter = null;
          }
        });
        ToastUtils.show(context, '已清除过滤条件');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.chipSelectedBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.btnPrimaryShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.chipSelectedFg,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 13,
              color: AppColors.chipSelectedFg,
            ),
          ],
        ),
      ),
    );
  }

  /// 筛选 / 排序 chip。
  ///
  /// 选中态与所有页面的 chip 统一走 `AppColors.chip*` 令牌：实心珊瑚 + 白字。
  /// 之前的选中态是浅金底（#F1C64D）+ 金字（#E5A500），两者亮度太接近，
  /// 对比度只有 1.5:1 左右，字几乎糊在底上。
  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    bool showArrow = false,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    final fg = isActive ? AppColors.chipSelectedFg : AppColors.chipFg;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.chipSelectedBg : AppColors.chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.chipSelectedBg : AppColors.chipBorder,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.btnPrimaryShadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        // 用 PillContent：胶囊居中策略统一为「图标 + 文字」内容组整体居中
        // （常规胶囊行为，用户已否掉文字单独几何居中的版本），
        // PillContent 同时处理 Web 端 CJK 文字的垂直光学补偿。
        // （文字会被图标挤偏属预期：排序胶囊带后置箭头 → 偏左约 8px，
        // 筛选胶囊带前置图标 → 偏右约 8px，内容组整体居中。）
        // 筛选胶囊带前置图标 → 偏右约 8px）。
        child: PillContent(
          label: label,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
          leading: icon,
          trailing: showArrow
              ? (_sortDropdownOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down)
              : null,
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Row(
      children: [
        _buildViewBtn(
          icon: Icons.grid_view,
          isActive: _isGridView,
          onTap: () {
            if (!_isGridView) setState(() => _isGridView = true);
          },
        ),
        const SizedBox(width: 4),
        _buildViewBtn(
          icon: Icons.view_list,
          isActive: !_isGridView,
          onTap: () {
            if (_isGridView) setState(() => _isGridView = false);
          },
        ),
      ],
    );
  }

  Widget _buildViewBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? AppColors.chipSelectedBg : AppColors.chipBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? AppColors.chipSelectedFg : AppColors.textHint,
        ),
      ),
    );
  }

  // ─── Result Count ──────────────────────────

  Widget _buildResultCount(int count) {
    return RichText(
      text: TextSpan(
        text: '共 ',
        style: TextStyle(fontSize: 12, color: AppColors.textHint),
        children: [
          TextSpan(
            text: '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.coralDeep,
            ),
          ),
          TextSpan(
            text: ' 件物品',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ─── Grid View ─────────────────────────────

  Widget _buildGridSliver(List<Item> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageMarginHorizontal,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.86,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return _buildGridCard(item, index);
        }, childCount: items.length),
      ),
    );
  }

  /// 物品缩略图：有照片时优先展示第一张（铺满父容器），无照片回退到 emoji。
  /// 父容器需已提供尺寸约束；emoji 场景依赖父容器的背景色。
  /// 图片加载失败（文件丢失/损坏）时自动回退 emoji，保证始终有显示。
  Widget _buildThumb(Item item, {required double emojiSize}) {
    final emoji = '📦';
    if (item.photos.isNotEmpty) {
      return SizedBox.expand(
        child: PhotoImage(
          source: item.photos.first,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: EmojiText(emoji: emoji, fontSize: emojiSize),
          ),
        ),
      );
    }
    return Center(
      child: EmojiText(emoji: emoji, fontSize: emojiSize),
    );
  }

  Widget _buildGridCard(Item item, int index) {
    final isSelected = _selectedIds.contains(item.id);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 50),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: Transform.scale(
            scale: 0.96 + 0.04 * value,
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _onItemTap(item),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusXLarge,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.coral.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片区域（占满信息区之外的全部高度）
              Expanded(
                child: Stack(
                  children: [
                    // 图片/Emoji 背景
                    Container(
                      width: double.infinity,
                      color: AppColors.coralSoft,
                      child: _buildThumb(item, emojiSize: 44),
                    ),
                    // 批量选择圆圈
                    if (_batchMode)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: () => _toggleCheck(item.id),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.chipSelectedBg
                                  : Colors.black12,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.chipSelectedBg
                                    : Colors.white.withValues(alpha: 0.7),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 14,
                                    color: AppColors.chipSelectedFg,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // 信息区域
              //
              // 刻意不用 Expanded 撑高：文字只有「名称 + 位置」两行，
              // 撑高会在卡片下半部留下一大片空白（原先还有 Spacer 把
              // 一个没有信息量的状态标签顶到最底部）。
              // 这里让信息区按内容自适应高度，剩余空间全部让给图片区域。
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 位置与状态徽标同行：既不浪费垂直空间，
                    // 也不用把徽标用 Spacer 顶到卡片底部留出一片空白。
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusBadge(item, isSmall: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── List View ─────────────────────────────

  Widget _buildListSliver(List<Item> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageMarginHorizontal,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildListCard(item, index),
          );
        }, childCount: items.length),
      ),
    );
  }

  Widget _buildListCard(Item item, int index) {
    final isSelected = _selectedIds.contains(item.id);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 50),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-12 * (1 - value), 0),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _onItemTap(item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusExtraLarge,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 缩略图
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.coralSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildThumb(item, emojiSize: 28),
                  ),
                  if (_batchMode)
                    Positioned(
                      top: -4,
                      left: -4,
                      child: GestureDetector(
                        onTap: () => _toggleCheck(item.id),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.chipSelectedBg
                                : Colors.black12,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.chipSelectedBg
                                  : AppColors.cardBg,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 12,
                                  color: AppColors.chipSelectedFg,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Flexible(
                      child: Text(
                        item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 状态徽标（中文）
              _buildStatusBadge(item, isSmall: true),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 通用组件 ──────────────────────────────

  /// 物品状态徽标。
  ///
  /// `items.status` 是数据库里的英文枚举值（默认 'safe'），
  /// 早先直接把原始值渲染出来，界面上就出现了英文「safe」。
  /// 这里统一映射成中文；遇到未知值回退显示原值，避免新状态被吞掉。
  static const Map<String, String> _statusLabels = {
    'safe': '在库',
    'lent': '借出',
    'lost': '丢失',
    'used': '已用',
  };

  Widget _buildStatusBadge(Item item, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 8,
        vertical: isSmall ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
      ),
      child: Text(
        _statusLabels[item.status] ?? item.status,
        style: TextStyle(
          fontSize: isSmall ? 10 : 10,
          fontWeight: FontWeight.w700,
          color: AppColors.statusUsing,
        ),
      ),
    );
  }

  // ─── Batch Bar ─────────────────────────────

  Widget _buildBatchBar() {
    // 2026-09-17 反馈：与详情页底部操作条统一成同一套悬浮条语言
    //（FloatingBar + 40pt 胶囊按钮，字号 13/700），不再是自绘的小字信息栏。
    // 移动 / 导出按同日反馈加回（原占位行为保持：真功能后续单独排期）。
    return FloatingBar(
      background: AppColors.actionBarBg,
      child: Row(
        children: [
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: '已选 ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.blushInk,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: '${_selectedIds.length}',
                    style: TextStyle(
                      color: AppColors.coralDeep,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(text: ' 件'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FloatingBarButton(
              label: '标记已用',
              tone: FloatingBarTone.ghost,
              onTap: _markSelectedUsed,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FloatingBarButton(
              label: '移动',
              tone: FloatingBarTone.ghost,
              onTap: () => ToastUtils.show(context, '移动'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FloatingBarButton(
              label: '导出',
              tone: FloatingBarTone.ghost,
              onTap: () => ToastUtils.show(context, '导出'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FloatingBarButton(
              label: '删除',
              tone: FloatingBarTone.danger,
              onTap: () => ToastUtils.show(context, '确认删除？'),
            ),
          ),
        ],
      ),
    );
  }

  /// 批量标记为「已用」：闲置物品的批量处理闭环——
  /// 状态改为 used 后自动退出闲置清单与批量模式。
  Future<void> _markSelectedUsed() async {
    if (_selectedIds.isEmpty) return;
    final ids = _selectedIds.toList();
    await ref.read(itemsProvider.notifier).markItemsStatus(ids, 'used');
    if (!mounted) return;
    setState(() {
      _batchMode = false;
      _selectedIds.clear();
    });
    ToastUtils.show(context, '已将 ${ids.length} 件物品标记为已用');
  }

  // ─── Filter Panel (Bottom Sheet) ───────────

  void _showFilterPanel() {
    FilterPanel.show(
      context,
      initialLocation: _selectedLocation,
      initialStatus: _statusFilter,
      initialSpecial: _specialFilter == kSpecialFilterIdle ? 'idle' : null,
      initialCategoryKey: _activeCategory,
      categories: ref.read(availableCategoriesProvider),
      dismissSignal: _filterDismissSignal,
      onApply: (FilterResult result) {
        setState(() {
          _selectedLocation = result.location;
          _statusFilter = result.status;
          // 面板里的分类与顶部分类 chip 是同一状态，改一个即同步
          _activeCategory = result.categoryKey ?? 'all';
          // 「闲置」走派生视图口径；应用面板时覆盖原预筛（互斥）
          _specialFilter = result.special;
        });
        ToastUtils.show(context, '已应用筛选条件');
      },
      onReset: () {
        setState(() {
          _selectedLocation = null;
          _statusFilter = null;
          _activeCategory = 'all';
          _specialFilter = null;
        });
      },
    );
  }
}
