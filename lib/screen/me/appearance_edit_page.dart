import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_skin.dart';
import '../../constants/design_metrics.dart';
import '../../providers/skin_provider.dart';
import '../../widgets/color_picker_sheet.dart';
import '../../widgets/floating_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/section_title.dart';
import '../../widgets/skin_preview.dart';
import '../../widgets/toast_utils.dart';
import 'appearance_top_bar.dart';

/// 新建 / 编辑一套配色（皮肤）时传入的参数。
class AppearanceEditArgs {
  /// 编辑对象：新建时是以当前皮肤为起点的草稿（见 [AppSkins.draftFrom]）
  final AppSkin skin;

  /// true = 新建（保存后立即应用）；false = 编辑已有的一套
  final bool isNew;

  const AppearanceEditArgs({required this.skin, required this.isNew});
}

/// 光晕的固定透明度：不透明的一大团暖色糊在右上角太抢眼，
/// 默认皮肤的 0x85 ≈ 52%，这里沿用。
const double _kGlowAlpha = 0.52;

/// 一个可编辑的锚点色槽。
class _Slot {
  final String label;
  final String hint;
  final Color Function(AppSkin) read;
  final AppSkin Function(AppSkin, Color) write;

  const _Slot(this.label, this.hint, this.read, this.write);
}

/// 7 个锚点色。顺序 = 界面上的顺序（从「最影响观感」到「最细节」）。
final List<_Slot> _slots = [
  _Slot(
    '主色',
    '按钮、选中态、强调文字',
    (s) => s.primary,
    (s, c) => s.copyWith(primary: c),
  ),
  _Slot('页面底色', '整页背景', (s) => s.bg, (s, c) => s.copyWith(bg: c)),
  _Slot('卡片底色', '白卡与悬浮条', (s) => s.cardBg, (s, c) => s.copyWith(cardBg: c)),
  _Slot('主文字', '标题与正文', (s) => s.ink, (s, c) => s.copyWith(ink: c)),
  _Slot('次文字', '说明、占位与日期', (s) => s.ink2, (s, c) => s.copyWith(ink2: c)),
  _Slot('分割线', '描边与行间细线', (s) => s.line, (s, c) => s.copyWith(line: c)),
  _Slot(
    '光晕',
    '右上角暖光（自动半透明）',
    (s) => s.glow,
    (s, c) => s.copyWith(glow: c.withValues(alpha: _kGlowAlpha)),
  ),
];

/// 新建 / 编辑配色页。
///
/// 交互：改任何一个颜色槽都会**实时刷新页内预览**（预览不读全局 [AppColors]，
/// 只读本页草稿，见 [SkinPreview]）；点「保存」才写入并全局生效。
class AppearanceEditPage extends ConsumerStatefulWidget {
  final AppearanceEditArgs args;

  const AppearanceEditPage({super.key, required this.args});

  @override
  ConsumerState<AppearanceEditPage> createState() => _AppearanceEditPageState();
}

class _AppearanceEditPageState extends ConsumerState<AppearanceEditPage> {
  late AppSkin _skin;
  late final TextEditingController _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _skin = widget.args.skin;
    _name = TextEditingController(text: _skin.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// 主文字与页面底色太接近时给个提醒——不是硬校验（用户可能就是想要低对比），
  /// 只是别让他保存完才发现文字看不清。
  bool get _lowContrast =>
      (_skin.ink.computeLuminance() - _skin.bg.computeLuminance()).abs() < 0.35;

  @override
  Widget build(BuildContext context) {
    final k = DesignMetrics.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppearanceTopBar(
                title: widget.args.isNew ? '新建配色' : '编辑配色',
                subtitle: '改完点保存，全部页面一起换',
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(top: 4 * k, bottom: 16 * k),
                  children: [
                    _previewCard(k),
                    SizedBox(height: 20 * k),
                    SectionTitle(
                      title: '配色名称',
                      titleSize: 13 * k,
                      titleColor: AppColors.blushInk,
                    ),
                    SizedBox(height: 10 * k),
                    _nameField(k),
                    SizedBox(height: 20 * k),
                    SectionTitle(
                      title: '颜色',
                      titleSize: 13 * k,
                      titleColor: AppColors.blushInk,
                    ),
                    SizedBox(height: 10 * k),
                    _colorGroup(k),
                    if (_lowContrast) ...[
                      SizedBox(height: 10 * k),
                      _contrastWarning(k),
                    ],
                    SizedBox(height: 24 * k),
                  ],
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// 实时预览：卡片背景用草稿自己的底色，再叠一圈它自己的描边，
  /// 于是「底色 / 卡底 / 主色 / 文字 / 描边」一次性都能看到。
  ///
  /// 用「左图右文」而不是上图下文：7 个色槽才是这页的主角，竖排预览会把
  /// 它们全推到首屏之外，用户得先滚一段才摸得到颜色。
  Widget _previewCard(double k) {
    final name = _name.text.trim().isEmpty ? '未命名配色' : _name.text.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Container(
        padding: EdgeInsets.all(14 * k),
        decoration: BoxDecoration(
          color: _skin.bg,
          borderRadius: BorderRadius.circular(18 * k),
          border: Border.all(color: _skin.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.floatCardShadow,
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 108 * k,
              height: 144 * k,
              child: FittedBox(child: SkinPreview(skin: _skin)),
            ),
            SizedBox(width: 14 * k),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '预览',
                    style: TextStyle(fontSize: 10.5 * k, color: _skin.ink2),
                  ),
                  SizedBox(height: 5 * k),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5 * k,
                      fontWeight: FontWeight.w800,
                      color: _skin.ink,
                    ),
                  ),
                  SizedBox(height: 8 * k),
                  Text(
                    '改下面任一颜色，\n这里立刻跟着变。',
                    style: TextStyle(
                      fontSize: 10.5 * k,
                      height: 1.5,
                      color: _skin.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameField(double k) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: TextField(
        controller: _name,
        // 预览里的名字要跟着输入走
        onChanged: (_) => setState(() {}),
        maxLength: 12,
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) => null,
        style: TextStyle(
          fontSize: 13 * k,
          fontWeight: FontWeight.w600,
          color: AppColors.blushInk,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14 * k,
            vertical: 13 * k,
          ),
          filled: true,
          fillColor: AppColors.cardBg,
          hintText: '给这套配色起个名字',
          hintStyle: TextStyle(fontSize: 13 * k, color: AppColors.textHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * k),
            borderSide: BorderSide(color: AppColors.blushLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * k),
            borderSide: BorderSide(color: AppColors.blushLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * k),
            borderSide: BorderSide(color: AppColors.coral, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _colorGroup(double k) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14 * k),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.floatCardShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            for (int i = 0; i < _slots.length; i++) ...[
              if (i > 0) Container(height: 1, color: AppColors.cellDivider),
              _slotRow(_slots[i], k),
            ],
          ],
        ),
      ),
    );
  }

