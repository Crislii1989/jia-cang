import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/category.dart';
import '../../models/item.dart';
import '../../models/storage.dart';
import '../../providers/category_provider.dart';
import '../../providers/item_providers.dart';
import '../../providers/storage_providers.dart';
import '../../widgets/center_sheet.dart';
import '../../widgets/emoji_text.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/toast_utils.dart';
import '../../widgets/pill_content.dart';
import '../add_item_page.dart';
import 'add_space_modal.dart';
import 'edit_space_modal.dart';
import 'items_preview_modal.dart';

/// 收纳位置管理页面。
///
/// 版式对齐「物品库」：
/// 顶部搜索栏（右侧 + 新增）→ 房间/柜体/箱子三个浏览维度按钮 →
/// 当前区域大标题 + 该区域的物品总数 → 具体内容列表。
///
/// 浏览维度 [_tab]：
/// - 0 房间：展示全部房间；
/// - 1 柜体：已进入某房间时，展示该房间的柜体 **以及房间内散放的物品**（配色区分）；
///           未进入房间时展示全部柜体；
/// - 2 箱子：已进入某柜体时，展示该柜体的箱子 **以及柜内散放的物品**（配色区分）；
///           否则展示全部箱子。
///
/// 不再有「房间内直接存放」这类中间卡片 —— 散放物品直接列在柜体/箱子下方。
class StoragePage extends ConsumerStatefulWidget {
  const StoragePage({super.key});

