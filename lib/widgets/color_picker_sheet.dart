import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import 'center_sheet.dart';
import 'floating_bar.dart';

/// 颜色选择器（居中弹窗）。
///
/// **为什么不引第三方包**（flutter_colorpicker 等）：本项目在中文路径下，
/// `flutter pub get` 偶发建符号链接失败、`pub cache repair` 又会冲掉
/// sqlite3 的本地补丁；为一个只在一处用到的取色器引入外部依赖，
/// 风险与收益不成比例。这里用 [HSVColor]（Flutter 自带）+ 三条渐变滑块
/// 自绘，约 200 行，且配色与弹窗圆角语言完全统一。
///
/// 交互：
/// - 常用色一栏（一眼可点的整色）
/// - 色相 / 饱和度 / 明度三条滑块（想微调时用）
/// - 十六进制输入框（有设计稿给的色值时直接粘）
///
/// 返回：确认时返回选中的颜色（**不含透明度**，透明度由调用方决定）；
/// 取消 / 点遮罩返回 null。
class ColorPickerSheet {
  ColorPickerSheet._();

  /// 常用色：按「暖 → 冷 → 中性 → 浅底」排布，覆盖这套设计语言常用区间。
  static const List<Color> presets = [
    // 暖：珊瑚 / 橘 / 金
    Color(0xFFF2705B),
    Color(0xFFE8807F),
    Color(0xFFDD5B46),
    Color(0xFFF79C84),
    Color(0xFFE0764F),
    Color(0xFFD97B4F),
    Color(0xFFC07A4A),
    Color(0xFFB27E00),
    // 绿 / 青
    Color(0xFFE5A500),
    Color(0xFF6BA05C),
    Color(0xFF3E9B4F),
    Color(0xFF3FA98C),
    Color(0xFF4ECDC4),
    Color(0xFF7BC8B4),
    Color(0xFFA8D5B5),
    Color(0xFF2F7A6B),
    // 蓝 / 紫
    Color(0xFF5B8AC4),
    Color(0xFF3F7DC0),
    Color(0xFF4A7FB5),
    Color(0xFF8A6FD1),
    Color(0xFF7B5FC7),
    Color(0xFF9B7BFF),
    Color(0xFFC98A79),
    Color(0xFFD9534A),
    // 中性 / 深
    Color(0xFF4A3733),
    Color(0xFF6F5A52),
    Color(0xFF8B7355),
    Color(0xFF9A817B),
    Color(0xFFC3ABA4),
    Color(0xFFE2DAD4),
    Color(0xFF33404E),
    Color(0xFF000000),
  ];

  static Future<Color?> show({
    required BuildContext context,
    required Color initial,
    String title = '选择颜色',
  }) {
    return showCenterSheet<Color>(
      context: context,
      backgroundColor: AppColors.cardBg,
      builder: (ctx) => _ColorPickerBody(initial: initial, title: title),
    );
  }
}

class _ColorPickerBody extends StatefulWidget {
  final Color initial;
  final String title;

  const _ColorPickerBody({required this.initial, required this.title});

  @override
  State<_ColorPickerBody> createState() => _ColorPickerBodyState();
}