  Widget _slotRow(_Slot slot, double k) {
    final color = slot.read(_skin);
    return InkWell(
      onTap: () => _pick(slot),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12 * k, vertical: 11 * k),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.label,
                    style: TextStyle(
                      fontSize: 12.5 * k,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blushInk,
                    ),
                  ),
                  SizedBox(height: 2 * k),
                  Text(
                    slot.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5 * k,
                      color: AppColors.blushInk3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * k),
            Text(
              _hexOf(color),
              style: TextStyle(
                fontSize: 10.5 * k,
                letterSpacing: 0.3,
                color: AppColors.blushInk2,
              ),
            ),
            SizedBox(width: 10 * k),
            // 色块：底层垫卡片色，带透明度的光晕才看得出真实效果。
            // 描边要比分割线重一档——「页面底色」「卡片底色」这类浅色要是
            // 只描一圈极浅的线，在白卡上几乎看不出这里有个色块。
            Container(
              width: 34 * k,
              height: 24 * k,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8 * k),
                border: Border.all(
                  color: AppColors.blushInk3.withValues(alpha: 0.55),
                ),
              ),
              padding: EdgeInsets.all(2 * k),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6 * k),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contrastWarning(double k) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14 * k, color: AppColors.warning),
          SizedBox(width: 6 * k),
          Expanded(
            child: Text(
              '主文字和页面底色太接近，正文可能看不清',
              style: TextStyle(fontSize: 10.5 * k, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return FloatingBar(
      child: Row(
        children: [
          Expanded(
            child: FloatingBarButton(
              label: '取消',
              tone: FloatingBarTone.ghost,
              onTap: () => context.pop(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FloatingBarButton(
              label: _saving ? '保存中…' : (widget.args.isNew ? '保存并应用' : '保存'),
              tone: FloatingBarTone.primary,
              onTap: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  static String _hexOf(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Future<void> _pick(_Slot slot) async {
    final picked = await ColorPickerSheet.show(
      context: context,
      initial: slot.read(_skin).withValues(alpha: 1),
      title: '选择「${slot.label}」',
    );
    if (!mounted || picked == null) return;
    setState(() => _skin = slot.write(_skin, picked));
  }

  Future<void> _save() async {
    if (_saving) return;
    // 只挡连点，不用 setState：这一页马上就要离开了
    _saving = true;

    final name = _name.text.trim().isEmpty ? '我的配色' : _name.text.trim();
    final skin = _skin.copyWith(name: name);
    // 编辑的若正是当前这套，保存后要立刻生效；新建的自然也要。
    // 编辑的是「另一套」时不动当前配色，避免突然全应用换色。
    final activate = widget.args.isNew || AppColors.skin.id == skin.id;

    // ⚠️ 顺序不能改：**先提示 → 先离开本页 → 最后才落盘换肤**。
    // 换肤会让当前路由页面整体重新挂载（页面 key 带皮肤版本号，见
    // `app_router.dart` 的 `_skinKeyed`）。如果这时还停在编辑页，
    // 本页会被换成一个新元素：`context.pop()` 落在已失活的元素上会抛异常，
    // 而且用户回不到列表——表现为「点了保存，弹了提示，但页面没退」。
    // 反过来也不怕：Toast 挂在根 Overlay 上，换肤不影响它；
    // 而 saveCustom 只是写存储 + 改静态色值，不依赖任何 context。
    ToastUtils.show(context, activate ? '已保存并应用「$name」' : '已保存「$name」');
    context.pop();
    await ref
        .read(skinManagerProvider.notifier)
        .saveCustom(skin, activate: activate);
  }
}
