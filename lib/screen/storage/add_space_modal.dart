import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../widgets/toast_utils.dart';
import '../../widgets/app_dropdown_button.dart';
import '../../widgets/emoji_picker_field.dart';
import '../../widgets/photo_image.dart';
import 'package:jia_cang/widgets/center_sheet.dart';
import '../../providers/storage_providers.dart';
import '../../services/photo_service.dart';

/// 数据回调：用户在新增模态框点击确认时触发，返回写入完成后的 Future。
///
/// 必须等待写入真正结束再关闭弹窗：写入失败（数据库连接异常等）时
/// 用户能看到失败原因，而不是「点了确认却什么都没发生」。
typedef AddSpaceCallback =
    Future<void> Function({
      required String level,
      required String parentId,
      required String name,
      required String icon,
      String? photoPath,
    });

/// 新增收纳空间模态框
class AddSpaceModal extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final AddSpaceCallback onConfirm;

  /// 当前浏览层级，用于默认选中
  final int currentLevel;
  final String? currentRoomId;
  final String? currentCabinetId;

  const AddSpaceModal({
    super.key,
    required this.onClose,
    required this.onConfirm,
    this.currentLevel = 0,
    this.currentRoomId,
    this.currentCabinetId,
  });

  @override
  ConsumerState<AddSpaceModal> createState() => _AddSpaceModalState();
}

class _AddSpaceModalState extends ConsumerState<AddSpaceModal> {
  late String _addLevel;
  late String _parentId; // 实际 ID（room id 或 cabinet id）
  String _addName = '';
  String _selectedIcon = '🛋️';
  // slot 级别专用：用户选择的房间 ID（用于级联筛选柜体）
  // 初始为 currentRoomId，若为空则等房间列表加载后取第一个
  String? _slotParentRoomId;

  // 实景图（仅 cabinet 层级）：单张草稿，保存前为本地文件路径
  PhotoEntry? _photo;
  bool _isPicking = false;
  bool _saved = false; // 用于 dispose 时判断是否清理草稿文件
  bool _submitting = false; // 确认添加进行中，避免重复点击 / 让用户看到反馈

  @override
  void initState() {
    super.initState();
    // 根据当前浏览层级自动设置默认值
    if (widget.currentLevel == 2 && widget.currentCabinetId != null) {
      _addLevel = 'slot';
      _parentId = widget.currentCabinetId!;
      _slotParentRoomId = widget.currentRoomId;
    } else if (widget.currentLevel == 1 && widget.currentRoomId != null) {
      _addLevel = 'cabinet';
      _parentId = widget.currentRoomId!;
    } else {
      _addLevel = 'room';
      _parentId = '';
    }

  }