class _ColorPickerBodyState extends State<_ColorPickerBody> {
  late HSVColor _hsv;
  late final TextEditingController _hex;
  final _hexFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _hex = TextEditingController(text: _hexOf(widget.initial));
  }

  @override
  void dispose() {
    _hex.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  Color get _color => _hsv.toColor();

  static String _hexOf(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// 统一的取色入口。
  /// [fromHex] 为 true 时不动输入框（否则用户每敲一个字符光标就会被重置）。
  void _setColor(Color c, {bool fromHex = false}) {
    setState(() => _hsv = HSVColor.fromColor(c));
    if (!fromHex && _hex.text != _hexOf(c)) {
      _hex.text = _hexOf(c);
    }
  }

  void _onHexChanged(String raw) {
    var s = raw.replaceAll('#', '').trim();
    if (s.length == 3) {
      // #abc → #aabbcc
      s = s.split('').map((ch) => '$ch$ch').join();
    }
    if (s.length != 6) return;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return;
    _setColor(Color(0xFF000000 | v), fromHex: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    // 内边距必须自己给：showCenterSheet 只负责居中/圆角/遮罩，不垫 padding，
    // 内容直接贴边会被圆角切掉一角（标题顶部最先露馅）。
    // 再套一层滚动：小屏（或大字号）时内容可能超过弹窗最大高度。
    return CenterSheetSurface(
      color: AppColors.cardBg,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            // 当前颜色预览
            Row(
              children: [
                Container(
                  width: 52,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blushLine),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hex,
                    focusNode: _hexFocus,
                    onChanged: _onHexChanged,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[#0-9a-fA-F]'),
                      ),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: '#F2705B',
                      hintStyle: TextStyle(color: AppColors.textHint),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.blushLine),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.blushLine),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.coral,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 常用色
            _label('常用色'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in ColorPickerSheet.presets)
                  _swatch(p, selected: p.toARGB32() == c.toARGB32()),
              ],
            ),
            const SizedBox(height: 18),
            _label('微调'),
            const SizedBox(height: 8),
            _slider(
              label: '色相',
              t: _hsv.hue / 360,
              colors: const [
                Color(0xFFFF0000),
                Color(0xFFFFFF00),
                Color(0xFF00FF00),
                Color(0xFF00FFFF),
                Color(0xFF0000FF),
                Color(0xFFFF00FF),
                Color(0xFFFF0000),
              ],
              onChanged: (t) => _setColor(
                _hsv.withHue(t * 360).withSaturation(_hsv.saturation).toColor(),
              ),
            ),
            const SizedBox(height: 10),
            _slider(
              label: '浓淡',
              t: _hsv.saturation,
              colors: [
                HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
                HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
              ],
              onChanged: (t) => _setColor(_hsv.withSaturation(t).toColor()),
            ),
            const SizedBox(height: 10),
            _slider(
              label: '明暗',
              t: _hsv.value,
              colors: [
                HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 0).toColor(),
                HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 1).toColor(),
              ],
              onChanged: (t) => _setColor(_hsv.withValue(t).toColor()),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FloatingBarButton(
                    label: '取消',
                    tone: FloatingBarTone.ghost,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FloatingBarButton(
                    label: '确定',
                    tone: FloatingBarTone.primary,
                    onTap: () => Navigator.pop(context, _color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    ),
  );

  Widget _swatch(Color color, {required bool selected}) {
    return GestureDetector(
      onTap: () => _setColor(color),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: AppColors.coral, width: 2.5)
              : Border.all(color: AppColors.blushLine),
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }

  Widget _slider({
    required String label,
    required double t,
    required List<Color> colors,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ),
        Expanded(
          child: _GradientSlider(
            value: t.clamp(0.0, 1.0),
            colors: colors,
            colorAt: (tt) {
              // 滑块拇指取轨道当前处的颜色（轨道两色之间线性插值）
              if (colors.length < 2) return colors.first;
              final seg = 1 / (colors.length - 1);
              final i = (tt / seg).floor().clamp(0, colors.length - 2);
              final local = ((tt - i * seg) / seg).clamp(0.0, 1.0);
              return Color.lerp(colors[i], colors[i + 1], local) ?? colors[i];
            },
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// 渐变色轨道滑块（自绘：Material 的 Slider 无法让轨道显示渐变）。
class _GradientSlider extends StatelessWidget {
  final double value;
  final List<Color> colors;
  final Color Function(double t) colorAt;
  final ValueChanged<double> onChanged;

  static const double _trackHeight = 22;
  static const double _thumb = 22;

  const _GradientSlider({
    required this.value,
    required this.colors,
    required this.colorAt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final travel = width - _thumb;
        final left = (value * travel).clamp(0.0, travel);

        void handle(Offset local) {
          if (travel <= 0) return;
          final t = ((local.dx - _thumb / 2) / travel).clamp(0.0, 1.0);
          onChanged(t);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => handle(d.localPosition),
          onHorizontalDragStart: (d) => handle(d.localPosition),
          onHorizontalDragUpdate: (d) => handle(d.localPosition),
          child: SizedBox(
            height: _trackHeight + 8,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: _trackHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                    border: Border.all(color: AppColors.blushLine),
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
                Positioned(
                  left: left,
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: BoxDecoration(
                      color: colorAt(value),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowDark,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
