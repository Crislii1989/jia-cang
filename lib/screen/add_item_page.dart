import 'package:flutter/material.dart' hide DatePickerTheme;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/models/category_item.dart';
import 'package:jia_cang/models/picker_item.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/widgets/center_sheet.dart';
import 'package:jia_cang/widgets/emoji_text.dart';
import 'package:jia_cang/widgets/floating_bar.dart';
import 'package:jia_cang/widgets/gradient_background.dart';
import 'package:jia_cang/widgets/photo_image.dart';
import 'package:jia_cang/widgets/toast_utils.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/providers/storage_providers.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/services/photo_service.dart';

// ==================== 主页面 ====================

/// 扫一扫识别结果预填充数据，用于从扫描页跳转到新建物品页时回填表单。
///
/// 也用于新建柜体后跳转新增物品页时预填收纳位置
///（preselectedCabinetId / preselectedSlotId / preselectedLocationLabel）。
class AddItemInitialValues {
  final String name;
  final String? category;

  /// AI 识别出的品牌：物品表已无品牌字段，这里只作为识别信息传递，
  /// 预填时并入备注（见 `_prefillFromScanResult`），避免丢失识别结果。
  final String? brand;
  final String? description;
  final String? photoPath;

  /// 预填收纳位置 —— 房间 id（物品直接存放于房间，不指定柜体时用）
  final String? preselectedRoomId;
  /// 预填收纳位置 —— 柜体 id（归属柜体，不指定格子时用）
  final String? preselectedCabinetId;
  /// 预填收纳位置 —— 格子 id（指定格子时用）
  final String? preselectedSlotId;
  /// 预填收纳位置 —— 显示标签（如 "卧室 / 床头柜"）
  final String? preselectedLocationLabel;

  const AddItemInitialValues({
    required this.name,
    this.category,
    this.brand,
    this.description,
    this.photoPath,
    this.preselectedRoomId,
    this.preselectedCabinetId,
    this.preselectedSlotId,
    this.preselectedLocationLabel,
  });
}

class AddItemPage extends ConsumerStatefulWidget {
  /// 编辑模式时传入的物品 id；新增模式为 null
  final String? itemId;

  /// 扫一扫识别结果预填充数据；仅新增模式且非编辑时生效
  final AddItemInitialValues? initialValues;

  const AddItemPage({super.key, this.itemId, this.initialValues});