  @override
  void dispose() {
    // 未保存就关闭模态：清理草稿照片文件，避免孤儿文件
    if (!_saved && _photo != null) {
      PhotoService.instance.deleteFile(_photo!.path);
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) return;
    if (_addName.isEmpty) {
      ToastUtils.show(context, '请填写名称');
      return;
    }
    if (_addLevel != 'room' && _parentId.isEmpty) {
      ToastUtils.show(context, '请选择上级空间');
      return;
    }
    setState(() => _submitting = true);
    _saved = true; // 标记已保存，dispose 时不再清理草稿照片
    try {
      await widget.onConfirm(
        level: _addLevel,
        parentId: _parentId,
        name: _addName,
        icon: _selectedIcon,
        photoPath: _addLevel == 'cabinet' ? _photo?.path : null,
      );
    } finally {
      // 成功时调用方会先关掉本弹窗，此时 mounted 已为 false，无需再 setState
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CenterModalShell(
      onDismiss: widget.onClose,
      maxHeight: 720,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '新增收纳空间',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onClose,
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
                      const SizedBox(height: 18),
                      // 所属层级
                      _buildFormRow('所属层级', _buildLevelSelect()),
                      // 上级空间（仅非 room 级别时显示）
                      if (_addLevel != 'room')
                        _buildFormRow('上级空间', _buildDynamicParentSelect()),
                      // 空间名称
                      _buildFormRow('空间名称', _buildNameInput(), required: true),
                      // 选择图标
                      _buildFormRow('选择图标', _buildIconGrid()),
                      // 上传实景图（仅 cabinet 级别）
                      if (_addLevel == 'cabinet')
                        _buildFormRow('上传实景图', _buildPhotoUpload()),
                      const SizedBox(height: 6),
                      // 确认按钮
                      GestureDetector(
                        onTap: _submitting ? null : _save,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            // 主按钮 = 实心珊瑚（稿子 `.btn.primary` 无渐变）
                            color: AppColors.btnPrimaryBg,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.btnPrimaryShadow,
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _submitting
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.btnPrimaryFg,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '添加中…',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.btnPrimaryFg,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    '确认添加',
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

  Widget _buildFormRow(String label, Widget child, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(fontSize: 10, color: AppColors.danger),
                ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildLevelSelect() {
    return AppDropdownButton<String>(
      value: _addLevel,
      items: const [
        DropdownOption('room', '房间'),
        DropdownOption('cabinet', '柜体'),
        DropdownOption('slot', '格子/区域'),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          // 离开柜体层级时清理草稿实景图（实景图仅 cabinet 层级开放）
          if (_addLevel == 'cabinet' && v != 'cabinet' && _photo != null) {
            PhotoService.instance.deleteFile(_photo!.path);
            _photo = null;
          }
          _addLevel = v;
          // 切换层级时重置父级选择
          if (_addLevel == 'room') {
            _parentId = '';
            _slotParentRoomId = null;
          } else if (_addLevel == 'cabinet') {
            _parentId = widget.currentRoomId ?? '';
            _slotParentRoomId = null;
          } else {
            // slot：以当前浏览房间为默认，后续用户可改
            _slotParentRoomId = widget.currentRoomId;
            _parentId = widget.currentCabinetId ?? '';
          }
        });
      },
    );
  }

  /// 动态父级选择器 — 从 providers 读取房间/柜体数据
  Widget _buildDynamicParentSelect() {
    if (_addLevel == 'cabinet') {
      // 选择房间作为柜体的上级
      final roomsAsync = ref.watch(roomsProvider);
      return roomsAsync.when(
        loading: () => _buildLoadingSelect(),
        error: (e, _) => _buildErrorSelect(),
        data: (rooms) {
          if (rooms.isEmpty) {
            return _buildEmptyHint('请先添加房间');
          }
          // 确保当前 parentId 在列表中
          final validId = rooms.any((r) => r.id == _parentId)
              ? _parentId
              : rooms.first.id;
          if (validId != _parentId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _parentId = validId);
            });
          }
          return _buildSelectFromList(
            items: rooms
                .map((r) => (id: r.id, label: '${r.emoji} ${r.name}'))
                .toList(),
            selectedId: validId,
            onChanged: (id) => setState(() => _parentId = id),
          );
        },
      );
    } else if (_addLevel == 'slot') {
      // 选择柜体作为格子的上级：级联「房间 → 柜体」
      // 用户可跨房间选择任意柜体作为父级
      return _buildSlotParentCascade();
    }
    return const SizedBox.shrink();
  }

