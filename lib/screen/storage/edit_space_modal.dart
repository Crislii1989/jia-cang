import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/center_sheet.dart';
import '../../widgets/emoji_picker_field.dart';
import '../../widgets/toast_utils.dart';

/// 编辑回调：用户点击确认时触发，传入新的名称和图标
typedef EditSpaceCallback =
    void Function({required String name, required String icon});

/// 编辑收纳空间模态框（房间/柜体/格子通用，仅编辑名称和图标）
class EditSpaceModal extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialIcon;
  final VoidCallback onClose;
  final EditSpaceCallback onConfirm;

  const EditSpaceModal({
    super.key,
    required this.title,
    required this.initialName,
    required this.initialIcon,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  State<EditSpaceModal> createState() => _EditSpaceModalState();
}

class _EditSpaceModalState extends State<EditSpaceModal> {
  late TextEditingController _nameController;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedIcon = widget.initialIcon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ToastUtils.show(context, '请填写名称');
      return;
    }
    widget.onConfirm(
      name: name,
      icon: _selectedIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 统一走 CenterModalShell：居中 + 四角圆角，避免各弹窗各写一套定位/圆角。
    return CenterModalShell(
      onDismiss: widget.onClose,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
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
                      // 名称输入
                      const Text(
                        '名称',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.coral,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 图标选择
                      const Text(
                        '图标',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      EmojiPickerField(
                        value: _selectedIcon,
                        options: kSpaceEmojiOptions,
                        onChanged: (v) => setState(() => _selectedIcon = v),
                      ),
                      const SizedBox(height: 20),
                      // 确认按钮
                      GestureDetector(
                        onTap: _save,
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
                          child: const Center(
                            child: Text(
                              '保存',
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

}
