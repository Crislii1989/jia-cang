import 'package:flutter/material.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/widgets/center_sheet.dart';
import 'package:jia_cang/widgets/emoji_picker_field.dart';
import 'package:jia_cang/widgets/toast_utils.dart';

/// 编辑资料回调
typedef ProfileModalCallback =
    void Function({required String nickname, required String emoji});

/// 编辑头像/昵称模态框
class EditProfileModal extends StatefulWidget {
  final VoidCallback onClose;
  final ProfileModalCallback onConfirm;
  final String currentNickname;
  final String currentEmoji;

  const EditProfileModal({
    super.key,
    required this.onClose,
    required this.onConfirm,
    required this.currentNickname,
    required this.currentEmoji,
  });

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late String _nickname;
  late String _emoji;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _nickname = widget.currentNickname;
    _emoji = widget.currentEmoji;
    _controller = TextEditingController(text: _nickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_nickname.trim().isEmpty) {
      ToastUtils.show(context, '请填写昵称');
      return;
    }
    widget.onConfirm(nickname: _nickname.trim(), emoji: _emoji);
  }

  @override
  Widget build(BuildContext context) {
    return CenterModalShell(
      onDismiss: widget.onClose,
      maxHeight: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildEmojiGrid(),
            const SizedBox(height: 16),
            _buildNicknameInput(),
            const SizedBox(height: 20),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '编辑资料',
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
            child: Icon(Icons.close, size: 16, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择头像',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        EmojiPickerField(
          value: _emoji,
          options: kAvatarEmojiOptions,
          onChanged: (v) => setState(() => _emoji = v),
        ),
      ],
    );
  }

  Widget _buildNicknameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '昵称',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(fontSize: 10, color: AppColors.danger),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: '给自己起个名字吧',
            hintStyle: TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.coral,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
          ),
          onChanged: (v) => _nickname = v,
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _save,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          // 主按钮 = 实心珊瑚（稿子 `.btn.primary` 无渐变）
          color: AppColors.btnPrimaryBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.btnPrimaryShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '保存修改',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