  /// slot 级别的级联父级选择器：先选房间，再选该房间下的柜体。
  Widget _buildSlotParentCascade() {
    final roomsAsync = ref.watch(roomsProvider);
    return roomsAsync.when(
      loading: () => _buildLoadingSelect(),
      error: (e, _) => _buildErrorSelect(),
      data: (rooms) {
        if (rooms.isEmpty) {
          return _buildEmptyHint('请先添加房间');
        }
        // 初始化或校验所选房间
        var selectedRoom = _slotParentRoomId;
        if (selectedRoom == null || !rooms.any((r) => r.id == selectedRoom)) {
          selectedRoom = rooms.first.id;
          if (_slotParentRoomId != selectedRoom) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _slotParentRoomId = selectedRoom;
                _parentId = ''; // 房间变了，柜体待重选
              });
            });
          }
        }
        return _buildRoomCabinetCascade(
          rooms: rooms,
          selectedRoomId: selectedRoom,
        );
      },
    );
  }

  /// 渲染房间 + 柜体两个级联下拉，已选项带明确视觉标识。
  Widget _buildRoomCabinetCascade({
    required List<dynamic> rooms,
    required String selectedRoomId,
  }) {
    final cabinetsAsync = ref.watch(cabinetsByRoomProvider(selectedRoomId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 第一级：房间
        _buildLabeledSelect(
          label: '所在房间',
          items: rooms
              .map((r) => (id: r.id as String, label: '${r.emoji} ${r.name}'))
              .toList(),
          selectedId: selectedRoomId,
          onChanged: (id) {
            setState(() {
              _slotParentRoomId = id;
              _parentId = ''; // 重置柜体选择
            });
          },
        ),
        const SizedBox(height: 10),
        // 第二级：柜体（依赖所选房间）
        cabinetsAsync.when(
          loading: () => _buildLoadingSelect(),
          error: (e, _) => _buildErrorSelect(),
          data: (cabinets) {
            if (cabinets.isEmpty) {
              return _buildEmptyHint('该房间暂无柜体，请先添加');
            }
            final validId = cabinets.any((c) => c.id == _parentId)
                ? _parentId
                : cabinets.first.id;
            if (validId != _parentId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _parentId = validId);
              });
            }
            return _buildLabeledSelect(
              label: '所属柜体',
              items: cabinets
                  .map((c) => (id: c.id, label: '${c.emoji} ${c.name}'))
                  .toList(),
              selectedId: validId,
              onChanged: (id) => setState(() => _parentId = id),
              highlight: true, // 最终父级高亮标识
            );
          },
        ),
      ],
    );
  }

  /// 带小标题的下拉选择器，[highlight] 为 true 时给选中项加金色边框。
  Widget _buildLabeledSelect({
    required String label,
    required List<({String id, String label})> items,
    required String selectedId,
    required ValueChanged<String> onChanged,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: highlight
                    ? AppColors.coralDeep
                    : AppColors.textSecondary,
              ),
            ),
            if (highlight)
              const Text(
                ' · 已选定',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.coralDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        _buildSelectFromList(
          items: items,
          selectedId: selectedId,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSelectFromList({
    required List<({String id, String label})> items,
    required String selectedId,
    required ValueChanged<String> onChanged,
  }) {
    return AppDropdownButton<String>(
      value: selectedId,
      items: items
          .map((item) => DropdownOption<String>(item.id, item.label))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _buildLoadingSelect() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorSelect() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '加载失败',
        style: TextStyle(color: AppColors.danger, fontSize: 13),
      ),
    );
  }

  Widget _buildEmptyHint(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hint,
        style: const TextStyle(color: AppColors.textHint, fontSize: 13),
      ),
    );
  }

  Widget _buildNameInput() {
    return TextField(
      decoration: InputDecoration(
        hintText: _addLevel == 'room'
            ? '例如：客厅、卧室'
            : _addLevel == 'cabinet'
            ? '例如：电视柜、衣柜'
            : '例如：上层隔板、抽屉',
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
      ),
      onChanged: (v) => _addName = v,
    );
  }

  Widget _buildIconGrid() {
    return EmojiPickerField(
      value: _selectedIcon,
      options: kSpaceEmojiOptions,
      onChanged: (v) => setState(() => _selectedIcon = v),
    );
  }

  Widget _buildPhotoUpload() {
    // 选图中：显示进度指示
    if (_isPicking) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.coral,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '正在处理照片…',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 已选：显示预览图 + 删除按钮
    if (_photo != null) {
      return GestureDetector(
        onTap: () => ToastUtils.show(context, '仅支持上传一张实景图，请先删除后重新选择'),
        child: Container(
          height: 150,
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
              PhotoImage(
                source: _photo!.path,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.border,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.textHint,
                      size: 30,
                    ),
                  ),
                ),
              ),
              // 底部渐变提示条
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x66000000)],
                    ),
                  ),
                  child: const Text(
                    '点击图片可删除后重传',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // 删除按钮
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removePhoto,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 空态：上传按钮
    return GestureDetector(
      onTap: _isPicking ? null : _showPhotoSourceSheet,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 26,
              color: AppColors.textHint,
            ),
            SizedBox(height: 6),
            Text(
              '点击上传空间照片',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '支持 JPG / PNG，单张 ≤ 5MB',
              style: TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  /// 照片来源选择（相册 / 拍照 / 取消）
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
                _pickFromGallery();
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
                _pickFromCamera();
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

  Future<void> _pickFromGallery() async {
    if (_isPicking) return;
    if (_photo != null) {
      ToastUtils.show(context, '仅支持上传一张实景图，请先删除后重新选择');
      return;
    }
    setState(() => _isPicking = true);
    final result = await PhotoService.instance.pickFromGallery(remaining: 1);
    if (!mounted) return;
    setState(() {
      if (result.entries.isNotEmpty) {
        _photo = result.entries.first;
      }
      _isPicking = false;
    });
    if (result.error != null) {
      ToastUtils.show(context, result.error!);
    } else if (result.entries.isNotEmpty) {
      ToastUtils.show(context, '实景图已添加');
    }
  }

  Future<void> _pickFromCamera() async {
    if (_isPicking) return;
    if (_photo != null) {
      ToastUtils.show(context, '仅支持上传一张实景图，请先删除后重新选择');
      return;
    }
    setState(() => _isPicking = true);
    final result = await PhotoService.instance.pickFromCamera();
    if (!mounted) return;
    setState(() {
      if (result.entries.isNotEmpty) {
        _photo = result.entries.first;
      }
      _isPicking = false;
    });
    if (result.error != null) {
      ToastUtils.show(context, result.error!);
    } else if (result.entries.isNotEmpty) {
      ToastUtils.show(context, '实景图已添加');
    }
  }

  void _removePhoto() {
    final removed = _photo;
    setState(() => _photo = null);
    // 草稿照片（未入库）直接删除文件
    if (removed != null) {
      PhotoService.instance.deleteFile(removed.path);
      ToastUtils.show(context, '已删除，可重新上传');
    }
  }
}

