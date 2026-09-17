import 'package:flutter/material.dart';

import '../constants/app_skin.dart';

/// 皮肤预览缩略图：在**固定 120×160 的设计空间**里画一只迷你 App
/// （底色 + 右上光晕 + 一张卡片 + 主色按钮 + 一行正文），
/// 由调用方用 `SizedBox` + `FittedBox` 缩放到实际需要的尺寸。
///
/// 为什么固定设计空间 + 外部缩放，而不是按传入尺寸算比例：
/// 迷你 App 里的每个元素尺寸都必须是整数才不会出现 0.7px 的糊边，
/// 按比例算到处都是小数；固定一次画好、整体缩放，几何永远协调，
/// 调用方也只需要给一个框。
///
/// ⚠️ 这里**不读 [AppColors]**，只读传入的 [AppSkin]——它要能预览
/// 「还没保存、还没生效」的皮肤，所以绝不能走全局当前皮肤。
class SkinPreview extends StatelessWidget {
  final AppSkin skin;

  const SkinPreview({super.key, required this.skin});

  static const double designWidth = 120;
  static const double designHeight = 160;

  /// 光晕圆直径：真机 460 ÷ 320 视口宽 = 1.44 倍视口宽，这里等比
  static const double _glowSize = 172;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: designWidth,
      height: designHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: skin.bg),
            // 右上角光晕（唯一一层装饰，与真实页面同构）
            Positioned(
              top: -64,
              right: -45,
              child: Container(
                width: _glowSize,
                height: _glowSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [skin.glow, skin.glow.withValues(alpha: 0)],
                    stops: const [0.0, 0.72],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(skin.ink, w: 52, h: 7, r: 3.5),
                  const SizedBox(height: 6),
                  _bar(skin.ink2, w: 34, h: 5, r: 2.5),
                  const SizedBox(height: 11),
                  _card(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: skin.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _bar(skin.primary, w: 38, h: 7, r: 3.5),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _bar(skin.ink2, w: 62, h: 5, r: 2.5),
                      const SizedBox(height: 5),
                      _bar(
                        skin.ink2.withValues(alpha: 0.62),
                        w: 40,
                        h: 5,
                        r: 2.5,
                      ),
                      const SizedBox(height: 9),
                      // 主色实心按钮
                      Container(
                        height: 15,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: skin.primary,
                          borderRadius: BorderRadius.circular(7.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _card(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: skin.primary.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _bar(skin.ink2, w: 999, h: 5, r: 2.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bar(
    Color c, {
    required double w,
    required double h,
    double r = 3,
  }) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }

  /// 迷你卡片：卡片底色 + 描边（跟随皮肤）
  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: skin.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: skin.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// 小色板方块：页面底色底 + 主色圆点，用于列表行左侧。
/// 比一整张预览图省地方，又能一眼看出「这套配色长什么样」。
class SkinPaletteChip extends StatelessWidget {
  final AppSkin skin;
  final double size;

  const SkinPaletteChip({super.key, required this.skin, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.5;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: skin.bg,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: skin.line),
      ),
      alignment: Alignment.center,
      child: Container(
        width: dot,
        height: dot,
        decoration: BoxDecoration(
          color: skin.primary,
          shape: BoxShape.circle,
          // 主色圆点描一圈卡片底色：在白卡上像一颗嵌进去的扣子
          border: Border.all(color: skin.cardBg, width: size * 0.07),
        ),
      ),
    );
  }
}