  @override
  ConsumerState<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends ConsumerState<StoragePage> {
  // ── 浏览维度 ──
  int _tab = 0;
  String? _currentRoomId;
  String? _currentCabinetId;
  String _currentRoomName = '';
  String _currentCabinetName = '';

  // ── 搜索 ──
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── 新增模态框 ──
  bool _showAddModal = false;
  String? _addModalRoomId;
  String? _addModalCabinetId;

  // ── 编辑模态框 ──
  bool _showEditModal = false;
  _EditTarget? _editTarget;

  // ── 箱子内物品模态框 ──
  bool _showItemsModal = false;
  String _itemsModalTitle = '';
  String _itemsModalSlotId = '';
  final Set<String> _selectedItemIds = {};

  // ── 进行中标记 ──
  bool _batchProcessing = false;
  bool _deleteChecking = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========== 浏览维度切换 ==========
  void _onTabTap(int tab) {
    setState(() {
      if (tab == _tab) {
        // 再次点击当前维度：退出已进入的房间/柜体，回到全局视图
        if (tab == 1 && _currentRoomId != null) {
          _currentRoomId = null;
          _currentRoomName = '';
          _currentCabinetId = null;
          _currentCabinetName = '';
        } else if (tab == 2 && _currentCabinetId != null) {
          _currentCabinetId = null;
          _currentCabinetName = '';
        }
        return;
      }
      _tab = tab;
      if (tab == 0) {
        _currentRoomId = null;
        _currentRoomName = '';
        _currentCabinetId = null;
        _currentCabinetName = '';
      } else if (tab == 1) {
        // 从箱子维度退回柜体维度时，先退出具体柜体
        _currentCabinetId = null;
        _currentCabinetName = '';
      }
    });
  }

  void _enterRoom(Room room) {
    setState(() {
      _tab = 1;
      _currentRoomId = room.id;
      _currentRoomName = room.name;
      _currentCabinetId = null;
      _currentCabinetName = '';
    });
  }

  void _enterCabinet(Cabinet cabinet, String roomId, String roomName) {
    setState(() {
      _tab = 2;
      _currentRoomId = roomId;
      _currentRoomName = roomName;
      _currentCabinetId = cabinet.id;
      _currentCabinetName = cabinet.name;
    });
  }

  // ========== 搜索 ==========
  /// 合并分类列表（数据库分类 + 虚拟分类），把 `categoryKey` 翻成中文名用。
  List<Category> get _categories => ref.watch(availableCategoriesProvider);

  bool _match(String text) =>
      _searchQuery.isEmpty || text.contains(_searchQuery);

  /// 物品是否命中搜索：名称 / 备注 / 位置文案 / 分类中文名。
  ///
  /// 位置也参与匹配，因此搜「卫生间」能列出放在卫生间的所有东西；
  /// 分类走中文名，搜「运动」能命中 categoryKey 为 `sports` 的物品。
  bool _matchItem(Item item) {
    if (_searchQuery.isEmpty) return true;
    if (item.name.contains(_searchQuery)) return true;
    if (item.note.contains(_searchQuery)) return true;
    if (item.location.contains(_searchQuery)) return true;
    final label = categoryLabelOf(_categories, item.categoryKey, fallback: '');
    return label.contains(_searchQuery);
  }

  /// 搜索命中的物品；搜索为空时返回空列表，不打扰正常浏览。
  ///
  /// 这里只按物品自身字段匹配、不做层级判断——物品可能挂在房间、柜体或箱子
  /// 任意一层，是否属于「当前区域」由各维度自己再筛一次。
  List<Item> _matchedItems(Iterable<Item> items) =>
      _searchQuery.isEmpty ? const <Item>[] : items.where(_matchItem).toList();

  /// 搜索命中的物品清单。
  ///
  /// 之前搜索只匹配房间/柜体/箱子的名字，物品收进库以后在收纳页搜不到，
  /// 只会得到「没有匹配的房间」。这里把命中的物品直接列出来：
  /// 一是搜得到，二是不用逐层点进柜体/箱子去找。
  Widget? _buildMatchedItemsSection(List<Item> items) {
    if (items.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel('物品', items.length, AppColors.info),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ItemCard(
              item: items[i],
              delay: i * 0.05,
              onTap: () => context.push('/detail/${items[i].id}'),
            ),
          ),
      ],
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim());
  }

  Future<void> _onRefresh() async {
    ref.invalidate(itemsProvider);
    await ref.read(itemsProvider.future);
  }

  // ========== 新增模态框 ==========
  void _openAddModal() {
    String? roomId = _currentRoomId;
    final cabinetId = _currentCabinetId;
    // 在「全部柜体 / 全部箱子」维度下新增时落到第一个房间，省去用户手动再选一次
    if (_tab >= 1 && roomId == null) {
      final rooms = ref.read(roomsProvider).value ?? const <Room>[];
      roomId = rooms.isEmpty ? null : rooms.first.id;
    }
    setState(() {
      _addModalRoomId = roomId;
      _addModalCabinetId = cabinetId;
      _showAddModal = true;
    });
  }

  void _closeAddModal() {
    setState(() => _showAddModal = false);
  }

  /// 新增模态框的默认层级：2=格子（已进入柜体）1=柜体（已进入房间）0=房间
  int get _addLevel {
    if (_tab == 2 && _currentCabinetId != null) return 2;
    if (_tab >= 1 && _addModalRoomId != null) return 1;
    return 0;
  }

  Future<void> _onAddConfirm({
    required String level,
    required String parentId,
    required String name,
    required String icon,
    String? photoPath,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final id = '${level}_$ts';
    // 新建空间的默认身份色：跟随 V2.6 珊瑚主色（旧值 AppColors.primary 是金色，
    // 在暖粉白底上会突兀出「金色瓷砖」，与首页的 pastel 身份色语言不统一）。
    const color = AppColors.coral;

    // 等写入真正完成后再关闭弹窗并提示。
    // 若数据库写入失败（连接异常等），用户能立刻看到失败原因，
    // 而不是「提示已添加、列表却一直是空的」这种静默失败。
    try {
      switch (level) {
        case 'room':
          await ref
              .read(roomActionsProvider.notifier)
              .addRoom(id: id, name: name, emoji: icon, color: color);
          // 不再自动创建「默认柜体 / 默认区域」。
          // 房间可以独立存在（柜体数量 = 0），物品可直接归属房间；
          // 用户需要柜体时在房间内点击右上角 + 主动创建。
          break;
        case 'cabinet':
          if (parentId.isEmpty) return;
          await ref
              .read(cabinetActionsProvider.notifier)
              .addCabinet(
                id: id,
                name: name,
                emoji: icon,
                color: color,
                roomId: parentId,
                photoPath: photoPath,
              );
          // 不再自动创建"默认区域"格子。
          // 柜体本身即可作为收纳位置（items.cabinetId 直接指向柜体），
          // 用户有分区需求时可在柜体详情页主动新建格子。
          break;
        case 'slot':
          if (parentId.isEmpty) return;
          await ref
              .read(slotActionsProvider.notifier)
              .addSlot(
                id: id,
                name: name,
                emoji: icon,
                color: color,
                cabinetId: parentId,
              );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.show(context, '添加失败：$e');
      return;
    }

    if (!mounted) return;
    ToastUtils.show(context, '「$name」已添加');
    _closeAddModal();

    // 创建后询问是否顺手添加物品（房间与柜体本身都可作为收纳位置）
    if (level == 'room') {
      _promptAddItemAfterRoomCreated(roomId: id, roomName: name);
    } else if (level == 'cabinet') {
      _promptAddItemAfterCabinetCreated(cabinetId: id, cabinetName: name);
    }
  }

  /// 新建柜体后提示是否立即添加物品到该柜体。
  void _promptAddItemAfterCabinetCreated({
    required String cabinetId,
    required String cabinetName,
  }) {
    _promptAddItemAfterSpaceCreated(
      spaceId: cabinetId,
      spaceName: cabinetName,
      dialogTitle: '柜体已创建',
      dialogContent: '「$cabinetName」已创建，是否立即添加物品到该柜体？',
      cabinetId: cabinetId,
    );
  }

  /// 新建房间后提示是否立即添加物品。
  /// 房间无需先建柜体即可存放物品，因此这里预填的是房间本身。
  void _promptAddItemAfterRoomCreated({
    required String roomId,
    required String roomName,
  }) {
    _promptAddItemAfterSpaceCreated(
      spaceId: roomId,
      spaceName: roomName,
      dialogTitle: '房间已创建',
      dialogContent:
          '「$roomName」已创建，是否立即添加物品到该房间？\n物品可直接存放在房间内，无需先建柜体。',
      roomId: roomId,
    );
  }

  /// 新建收纳单元（房间/柜体）后的「立即添加物品」提示，跳转 AddItemPage 并预选该位置。
  void _promptAddItemAfterSpaceCreated({
    required String spaceId,
    required String spaceName,
    required String dialogTitle,
    required String dialogContent,
    String? roomId,
    String? cabinetId,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // 等待 storageLocationTree 刷新，确保跳转后能匹配到节点
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(dialogTitle),
          content: Text(dialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('稍后'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.btnTextFg),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('立即添加'),
            ),
          ],
        ),
      );
      if (shouldAdd != true) return;
      if (!mounted) return;
      final nodes = ref.read(storageLocationTreeProvider).value ?? const [];
      final node = nodes.where((n) => n.id == spaceId).firstOrNull;
      final locationLabel = node?.pathLabel ?? spaceName;
      if (!mounted) return;
      context.push(
        '/add_item',
        extra: AddItemInitialValues(
          name: '',
          preselectedRoomId: roomId,
          preselectedCabinetId: cabinetId,
          preselectedSlotId: null,
          preselectedLocationLabel: locationLabel,
        ),
      );
    });
  }

  // ========== 箱子内物品模态框 ==========
  void _openItemsModal(String title, String slotId) {
    setState(() {
      _showItemsModal = true;
      _itemsModalTitle = title;
      _itemsModalSlotId = slotId;
      _selectedItemIds.clear();
    });
  }

  void _closeItemsModal() {
    setState(() => _showItemsModal = false);
  }

  // ========== 长按操作面板 ==========
  void _showRoomActionSheet(Room room) {
    showCenterSheet(
      context: context,
      backgroundColor: Colors.white,
      borderRadius: 20,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.btnTextFg,
              ),
              title: const Text('编辑房间'),
              onTap: () {
                Navigator.pop(ctx);
                _openEditModal(
                  _EditTarget(
                    kind: _EditKind.room,
                    id: room.id,
                    name: room.name,
                    emoji: room.emoji,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text('删除房间'),
              subtitle: const Text(
                '将一并删除其下所有柜体与格子（含物品时不可删除）',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteRoom(room);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 长按柜体 → 编辑 / 移动 / 删除。
  /// [roomId] 为该柜体所属房间，需由调用方传入（「全部柜体」维度下没有当前房间）。
  void _showCabinetActionSheet(Cabinet cabinet, String roomId) {
    showCenterSheet(
      context: context,
      backgroundColor: Colors.white,
      borderRadius: 20,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.btnTextFg,
              ),
              title: const Text('编辑柜体'),
              onTap: () {
                Navigator.pop(ctx);
                _openEditModal(
                  _EditTarget(
                    kind: _EditKind.cabinet,
                    id: cabinet.id,
                    parentId: roomId,
                    name: cabinet.name,
                    emoji: cabinet.emoji,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.drive_file_move_outline,
                color: Color(0xFF4A90D9),
              ),
              title: const Text('移动到其他房间'),
              subtitle: const Text(
                '柜体及其下格子、物品一并迁移到新房间',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showMoveCabinetPicker(cabinet, roomId);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text('删除柜体'),
              subtitle: const Text(
                '将一并删除其下所有格子（含物品时不可删除）',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteCabinet(cabinet, roomId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSlotActionSheet(Slot slot, String cabinetId) {
    showCenterSheet(
      context: context,
      backgroundColor: Colors.white,
      borderRadius: 20,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.btnTextFg,
              ),
              title: const Text('编辑箱子'),
              onTap: () {
                Navigator.pop(ctx);
                _openEditModal(
                  _EditTarget(
                    kind: _EditKind.slot,
                    id: slot.id,
                    parentId: cabinetId,
                    name: slot.name,
                    emoji: slot.emoji,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text('删除箱子'),
              subtitle: const Text(
                '含物品时不可删除，请先迁移箱子内物品',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteSlot(slot, cabinetId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// 移动柜体到其他房间 —— 房间选择器（中间弹窗）
  Future<void> _showMoveCabinetPicker(
    Cabinet cabinet,
    String fromRoomId,
  ) async {
    final roomsAsync = ref.read(roomsProvider);
    final allRooms = roomsAsync.value ?? const [];

    final candidates = allRooms.where((r) => r.id != fromRoomId).toList();
    if (candidates.isEmpty) {
      ToastUtils.show(context, '暂无其他房间，请先创建新房间');
      return;
    }

    final targetRoom = await showCenterSheet<Room>(
      context: context,
      backgroundColor: Colors.white,
      borderRadius: 20,
      builder: (ctx) {
        final screenHeight = MediaQuery.sizeOf(ctx).height;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  '移动「${cabinet.name}」到',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (c, i) {
                    final room = candidates[i];
                    return ListTile(
                      leading: EmojiText(emoji: room.emoji, fontSize: 24),
                      title: Text(room.name),
                      subtitle: Text(
                        '${room.storageCount}个柜体 · ${room.items}件物品',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textHint,
                      ),
                      onTap: () => Navigator.pop(ctx, room),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (targetRoom == null) return;
    if (targetRoom.id == fromRoomId) return;

    await ref.read(cabinetActionsProvider.notifier).moveCabinet(
      cabinetId: cabinet.id,
      fromRoomId: fromRoomId,
      toRoomId: targetRoom.id,
    );

    if (mounted) {
      ToastUtils.show(
        context,
        '「${cabinet.name}」已移动到「${targetRoom.name}」',
      );
    }
  }

  // ========== 编辑模态框 ==========
  void _openEditModal(_EditTarget target) {
    setState(() {
      _editTarget = target;
      _showEditModal = true;
    });
  }

  void _closeEditModal() {
    setState(() {
      _showEditModal = false;
      _editTarget = null;
    });
  }

  void _onEditConfirm({required String name, required String icon}) {
    final t = _editTarget;
    if (t == null) return;
    switch (t.kind) {
      case _EditKind.room:
        ref
            .read(roomActionsProvider.notifier)
            .updateRoom(id: t.id, name: name, emoji: icon);
        if (_currentRoomId == t.id) _currentRoomName = name;
        break;
      case _EditKind.cabinet:
        ref
            .read(cabinetActionsProvider.notifier)
            .updateCabinet(
              id: t.id,
              roomId: t.parentId!,
              name: name,
              emoji: icon,
            );
        if (_currentCabinetId == t.id) _currentCabinetName = name;
        break;
      case _EditKind.slot:
        ref
            .read(slotActionsProvider.notifier)
            .updateSlot(
              id: t.id,
              cabinetId: t.parentId!,
              name: name,
              emoji: icon,
            );
        break;
    }
    ToastUtils.show(context, '「$name」已更新');
    _closeEditModal();
  }

  // ========== 删除确认 ==========
  Future<void> _confirmDeleteRoom(Room room) async {
    setState(() => _deleteChecking = true);
    DeletionBlocker? blocker;
    try {
      blocker = await ref
          .read(roomActionsProvider.notifier)
          .checkRoomDeletion(room.id);
    } finally {
      if (mounted) setState(() => _deleteChecking = false);
    }
    if (!mounted) return;
    if (blocker != null) {
      _showDeleteBlockedDialog(blocker);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除房间'),
        content: Text('确定删除「${room.name}」？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(roomActionsProvider.notifier).deleteRoom(room.id);
              ToastUtils.show(context, '「${room.name}」已删除');
              // 删除的正是当前浏览的房间 → 回到房间列表
              if (_currentRoomId == room.id) {
                _onTabTap(0);
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCabinet(Cabinet cabinet, String roomId) async {
    setState(() => _deleteChecking = true);
    DeletionBlocker? blocker;
    try {
      blocker = await ref
          .read(cabinetActionsProvider.notifier)
          .checkCabinetDeletion(cabinet.id);
    } finally {
      if (mounted) setState(() => _deleteChecking = false);
    }
    if (!mounted) return;
    if (blocker != null) {
      _showDeleteBlockedDialog(blocker);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除柜体'),
        content: Text('确定删除「${cabinet.name}」？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(cabinetActionsProvider.notifier)
                  .deleteCabinet(cabinet.id, roomId);
              ToastUtils.show(context, '「${cabinet.name}」已删除');
              // 删除的正是当前浏览的柜体 → 退回该房间的柜体视图
              if (_currentCabinetId == cabinet.id) {
                setState(() {
                  _tab = 1;
                  _currentCabinetId = null;
                  _currentCabinetName = '';
                });
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSlot(Slot slot, String cabinetId) async {
    setState(() => _deleteChecking = true);
    DeletionBlocker? blocker;
    try {
      blocker = await ref
          .read(slotActionsProvider.notifier)
          .checkSlotDeletion(slot.id);
    } finally {
      if (mounted) setState(() => _deleteChecking = false);
    }
    if (!mounted) return;
    if (blocker != null) {
      _showDeleteBlockedDialog(blocker);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除箱子'),
        content: Text('确定删除「${slot.name}」？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(slotActionsProvider.notifier)
                  .deleteSlot(slot.id, cabinetId);
              ToastUtils.show(context, '「${slot.name}」已删除');
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 删除被阻止时的提示对话框：指明具体子单元路径与物品数
  void _showDeleteBlockedDialog(DeletionBlocker blocker) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('无法删除'),
        content: Text(
          '「${blocker.path}」中存在 ${blocker.count} 件物品，请先将物品迁移至其他收纳位置后再删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  // ========== 物品选择 / 批量操作 ==========
  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  Future<void> _batchMigrate() async {
    if (_selectedItemIds.isEmpty) return;
    final fromSlotId = _itemsModalSlotId;
    if (fromSlotId.isEmpty) return;

    // 目标可以是房间 / 柜体 / 箱子
    final target = await showCenterSheet<StorageLocationNode>(
      context: context,
      backgroundColor: Colors.transparent,
      borderRadius: 24,
      builder: (ctx) => _buildMoveTargetPicker(ctx),
    );
    if (!mounted) return;
    if (target == null) return;
    if (target.isSlot && target.id == fromSlotId) {
      ToastUtils.show(context, '目标位置与源位置相同');
      return;
    }

    setState(() => _batchProcessing = true);
    try {
      await ref
          .read(itemsProvider.notifier)
          .migrateItems(
            _selectedItemIds.toList(),
            roomId: target.roomId,
            cabinetId: target.cabinetId,
            slotId: target.isSlot ? target.id : null,
            locationLabel: target.pathLabel,
          );
      if (mounted) {
        ToastUtils.show(
          context,
          '已迁移 ${_selectedItemIds.length} 件物品到「${target.name}」',
        );
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, '迁移失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _batchProcessing = false;
          _selectedItemIds.clear();
        });
        _closeItemsModal();
      }
    }
  }

  Widget _buildMoveTargetPicker(BuildContext ctx) {
    return Consumer(
      builder: (ctx, ref, _) {
        final treeAsync = ref.watch(storageLocationTreeProvider);
        final screenHeight = MediaQuery.sizeOf(ctx).height;
        return treeAsync.when(
          loading: () => Container(
            height: screenHeight * 0.5,
            color: Colors.white,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
          error: (e, _) => Container(
            height: screenHeight * 0.5,
            color: Colors.white,
            alignment: Alignment.center,
            child: Text('加载失败: $e'),
          ),
          data: (nodes) {
            return Container(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.5),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '选择目标位置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Flexible(
                    child: nodes.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text(
                                '暂无可选位置',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: nodes.length,
                            itemBuilder: (ctx, i) {
                              final node = nodes[i];
                              final isCurrent =
                                  node.isSlot && node.id == _itemsModalSlotId;
                              return ListTile(
                                leading: EmojiText(
                                  emoji: node.emoji,
                                  fontSize: 22,
                                ),
                                title: Text(node.name),
                                subtitle: Text(
                                  node.subLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isCurrent
                                    ? const Text(
                                        '当前',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textHint,
                                      ),
                                onTap: isCurrent
                                    ? null
                                    : () => Navigator.pop(ctx, node),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _batchDelete() async {
    if (_selectedItemIds.isEmpty) return;
    if (_itemsModalSlotId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定删除选中的 ${_selectedItemIds.length} 件物品？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _batchProcessing = true);
    try {
      await ref
          .read(itemsProvider.notifier)
          .removeItems(_selectedItemIds.toList());
      if (mounted) {
        ToastUtils.show(context, '已删除 ${_selectedItemIds.length} 件物品');
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, '删除失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _batchProcessing = false;
          _selectedItemIds.clear();
        });
        _closeItemsModal();
      }
    }
  }

  // ========== 构建 UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildTopBar(),
                  const SizedBox(height: 12),
                  _buildTypeTabs(),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.coral,
                      onRefresh: _onRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAreaHeader(),
                            const SizedBox(height: 4),
                            _buildContent(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_showAddModal)
              AddSpaceModal(
                onClose: _closeAddModal,
                onConfirm: _onAddConfirm,
                currentLevel: _addLevel,
                currentRoomId: _addModalRoomId,
                currentCabinetId: _addModalCabinetId,
              ),
            if (_showEditModal && _editTarget != null)
              EditSpaceModal(
                title: _editTarget!.title,
                initialName: _editTarget!.name,
                initialIcon: _editTarget!.emoji,
                onClose: _closeEditModal,
                onConfirm: _onEditConfirm,
              ),
            if (_showItemsModal) _buildItemsModalFromProvider(),
            if (_batchProcessing || _deleteChecking)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ========== 顶部搜索栏 ==========
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
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
                  const Icon(Icons.search, size: 18, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: '搜索房间、柜体、箱子、物品…',
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
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openAddModal,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                // 主按钮 = 实心珊瑚（稿子 `.btn.primary` 无渐变）
                color: AppColors.btnPrimaryBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.btnPrimaryShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, size: 20, color: AppColors.btnPrimaryFg),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 浏览维度按钮（房间 / 柜体 / 箱子） ==========
  Widget _buildTypeTabs() {
    const labels = ['房间', '柜体', '箱子'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isActive = _tab == index;
          return GestureDetector(
            onTap: () => _onTabTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? AppColors.chipSelectedBg : AppColors.chipBg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? AppColors.btnPrimaryShadow
                        : AppColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: isActive ? 14 : 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? AppColors.chipSelectedFg
                      : AppColors.chipFg,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ========== 当前区域大标题 ==========
  /// 该区域（当前维度 + 已进入的房间/柜体）内的物品总数
  int _areaItemCount(List<Item> items) {
    if (_tab == 0) return items.length;
    if (_tab == 1) {
      return _currentRoomId == null
          ? items.length
          : items.where((i) => i.roomId == _currentRoomId).length;
    }
    return _currentCabinetId == null
        ? items.length
        : items.where((i) => i.cabinetId == _currentCabinetId).length;
  }

  Widget _buildAreaHeader() {
    final String title;
    switch (_tab) {
      case 0:
        title = '全部空间';
        break;
      case 1:
        title = _currentRoomId == null ? '全部柜体' : _currentRoomName;
        break;
      default:
        title = _currentCabinetId == null ? '全部箱子' : _currentCabinetName;
    }

    // 进入柜体后补上所属房间，避免同名箱子分不清在哪
    final path = (_tab == 2 && _currentCabinetId != null)
        ? '$_currentRoomName / '
        : '';

    final itemsAsync = ref.watch(itemsProvider);
    final total = itemsAsync.whenOrNull(data: _areaItemCount) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // 已进入房间/柜体时，给出一个回到上层的快捷入口
              if (_currentRoomId != null)
                GestureDetector(
                  onTap: () => _onTabTap(_tab),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      // 裸 Row 会把「箭头 + 文字」整体居中，文字因此偏右约 7px；
                      // PillContent 在对侧补等宽留白，让文字真正居中。
                      child: PillContent(
                        label: _tab == 2 ? '全部箱子' : '全部柜体',
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        leading: Icons.arrow_upward,
                        iconSize: 11,
                        gap: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$path共 $total 件物品',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ========== 内容 ==========
  Widget _buildContent() {
    switch (_tab) {
      case 0:
        return _buildRoomsView();
      case 1:
        return _currentRoomId == null
            ? _buildAllCabinetsView()
            : _buildRoomCabinetsView(_currentRoomId!);
      default:
        return _currentCabinetId == null
            ? _buildAllSlotsView()
            : _buildCabinetSlotsView(_currentCabinetId!);
    }
  }

  /// 维度 0：房间列表
  Widget _buildRoomsView() {
    final roomsAsync = ref.watch(roomsProvider);
    final allItems = ref.watch(itemsProvider).value ?? const <Item>[];

    return roomsAsync.when(
      loading: _buildLoading,
      error: (e, _) => _buildError(e),
      data: (rooms) {
        // 命中搜索的物品：直接列在房间卡片之前，保证「搜物品」能搜到东西
        final matched = _matchedItems(allItems);
        // 房间出现在结果里的两种情况：名字命中，或房间里（含柜体/箱子）有命中的物品
        final list = rooms
            .where(
              (r) =>
                  _match(r.name) ||
                  matched.any((i) => i.roomId == r.id),
            )
            .toList();
        if (list.isEmpty && matched.isEmpty) {
          return _buildEmpty(
            rooms.isEmpty
                ? '还没有房间\n点击右上角 + 添加你的第一个房间'
                : '没有匹配「$_searchQuery」的房间或物品',
          );
        }
        final matchedSection = _buildMatchedItemsSection(matched);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (matchedSection != null) ...[
              matchedSection,
              const SizedBox(height: 10),
            ],
            for (var i = 0; i < list.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NavCard(
                  emoji: list[i].emoji,
                  color: list[i].color,
                  title: list[i].name,
                  subtitle:
                      '${list[i].storageCount} 个柜体 · ${list[i].items} 件物品',
                  delay: i * 0.06,
                  onTap: () => _enterRoom(list[i]),
                  onLongPress: () => _showRoomActionSheet(list[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 维度 1：某个房间 → 柜体 + 房间内的物品
  Widget _buildRoomCabinetsView(String roomId) {
    final cabinetsAsync = ref.watch(cabinetsByRoomProvider(roomId));
    final itemsAsync = ref.watch(itemsProvider);

    return cabinetsAsync.when(
      loading: _buildLoading,
      error: (e, _) => _buildError(e),
      data: (cabinets) {
        final inRoom = (itemsAsync.value ?? const <Item>[])
            .where((i) => i.roomId == roomId)
            .toList();
        // 直接放在房间里、不归属任何柜体的物品
        final loose = inRoom
            .where((i) => (i.cabinetId ?? '').isEmpty && _matchItem(i))
            .toList();
        // 搜索时把房间内所有命中物品（含收在柜体/箱子深处的）统一列在顶部；
        // 此时 loose 是 matchedInRoom 的子集，就不再单独渲染「房间内的物品」，
        // 免得同一件东西出现两次。
        final searching = _searchQuery.isNotEmpty;
        final matchedInRoom = _matchedItems(inRoom);
        final matchedSection = _buildMatchedItemsSection(matchedInRoom);
        // 柜体出现在结果里的两种情况：自己名字命中，或柜内（含箱子）有命中物品
        final visibleCabinets = cabinets
            .where(
              (c) =>
                  _match(c.name) ||
                  matchedInRoom.any((i) => i.cabinetId == c.id),
            )
            .toList();

        if (visibleCabinets.isEmpty &&
            loose.isEmpty &&
            matchedInRoom.isEmpty) {
          return _buildEmpty(
            cabinets.isEmpty
                ? '「$_currentRoomName」还没有柜体\n点击右上角 + 添加柜体，物品也可以直接放进房间'
                : '没有匹配的内容',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (matchedSection != null) ...[
              matchedSection,
              const SizedBox(height: 10),
            ],
            if (visibleCabinets.isNotEmpty) ...[
              _buildSectionLabel(
                '柜体',
                visibleCabinets.length,
                AppColors.coralDeep,
              ),
              for (var i = 0; i < visibleCabinets.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NavCard(
                    emoji: visibleCabinets[i].emoji,
                    color: visibleCabinets[i].color,
                    title: visibleCabinets[i].name,
                    subtitle:
                        '${visibleCabinets[i].items} 件物品 · '
                        '${visibleCabinets[i].hasPhoto ? '已拍实景图' : '暂无实景图'}',
                    delay: i * 0.06,
                    onTap: () => _enterCabinet(
                      visibleCabinets[i],
                      roomId,
                      _currentRoomName,
                    ),
                    onLongPress: () =>
                        _showCabinetActionSheet(visibleCabinets[i], roomId),
                  ),
                ),
            ],
            if (!searching && loose.isNotEmpty) ...[
              _buildSectionLabel('房间内的物品', loose.length, AppColors.info),
              for (var i = 0; i < loose.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ItemCard(
                    item: loose[i],
                    delay: i * 0.05,
                    onTap: () => context.push('/detail/${loose[i].id}'),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  /// 维度 1（全局）：全部柜体
  Widget _buildAllCabinetsView() {
    final roomsAsync = ref.watch(roomsProvider);

    return roomsAsync.when(
      loading: _buildLoading,
      error: (e, _) => _buildError(e),
      data: (rooms) {
        final matched = _matchedItems(
          ref.watch(itemsProvider).value ?? const <Item>[],
        );
        final entries = <({Room room, Cabinet cabinet})>[];
        for (final room in rooms) {
          final cabinets =
              ref.watch(cabinetsByRoomProvider(room.id)).value ??
              const <Cabinet>[];
          for (final cabinet in cabinets) {
            // 柜体自己命中、所属房间命中，或柜内（含箱子）有命中物品
            if (_match(cabinet.name) ||
                _match(room.name) ||
                matched.any((i) => i.cabinetId == cabinet.id)) {
              entries.add((room: room, cabinet: cabinet));
            }
          }
        }
        if (entries.isEmpty && matched.isEmpty) {
          return _buildEmpty(
            rooms.isEmpty
                ? '还没有房间\n先添加房间，再往房间里添加柜体'
                : (_searchQuery.isEmpty
                      ? '还没有柜体\n点进某个房间后，点击右上角 + 添加柜体'
                      : '没有匹配「$_searchQuery」的柜体或物品'),
          );
        }
        final matchedSection = _buildMatchedItemsSection(matched);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (matchedSection != null) ...[
              matchedSection,
              const SizedBox(height: 10),
            ],
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NavCard(
                  emoji: entries[i].cabinet.emoji,
                  color: entries[i].cabinet.color,
                  title: entries[i].cabinet.name,
                  subtitle:
                      '${entries[i].room.name} · ${entries[i].cabinet.items} 件物品',
                  delay: i * 0.05,
                  onTap: () => _enterCabinet(
                    entries[i].cabinet,
                    entries[i].room.id,
                    entries[i].room.name,
                  ),
                  onLongPress: () => _showCabinetActionSheet(
                    entries[i].cabinet,
                    entries[i].room.id,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 维度 2：某个柜体 → 箱子 + 柜内的物品
  Widget _buildCabinetSlotsView(String cabinetId) {
    final slotsAsync = ref.watch(slotsByCabinetProvider(cabinetId));
    final itemsAsync = ref.watch(itemsProvider);

    return slotsAsync.when(
      loading: _buildLoading,
      error: (e, _) => _buildError(e),
      data: (slots) {
        final inCabinet = (itemsAsync.value ?? const <Item>[])
            .where((i) => i.cabinetId == cabinetId)
            .toList();
        // 直接放在柜体里、不归属任何箱子的物品
        final loose = inCabinet
            .where((i) => (i.slotId ?? '').isEmpty && _matchItem(i))
            .toList();
        // 搜索时把柜内所有命中物品（含收在箱子里的）统一列在顶部，
        // 此时 loose 是它的子集，就不再单独渲染「柜内的物品」避免重复。
        final searching = _searchQuery.isNotEmpty;
        final matchedInCabinet = _matchedItems(inCabinet);
        final matchedSection = _buildMatchedItemsSection(matchedInCabinet);
        // 箱子出现在结果里的两种情况：自己名字命中，或箱内有命中物品
        final visibleSlots = slots
            .where(
              (s) =>
                  _match(s.name) ||
                  matchedInCabinet.any((i) => i.slotId == s.id),
            )
            .toList();

        if (visibleSlots.isEmpty &&
            loose.isEmpty &&
            matchedInCabinet.isEmpty) {
          return _buildEmpty(
            slots.isEmpty
                ? '「$_currentCabinetName」还没有箱子\n点击右上角 + 添加箱子，物品也可以直接放进柜体'
                : '没有匹配的内容',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (matchedSection != null) ...[
              matchedSection,
              const SizedBox(height: 10),
            ],
            if (visibleSlots.isNotEmpty) ...[
              _buildSectionLabel(
                '箱子',
                visibleSlots.length,
                AppColors.coralDeep,
              ),
              for (var i = 0; i < visibleSlots.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NavCard(
                    emoji: visibleSlots[i].emoji,
                    color: visibleSlots[i].color,
                    title: visibleSlots[i].name,
                    subtitle: '${visibleSlots[i].items} 件物品',
                    delay: i * 0.06,
                    onTap: () => _openItemsModal(
                      '$_currentCabinetName / ${visibleSlots[i].name}',
                      visibleSlots[i].id,
                    ),
                    onLongPress: () =>
                        _showSlotActionSheet(visibleSlots[i], cabinetId),
                  ),
                ),
            ],
            if (!searching && loose.isNotEmpty) ...[
              _buildSectionLabel('柜内的物品', loose.length, AppColors.info),
              for (var i = 0; i < loose.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ItemCard(
                    item: loose[i],
                    delay: i * 0.05,
                    onTap: () => context.push('/detail/${loose[i].id}'),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  /// 维度 2（全局）：全部箱子
  Widget _buildAllSlotsView() {
    final roomsAsync = ref.watch(roomsProvider);

    return roomsAsync.when(
      loading: _buildLoading,
      error: (e, _) => _buildError(e),
      data: (rooms) {
        final matched = _matchedItems(
          ref.watch(itemsProvider).value ?? const <Item>[],
        );
        final entries = <({Room room, Cabinet cabinet, Slot slot})>[];
        for (final room in rooms) {
          final cabinets =
              ref.watch(cabinetsByRoomProvider(room.id)).value ??
              const <Cabinet>[];
          for (final cabinet in cabinets) {
            final slots =
                ref.watch(slotsByCabinetProvider(cabinet.id)).value ??
                const <Slot>[];
            for (final slot in slots) {
              // 箱子/柜体/房间自己命中，或箱内有命中物品
              if (_match(slot.name) ||
                  _match(cabinet.name) ||
                  _match(room.name) ||
                  matched.any((i) => i.slotId == slot.id)) {
                entries.add((room: room, cabinet: cabinet, slot: slot));
              }
            }
          }
        }
        if (entries.isEmpty && matched.isEmpty) {
          return _buildEmpty(
            _searchQuery.isEmpty
                ? '还没有箱子\n点进某个柜体后，点击右上角 + 添加箱子'
                : '没有匹配「$_searchQuery」的箱子或物品',
          );
        }
        final matchedSection = _buildMatchedItemsSection(matched);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (matchedSection != null) ...[
              matchedSection,
              const SizedBox(height: 10),
            ],
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NavCard(
                  emoji: entries[i].slot.emoji,
                  color: entries[i].slot.color,
                  title: entries[i].slot.name,
                  subtitle:
                      '${entries[i].room.name} / ${entries[i].cabinet.name} · '
                      '${entries[i].slot.items} 件物品',
                  delay: i * 0.05,
                  onTap: () => _openItemsModal(
                    '${entries[i].cabinet.name} / ${entries[i].slot.name}',
                    entries[i].slot.id,
                  ),
                  onLongPress: () => _showSlotActionSheet(
                    entries[i].slot,
                    entries[i].cabinet.id,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ========== 通用小组件 ==========
  Widget _buildSectionLabel(String text, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.coral),
      ),
    );
  }

  Widget _buildError(Object e) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          '加载失败: $e',
          style: const TextStyle(color: AppColors.textHint),
        ),
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 44),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  /// 箱子内物品模态框（支持批量迁移 / 批量删除）
  Widget _buildItemsModalFromProvider() {
    if (_itemsModalSlotId.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemsAsync = ref.watch(itemsProvider);

    return itemsAsync.when(
      loading: () => Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: Center(
            child: Text(
              '加载失败: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      data: (allItems) {
        final items = allItems
            .where((i) => i.slotId == _itemsModalSlotId)
            .toList();
        return ItemsPreviewModal(
          title: _itemsModalTitle,
          items: items,
          selectedItemIds: _selectedItemIds,
          onClose: _closeItemsModal,
          onToggleItem: _toggleItemSelection,
          onBatchMigrate: _batchMigrate,
          onBatchDelete: _batchDelete,
        );
      },
    );
  }
}

// ========== 导航卡片（房间 / 柜体 / 箱子共用） ==========
class _NavCard extends StatelessWidget {
  final String emoji;
  final Color color;
  final String title;
  final String subtitle;
  final double delay;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _NavCard({
    required this.emoji,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.delay,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 380 + (delay * 1000).round()),
        curve: const Cubic(0.34, 1.4, 0.64, 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: EmojiText(emoji: emoji, fontSize: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== 物品卡片（散放在房间/柜体内的物品，配色区别于柜体卡片） ==========
class _ItemCard extends StatelessWidget {
  final Item item;
  final double delay;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 340 + (delay * 1000).round()),
        curve: const Cubic(0.34, 1.4, 0.64, 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(10 * (1 - value), 0),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // 淡蓝底 + 蓝边，与白色柜体/箱子卡片一眼区分
            color: const Color(0xFFF4F9FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.infoLight, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(
                  child: EmojiText(emoji: '📦', fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.location.isEmpty ? '未指定位置' : item.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== 编辑目标数据类 ==========
enum _EditKind { room, cabinet, slot }

class _EditTarget {
  final _EditKind kind;
  final String id;
  final String? parentId; // cabinet: roomId; slot: cabinetId
  final String name;
  final String emoji;

  const _EditTarget({
    required this.kind,
    required this.id,
    this.parentId,
    required this.name,
    required this.emoji,
  });

  String get title {
    switch (kind) {
      case _EditKind.room:
        return '编辑房间';
      case _EditKind.cabinet:
        return '编辑柜体';
      case _EditKind.slot:
        return '编辑箱子';
    }
  }
}