  @override
  ConsumerState<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends ConsumerState<AddItemPage>
    with TickerProviderStateMixin {
  bool get _isEdit => widget.itemId != null;

  // 表单控制器
  final _nameController = TextEditingController();
  // 到期日与登记时间都是「点选/自动」型字段，用只读输入框承载展示，
  // 真实值分别存在 _expiryDate / _registeredAt 里。
  final _expiryController = TextEditingController();
  final _registeredController = TextEditingController();
  final _noteController = TextEditingController();
  final _scrollController = ScrollController();

  /// 到期日（可选）
  DateTime? _expiryDate;

  /// 登记时间：新增时按系统时间自动录入，编辑时沿用原值
  DateTime _registeredAt = DateTime.now();

  // 照片（真实本地文件路径 + 上传状态）
  final List<PhotoEntry> _photos = [];
  bool _isPicking = false;

  // 状态
  String? _selectedCategory;
  String? _selectedCategoryKey;
  String? _selectedLocation;
  StorageLocationNode? _selectedLocationNode;

  // 编辑模式下记录原始照片路径，用于提交时清理被删除的文件
  List<String> _originalPhotos = const [];

  // 扫一扫预填充：待匹配的 AI 分类标签（数据库分类异步加载完成后再匹配）
  String? _pendingCategoryLabel;

  // 编辑模式预填充：待反查中文名的 categoryKey（分类数据到位后再匹配）
  String? _pendingCategoryKey;

  // 编辑模式的预填充是否已经成功执行过（用于 initState 里的兜底重试）
  bool _didPrefill = false;

  // 预填位置：待匹配的 roomId/cabinetId/slotId（storageLocationTree 加载完成后匹配）
  String? _pendingRoomId;
  String? _pendingCabinetId;
  String? _pendingSlotId;

  // 成功弹窗
  bool _showSuccess = false;
  String _successTitle = '保存成功！';
  String _successSub = '';
  String _successBtnText = '好的';
  VoidCallback? _successBtnAction;

  @override
  void initState() {
    super.initState();

    // 登记时间默认按系统时间录入（编辑模式会在 _prefillFromItem 里换成原值）
    _syncDateFields();

    // 编辑模式：从数据库预填充；扫一扫：用识别结果预填充；其余新增模式：空白表单
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEdit) {
        _prefillFromItem();
      } else if (widget.initialValues != null) {
        _prefillFromScanResult();
      }
    });

    // 兜底重试：itemsProvider 是 autoDispose 的，页面被回收后重建（或直接
    // 深链进入）时可能还处在 loading，此时上面那次预填充会静默失效、整张
    // 表单空着。等它真正有数据了再补一次，保证编辑一定回填。
    // 只在编辑模式订阅：新增模式根本不需要物品数据，订阅会把无关的
    // 数据库依赖拖进来。
    if (_isEdit) {
      ref.listenManual(itemsProvider, (prev, next) {
        if (!_didPrefill && next.hasValue) _prefillFromItem();
      });
    }

    // 监听分类数据加载完成，匹配扫一扫预填充的分类标签
    ref.listenManual(categoryManagerProvider, (prev, next) {
      if (!next.hasValue) return;
      if (_pendingCategoryLabel != null) _tryMatchPendingCategory();
      if (_pendingCategoryKey != null) _resolveCategoryFromKey();
    });

    // 监听收纳位置树加载完成，匹配预填的 roomId/cabinetId/slotId
    ref.listenManual(storageLocationTreeProvider, (prev, next) {
      if (next.hasValue &&
          (_pendingRoomId != null || _pendingCabinetId != null)) {
        _tryMatchPendingLocation();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expiryController.dispose();
    _registeredController.dispose();
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==================== 日期字段（到期日 / 登记时间）====================

  /// 日期展示格式：2026-09-15
  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// 把 [_expiryDate] / [_registeredAt] 同步到两个只读输入框。
  void _syncDateFields() {
    _expiryController.text = _expiryDate == null
        ? ''
        : _formatDate(_expiryDate!);
    _registeredController.text = _formatDate(_registeredAt);
  }

  /// 选择到期日。清空需要通过「清除」按钮（[_clearExpiryDate]）。
  Future<void> _pickExpiryDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      // 支持记录已过期的东西（食品/药品），因此起始年份往前放宽
      initialDate: _expiryDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 40),
      helpText: '选择到期日',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null) return;
    setState(() {
      _expiryDate = picked;
      _syncDateFields();
    });
  }

  void _clearExpiryDate() {
    setState(() {
      _expiryDate = null;
      _syncDateFields();
    });
  }

  // ==================== 编辑模式预填充 ====================
  /// 按 id 从 [itemsProvider] 里取物品；物品数据未就绪时返回 null。
  ///
  /// 这里刻意不走 `itemByIdProvider`：它是派生的 autoDispose provider，
  /// 页面首帧就读取时（itemsProvider 还是 loading）会把 `null` 结果缓存下来，
  /// 之后即使物品加载完成，在监听回调里再读到的仍是这个过期的 null，
  /// 于是整张编辑表单一直是空的。直接读列表即可拿到当前值。
  Item? _itemById(String id) {
    final items = ref.read(itemsProvider).value ?? const <Item>[];
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _prefillFromItem() {
    final item = _itemById(widget.itemId!);
    if (item == null) return;

    _nameController.text = item.name;
    _noteController.text = item.note;
    _expiryDate = item.expiryDate;
    _registeredAt = item.createdAt;
    _syncDateFields();

    // 分类：库里存的是 key（sports），表单要显示中文名（运动）。
    // 只回填 key 不回填展示名，会让分类框空成「选择分类」，
    // 用户以为分类被清掉了、保存还会被「请选择物品分类」拦下。
    _pendingCategoryKey = item.categoryKey.isEmpty ? null : item.categoryKey;
    _resolveCategoryFromKey();
    _selectedLocation = item.location == '未知' ? null : item.location;

    // 还原照片
    _originalPhotos = List<String>.from(item.photos);
    _photos
      ..clear()
      ..addAll(
        item.photos.map(
          (p) => PhotoEntry(path: p, status: PhotoStatus.success),
        ),
      );

    // 还原收纳位置节点：格子 > 柜体 > 房间
    if (item.roomId != null || item.cabinetId != null || item.slotId != null) {
      final nodes = ref.read(storageLocationTreeProvider).value ?? const [];
      StorageLocationNode? matched;
      if (item.slotId != null) {
        matched = nodes
            .where((n) => n.isSlot && n.id == item.slotId)
            .cast<StorageLocationNode?>()
            .firstWhere((_) => true, orElse: () => null);
      }
      matched ??= item.cabinetId != null
          ? nodes
                .where((n) => !n.isSlot && !n.isRoom && n.id == item.cabinetId)
                .cast<StorageLocationNode?>()
                .firstWhere((_) => true, orElse: () => null)
          : null;
      // 物品直接存放在房间（无柜体/格子）
      matched ??= item.roomId != null
          ? nodes
                .where((n) => n.isRoom && n.id == item.roomId)
                .cast<StorageLocationNode?>()
                .firstWhere((_) => true, orElse: () => null)
          : null;
      _selectedLocationNode = matched;
    }

    _didPrefill = true;
    setState(() {});
  }

  // ==================== 扫一扫预填充 ====================
  void _prefillFromScanResult() {
    final iv = widget.initialValues;
    if (iv == null) return;

    _nameController.text = iv.name;
    // 识别出的品牌信息没有独立字段可放了（品牌已被到期日取代），
    // 并入备注，避免用户辛苦识别的信息白白丢掉。
    if (iv.brand != null && iv.brand!.isNotEmpty) {
      _noteController.text = '品牌：${iv.brand}';
    }
    if (iv.description != null && iv.description!.isNotEmpty) {
      _noteController.text = _noteController.text.isEmpty
          ? iv.description!
          : '${_noteController.text}\n${iv.description!}';
    }
    if (iv.photoPath != null && iv.photoPath!.isNotEmpty) {
      _photos
        ..clear()
        ..add(PhotoEntry(path: iv.photoPath!, status: PhotoStatus.success));
    }
    // 分类需匹配数据库分类（异步），暂存标签等待 provider 就绪后匹配
    if (iv.category != null && iv.category!.isNotEmpty) {
      _pendingCategoryLabel = iv.category;
      _tryMatchPendingCategory();
    }
    // 预填位置（异步匹配 storageLocationTree 节点）
    if (iv.preselectedRoomId != null ||
        iv.preselectedCabinetId != null ||
        iv.preselectedSlotId != null) {
      _pendingRoomId = iv.preselectedRoomId;
      _pendingCabinetId = iv.preselectedCabinetId;
      _pendingSlotId = iv.preselectedSlotId;
      _selectedLocation = iv.preselectedLocationLabel;
      _tryMatchPendingLocation();
    }
    setState(() {});
  }

  /// 将预填的 roomId/cabinetId/slotId 匹配到 storageLocationTree 节点。
  /// 树尚未加载时跳过，由 listenManual 触发重试。
  void _tryMatchPendingLocation() {
    final roomId = _pendingRoomId;
    final cabinetId = _pendingCabinetId;
    final slotId = _pendingSlotId;
    if (roomId == null && cabinetId == null && slotId == null) return;

    final nodes = ref.read(storageLocationTreeProvider).value ?? const [];
    if (nodes.isEmpty) return;

    StorageLocationNode? match;
    if (slotId != null) {
      match = nodes
          .where((n) => n.isSlot && n.id == slotId)
          .cast<StorageLocationNode?>()
          .firstWhere((_) => true, orElse: () => null);
    }
    // 优先匹配格子，未命中则按 cabinetId 匹配柜体节点（排除房间节点）
    if (match == null && cabinetId != null) {
      match = nodes
          .where((n) => !n.isSlot && !n.isRoom && n.id == cabinetId)
          .cast<StorageLocationNode?>()
          .firstWhere((_) => true, orElse: () => null);
    }
    // 再未命中则按 roomId 匹配「房间本身」节点（物品直接存放于房间）
    if (match == null && roomId != null) {
      match = nodes
          .where((n) => n.isRoom && n.id == roomId)
          .cast<StorageLocationNode?>()
          .firstWhere((_) => true, orElse: () => null);
    }
    if (match != null) {
      _selectedLocationNode = match;
      _selectedLocation = match.pathLabel;
    }
    _pendingRoomId = null;
    _pendingCabinetId = null;
    _pendingSlotId = null;
    setState(() {});
  }

  /// 编辑模式：把物品的 categoryKey 反查成中文分类名回填到选择框。
  ///
  /// 分类表是异步加载的，没就绪时先保留 `_pendingCategoryKey` 交给
  /// `initState` 里的 listen 重试；否则会在数据到位之前就把 key 当成
  /// 「分类已被删除」处理。
  void _resolveCategoryFromKey() {
    final key = _pendingCategoryKey;
    if (key == null || key.isEmpty) return;
    // 分类表尚未加载完成（只有虚拟分类）时先等着，避免误判为已删除
    if (!ref.read(categoryManagerProvider).hasValue) return;

    final cats = ref.read(availableCategoriesProvider);
    String? label;
    for (final c in cats) {
      if (c.key == key) {
        label = c.label;
        break;
      }
    }

    _selectedCategory = label ?? key; // 分类被删掉时退回显示 key，别显示成空
    _selectedCategoryKey = key;
    _pendingCategoryKey = null;
    setState(() {});
  }

  /// 将 AI 返回的分类标签匹配到数据库分类，命中则设置 _selectedCategory/_selectedCategoryKey。
  /// 数据库分类尚未加载时跳过，由 build 中 watch 触发重试。
  void _tryMatchPendingCategory() {
    final label = _pendingCategoryLabel;
    if (label == null) return;
    final dbCats = ref.read(categoryManagerProvider).value ?? const [];
    if (dbCats.isEmpty) return;

    CategoryItem? match;
    for (final c in dbCats) {
      if (c.label == label) {
        match = c;
        break;
      }
    }
    // 精确匹配失败时尝试包含关系兜底（如 AI 返回"数码电子"匹配"数码"）
    if (match == null) {
      for (final c in dbCats) {
        if (label.contains(c.label) || c.label.contains(label)) {
          match = c;
          break;
        }
      }
    }
    if (match != null) {
      _selectedCategory = match.label;
      _selectedCategoryKey = match.id;
    }
    _pendingCategoryLabel = null;
    setState(() {});
  }

  // ==================== Toast ====================
  void _showToast(String message) {
    // 使用 Overlay 实现的顶部 Toast，避免 SnackBar floating 在底部按钮/模板字段
    // 占用较多垂直空间时触发 "Floating SnackBar presented off screen" 断言。
    ToastUtils.show(context, message);
  }

  // ==================== 照片操作 ====================
  Future<void> _addPhoto() async {
    if (_isPicking) return;
    if (_photos.length >= PhotoService.maxPhotos) {
      _showToast('最多添加 ${PhotoService.maxPhotos} 张照片');
      return;
    }
    setState(() => _isPicking = true);

    final remaining = PhotoService.maxPhotos - _photos.length;
    final result = await PhotoService.instance.pickFromGallery(
      remaining: remaining,
    );

    if (!mounted) return;
    setState(() {
      _photos.addAll(result.entries);
      _isPicking = false;
    });

    if (result.error != null && result.entries.isEmpty) {
      _showToast(result.error!);
    } else if (result.error != null) {
      _showToast('部分图片未通过：${result.error}');
    } else if (result.entries.isNotEmpty) {
      _showToast('已添加 ${result.entries.length} 张照片');
    }
  }

  Future<void> _addPhotoFromCamera() async {
    if (_isPicking) return;
    if (_photos.length >= PhotoService.maxPhotos) {
      _showToast('最多添加 ${PhotoService.maxPhotos} 张照片');
      return;
    }
    setState(() => _isPicking = true);

    final result = await PhotoService.instance.pickFromCamera();

    if (!mounted) return;
    setState(() {
      _photos.addAll(result.entries);
      _isPicking = false;
    });

    if (result.error != null) {
      _showToast(result.error!);
    } else if (result.entries.isNotEmpty) {
      _showToast('已添加照片');
    }
  }

  void _showPhotoSourceSheet() {
    showCenterSheet(
      context: context,
      backgroundColor: Colors.white,
      borderRadius: 20,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.btnTextFg,
              ),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.btnTextFg,
              ),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhotoFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.textSecondary),
              title: const Text('取消'),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    final removed = _photos[index];
    setState(() {
      _photos.removeAt(index);
    });
    // 编辑模式下：被删除的若是已存库照片，提交时再清理文件；
    // 新增模式下草稿照片直接删除文件
    if (!_isEdit && !_originalPhotos.contains(removed.path)) {
      PhotoService.instance.deleteFile(removed.path);
    }
  }

  void _retryPhoto(int index) {
    final entry = _photos[index];
    if (entry.status != PhotoStatus.failed) return;
    setState(() {
      _photos[index] = entry.copyWith(status: PhotoStatus.uploading);
    });
    // 失败重试：重新拷贝（失败条目 path 指向缓存原图路径的场景极少，这里直接移除让用户重选）
    setState(() {
      _photos.removeAt(index);
    });
    _showToast('请重新选择该照片');
  }

  // ==================== 选择器 ====================
  void _openCategoryPicker() {
    // 分类选择：动态读取数据库分类（含用户增删改）
    final dbCats = ref.read(categoryManagerProvider).value ?? const [];
    final data = [
      for (final c in dbCats) PickerItem(emoji: c.emoji, name: c.label),
    ];
    final labelToKey = {for (final c in dbCats) c.label: c.id};

    showCenterSheet(
      context: context,
      backgroundColor: Colors.transparent,
      borderRadius: 24,
      builder: (ctx) => _PickerSheet(
        title: '选择分类',
        items: data,
        selectedName: _selectedCategory,
        onPick: (name) {
          setState(() {
            _selectedCategory = name;
            _selectedCategoryKey = labelToKey[name];
          });
          Navigator.pop(ctx);
          _showToast('已选择：$name');
        },
      ),
    );
  }

  // ==================== 收纳位置选择（联动柜体/格子）====================
  void _openLocationPicker() {
    showCenterSheet(
      context: context,
      backgroundColor: Colors.transparent,
      borderRadius: 24,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final asyncNodes = ref.watch(storageLocationTreeProvider);
            final allNodes = asyncNodes.value ?? const [];
            // 同时展示房间、柜体、格子三类收纳位置。
            // storageLocationTreeProvider 已按「房间→其下柜体→柜体下格子」顺序生成节点，
            // _LocationTile 用颜色区分层级（房间绿、柜体黄、格子蓝）。
            return _LocationPickerSheet(
              nodes: allNodes,
              isLoading: asyncNodes.isLoading,
              selectedNode: _selectedLocationNode,
              onPick: (node) {
                setState(() {
                  _selectedLocationNode = node;
                  _selectedLocation = node.pathLabel;
                });
                Navigator.pop(ctx);
                _showToast('已选择：${node.pathLabel}');
              },
              onClear: () {
                setState(() {
                  _selectedLocationNode = null;
                  _selectedLocation = null;
                });
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  // ==================== 保存 ====================
  Future<void> _saveItem(bool andContinue) async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showToast('请填写物品名称');
      FocusScope.of(context).unfocus();
      return;
    }

    // 必须选择分类
    if (_selectedCategory == null) {
      _showToast('请选择物品分类');
      FocusScope.of(context).unfocus();
      return;
    }

    // 必须选择收纳位置
    if (_selectedLocation == null) {
      _showToast('请选择收纳位置');
      FocusScope.of(context).unfocus();
      return;
    }

    // 照片路径（仅取成功状态的）
    final photoPaths = _photos
        .where((p) => p.status == PhotoStatus.success)
        .map((p) => p.path)
        .toList();

    final node = _selectedLocationNode;
    final bool saving = _isEdit;

    if (saving) {
      // 编辑模式：全量更新
      final existing = _itemById(widget.itemId!);
      if (existing == null) {
        // 物品已被别处删除（如另一个页面里删掉后返回），别默默写回一条脏数据
        _showToast('这件物品已不存在，无法保存');
        return;
      }
      final item = Item(
        id: existing.id,
        name: name,
        location: _selectedLocation ?? '未知',
        status: existing.status,
        categoryKey: _selectedCategoryKey ?? '',
        roomId: node?.roomId,
        cabinetId: node?.cabinetId,
        slotId: node?.isSlot == true ? node?.id : null,
        photos: photoPaths,
        expiryDate: _expiryDate,
        note: _noteController.text.trim(),
        createdAt: existing.createdAt,
      );
      await ref.read(itemsProvider.notifier).updateItem(item);

      // 清理被删除的旧照片文件
      final removedFiles = _originalPhotos
          .where((p) => !photoPaths.contains(p))
          .toList();
      for (final f in removedFiles) {
        PhotoService.instance.deleteFile(f);
      }

      _successTitle = '保存成功！';
      _successSub = '「$name」的信息已更新';
      _successBtnText = '好的';
      _successBtnAction = () {
        if (mounted) {
          setState(() => _showSuccess = false);
          Navigator.of(context).pop();
        }
      };
    } else {
      // 新增模式
      final item = Item.create(
        name: name,
        location: _selectedLocation ?? '未知',
        status: 'safe',
        categoryKey: _selectedCategoryKey ?? '',
        roomId: node?.roomId,
        cabinetId: node?.cabinetId,
        slotId: node?.isSlot == true ? node?.id : null,
        photos: photoPaths,
        expiryDate: _expiryDate,
        note: _noteController.text.trim(),
      );

      await ref.read(itemsProvider.notifier).addItem(item);

      if (andContinue) {
        _successTitle = '已保存！';
        _successSub = '「$name」已入库，继续添加下一件吧';
        _successBtnText = '继续新增';
        _successBtnAction = () {
          setState(() => _showSuccess = false);
          _resetForm();
        };
      } else {
        _successTitle = '保存成功！';
        _successSub = '「$name」已添加到你的物品库';
        _successBtnText = '好的';
        _successBtnAction = () {
          if (mounted) {
            setState(() => _showSuccess = false);
            Navigator.of(context).pop();
          }
        };
      }
    }

    if (mounted) setState(() => _showSuccess = true);
  }

  void _resetForm() {
    _nameController.clear();
    _noteController.clear();

    setState(() {
      _selectedCategory = null;
      _selectedCategoryKey = null;
      _selectedLocation = null;
      _selectedLocationNode = null;
      _photos.clear();
      // 到期日清空；登记时间按「下一件的登记时刻」重新取系统时间
      _expiryDate = null;
      _registeredAt = DateTime.now();
      _syncDateFields();
    });
    _scrollController.jumpTo(0);
    _showToast('表单已重置，继续添加 💪');
  }

  // ==================== Build ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 透明：透出全局那一层背景（S1~S5 共用同一片）
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: Stack(
          children: [
            // 主内容：滚动区 + 固定底部的悬浮操作条
            Column(
              children: [
                // 状态栏占位
                SizedBox(height: MediaQuery.of(context).padding.top),
                // 滚动区域
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 8),
                        _buildPhotoSection(),
                        const SizedBox(height: 16),
                        _buildBasicInfoSection(),
                        const SizedBox(height: 12),
                        _buildCategoryLocationSection(),
                        // 操作条已不悬浮在内容之上，只留一点收尾留白
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
            // 成功弹窗
            if (_showSuccess) Positioned.fill(child: _buildSuccessOverlay()),
          ],
        ),
      ),
    );
  }

  // ==================== 顶部导航 ====================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
          Text(
            _isEdit ? '编辑物品' : '新增物品',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 照片区域 ====================
  Widget _buildPhotoSection() {
    final canAddMore = _photos.length < PhotoService.maxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 14,
              color: AppColors.coralDeep,
            ),
            const SizedBox(width: 6),
            Text(
              '物品照片 · ${_photos.length}/${PhotoService.maxPhotos}（JPG/PNG，≤5MB）',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length + (canAddMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == _photos.length) {
                // 添加按钮
                return GestureDetector(
                  onTap: _isPicking ? null : _showPhotoSourceSheet,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.border,
                        width: 2.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: _isPicking
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.coral,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 28,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '添加照片',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              }
              // 照片缩略图
              final photo = _photos[index];
              return _PhotoThumb(
                entry: photo,
                isCover: index == 0,
                onRemove: () => _removePhoto(index),
                onRetry: photo.status == PhotoStatus.failed
                    ? () => _retryPhoto(index)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== 基本信息 ====================
  Widget _buildBasicInfoSection() {
    return _FormCard(
      icon: Icons.edit,
      title: '基本信息',
      children: [
        // 物品名称
        _buildLabel('物品名称', required: true),
        const SizedBox(height: 6),
        _buildInput(
          controller: _nameController,
          placeholder: '例如：AirPods Pro 2',
        ),
        const SizedBox(height: 14),
        // 到期日（可选，用于食品/药品/耗材等有保质期的东西）
        _buildLabel('到期日'),
        const SizedBox(height: 6),
        _buildInput(
          controller: _expiryController,
          placeholder: '点击选择日期（可不填）',
          readOnly: true,
          onTap: _pickExpiryDate,
          fontSize: 15,
          suffix: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_expiryDate != null)
                GestureDetector(
                  onTap: _clearExpiryDate,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 登记时间（自动按系统时间录入，不可编辑）
        _buildLabel('登记时间'),
        const SizedBox(height: 6),
        _buildInput(
          controller: _registeredController,
          placeholder: '自动记录',
          readOnly: true,
          fontSize: 15,
          suffix: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.schedule,
              size: 16,
              color: AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 归属信息 ====================
  Widget _buildCategoryLocationSection() {
    return _FormCard(
      icon: Icons.inventory_2_outlined,
      title: '归属信息',
      children: [
        Row(
          children: [
            // 物品分类
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('物品分类', required: true),
                  const SizedBox(height: 6),
                  _buildSelectTrigger(
                    text: _selectedCategory ?? '选择分类',
                    hasValue: _selectedCategory != null,
                    onTap: _openCategoryPicker,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // 收纳位置
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('收纳位置', required: true),
                  const SizedBox(height: 6),
                  _buildSelectTrigger(
                    text: _selectedLocation ?? '选择位置',
                    hasValue: _selectedLocation != null,
                    onTap: _openLocationPicker,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // 备注
        _buildLabel('备注'),
        const SizedBox(height: 6),
        _buildInput(
          controller: _noteController,
          placeholder: '记录一些补充信息…',
          maxLines: 4,
        ),
      ],
    );
  }

  // ==================== 底部操作条 ====================
  /// V2.6：与底部导航同一套悬浮圆角白条语言（不是满宽贴底渐变条），
  /// 条内托 40pt 胶囊按钮——保存入库/保存修改（主按钮）+ 保存并继续新增（次要）。
  Widget _buildBottomActions() {
    return FloatingBar(
      background: AppColors.actionBarBg,
      child: Row(
        children: [
          Expanded(
            child: FloatingBarButton(
              label: _isEdit ? '保存修改' : '保存入库',
              tone: FloatingBarTone.primary,
              onTap: () => _saveItem(false),
            ),
          ),
          // 新增模式才显示“保存并继续新增”
          if (!_isEdit) ...[
            const SizedBox(width: 10),
            Expanded(
              child: FloatingBarButton(
                label: '保存并继续新增',
                tone: FloatingBarTone.ghost,
                onTap: () => _saveItem(true),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== 成功弹窗 ====================
  Widget _buildSuccessOverlay() {
    return Container(
      color: AppColors.background.withValues(alpha: 0.96),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 成功图标
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.successLight, AppColors.success],
                ),
              ),
              child: const Icon(Icons.check, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              _successTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _successSub,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _successBtnAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  // 主按钮 = 实心珊瑚（稿子 `.btn.primary` 无渐变）
                  color: AppColors.btnPrimaryBg,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.btnPrimaryShadow,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _successBtnText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.btnPrimaryFg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 通用组件 ====================
  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        if (required)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              '*',
              style: TextStyle(fontSize: 10, color: AppColors.danger),
            ),
          ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
    double fontSize = 16,
    EdgeInsets? padding,
    Widget? suffix,
  }) {
    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: fontSize, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: fontSize),
            contentPadding:
                padding ??
                //const EdgeInsets.fromLTRB(14, 11, 4, 11),
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: InputBorder.none,
            suffixIcon: suffix,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectTrigger({
    required String text,
    required bool hasValue,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.border.withValues(alpha: 0.3)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled
                ? AppColors.border.withValues(alpha: 0.5)
                : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: disabled
                      ? AppColors.textSecondary
                      : (hasValue ? AppColors.textPrimary : AppColors.textHint),
                ),
              ),
            ),
            Icon(
              disabled ? Icons.lock_outline : Icons.expand_more,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 表单卡片容器 ====================
class _FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _FormCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.coralDeep),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ==================== 选择器底部弹窗 ====================
class _PickerSheet extends StatelessWidget {
  final String title;
  final List<PickerItem> items;
  final String? selectedName;
  final ValueChanged<String> onPick;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selectedName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 14, color: AppColors.textHint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4列网格
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.name == selectedName;
                return GestureDetector(
                  onTap: () => onPick(item.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.coralSoft
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.coral : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EmojiText(emoji: item.emoji, fontSize: 24),
                        const SizedBox(height: 6),
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.coralDeep
                                : AppColors.textSecondary,
                          ),
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

// ==================== 收纳位置选择弹窗 ====================
class _LocationPickerSheet extends StatelessWidget {
  final List<StorageLocationNode> nodes;
  final bool isLoading;
  final StorageLocationNode? selectedNode;
  final ValueChanged<StorageLocationNode> onPick;
  final VoidCallback onClear;

  const _LocationPickerSheet({
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
          // 顶部把手
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
          // 标题行
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择收纳位置',
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
                  tooltip: '清除选择',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // 列表
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
                        '暂无可用收纳位置\n请先在收纳页面添加房间',
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
                      final isSelected =
                          selectedNode?.id == node.id &&
                          selectedNode?.isSlot == node.isSlot &&
                          selectedNode?.isRoom == node.isRoom;
                      return _LocationTile(
                        node: node,
                        isSelected: isSelected,
                        onTap: () => onPick(node),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final StorageLocationNode node;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationTile({
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.coralSoft : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.coral : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // 层级图标（房间绿 / 柜体黄 / 格子蓝）
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
              child: Center(child: EmojiText(emoji: node.emoji, fontSize: 18)),
            ),
            const SizedBox(width: 12),
            // 路径信息
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
            // 选中标记
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
  }
}

// ==================== 照片缩略图组件 ====================
class _PhotoThumb extends StatelessWidget {
  final PhotoEntry entry;
  final bool isCover;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;

  const _PhotoThumb({
    required this.entry,
    required this.isCover,
    required this.onRemove,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final failed = entry.status == PhotoStatus.failed;
    final uploading = entry.status == PhotoStatus.uploading;
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 图片
          PhotoImage(
            source: entry.path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.border,
              child: const Icon(Icons.broken_image, color: AppColors.textHint),
            ),
          ),
          // 上传中遮罩
          if (uploading)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // 失败遮罩
          if (failed)
            GestureDetector(
              onTap: onRetry,
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 22),
                    SizedBox(height: 2),
                    Text(
                      '点击重试',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 删除按钮
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
          // 封面标签
          if (isCover)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: const BoxDecoration(
                  color: AppColors.btnPrimaryBg,
                ),
                child: const Text(
                  '封面',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.btnPrimaryFg,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
