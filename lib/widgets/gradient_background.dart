import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 全局页面背景（高保真稿 V2.3/V2.6 定稿）。
///
/// **S1~S5 所有页面共用同一片**：只有一层——右上角一团柔和的暖橙光晕，
/// 下面是纯色暖粉白 [AppColors.blushBg]。背景铺在页面最外层，
/// 内容滚动时它固定不动。
///
/// [colors] 仅作兼容保留：显式传入时退回旧的「双色线性渐变」渲染方式
/// （当前没有任何调用方传它，全部走新的全局背景）。
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const GradientBackground({super.key, required this.child, this.colors});

  /// 光晕圆直径（CSS 里的椭圆光晕 ≈ 165% × 40% 机型宽；Flutter 的
  /// RadialGradient 是正圆，这里用一颗**大部分落在屏外右上角**的大圆近似，
  /// 视觉上就是「右上角一片化开的暖光」）
  static const double _glowSize = 460;

  @override
  Widget build(BuildContext context) {
    if (colors != null) {
      // 兼容旧调用：显式指定双色时仍走线性渐变
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors!,
          ),
        ),
        child: child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 纯色暖粉白底
        const ColoredBox(color: AppColors.blushBg),
        // 右上角光晕（唯一一层装饰）
        Positioned(
          top: -170,
          right: -120,
          child: Container(
            width: _glowSize,
            height: _glowSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.bgGlow, AppColors.glowFade],
                stops: [0.0, 0.72],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
