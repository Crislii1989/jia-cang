import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/widgets/center_sheet.dart';
import 'package:jia_cang/widgets/emoji_picker_field.dart';
import 'package:jia_cang/widgets/toast_utils.dart';

/// 分类名称最大字数（中文按字计，超出会截断/拦截）。
const int kCategoryNameMaxLength = 8;

/// 分类编辑回调
typedef CategoryModalCallback =
    void Function({required String label, required String emoji});

/// 新增/编辑分类模态框
class AddCategoryModal extends StatefulWidget {
  final VoidCallback onClose;
  final CategoryModalCallback onConfirm;

  /// 编辑模式：传入现有值
  final String? editLabel;
  final String? editEmoji;
  final String title;

  /// 现有分类名称（**不含**当前正在编辑的那一项）。
  /// 用于「禁止重名」校验：`选择分类`弹窗用「中文名 → id」反查，
  /// 一旦重名会命中错误的分类，因此必须在此拦掉。
  final List<String> otherLabels;

  const AddCategoryModal({
    super.key,
    required this.onClose,
    required this.onConfirm,
    this.editLabel,
    this.editEmoji,
    this.title = '新增分类',
    this.otherLabels = const [],
  });

  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  late String _label;
  late String _emoji;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _label = widget.editLabel ?? '';
    _emoji = widget.editEmoji ?? '📦';
    _controller = TextEditingController(text: _label);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _label.trim();
    if (name.isEmpty) {
      ToastUtils.show(context, '请填写分类名称');
      return;
    }
    if (name.runes.length > kCategoryNameMaxLength) {
      ToastUtils.show(context, '分类名称最多 $kCategoryNameMaxLength 个字');
      return;
    }
    // 禁止重名（不区分大小写）：重名会让「中文名 → id」反查命中错误的分类。
    final lower = name.toLowerCase();
    final duplicated =
        widget.otherLabels.any((l) => l.trim().toLowerCase() == lower);
    if (duplicated) {
      ToastUtils.show(context, '已存在同名分类');
      return;
    }
    widget.onConfirm(label: name, emoji: _emoji);
  }

  @override
  Widget build(BuildContext context) {
    // 统一走 CenterModalShell：居中 + 四角圆角。
    // 历史写法是 Positioned.fill + Align(bottomCenter) + 只圆上边角，
    // 于是「新增分类」会贴在屏幕底部、下面两个角是直角。
    return CenterModalShell(
      onDismiss: widget.onClose,
      maxHeight: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildEmojiGrid(),
            const SizedBox(height: 16),
            _buildLabelInput(),
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
          widget.title,
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
          '选择图标',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        EmojiPickerField(
          value: _emoji,
          options: kCategoryEmojiOptions,
          onChanged: (v) => setState(() => _emoji = v),
        ),
      ],
    );
  }

  Widget _buildLabelInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '分类名称',
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
          // 硬限制 8 字：超出直接截断，配合 _save 的字数校验双保险。
          inputFormatters: [
            LengthLimitingTextInputFormatter(kCategoryNameMaxLength),
          ],
          decoration: InputDecoration(
            hintText: '例如：美妆、户外、宠物',
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
          onChanged: (v) => _label = v,
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
        child: Center(
          child: Text(
            widget.editLabel != null ? '保存修改' : '确认添加',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.btnPrimaryFg,
            ),
          ),
        ),
      ),
    );
  }
}
