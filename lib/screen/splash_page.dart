import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/app_text_styles.dart';
import 'package:jia_cang/constants/app_shadows.dart';
import 'package:jia_cang/widgets/gradient_background.dart';
import 'package:jia_cang/services/first_run_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _progress = 0.0;
  bool _isFading = false;
  bool _disposed = false;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _startTimer = Timer(const Duration(milliseconds: 600), () {
      if (!_disposed) _runProgress();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _startTimer?.cancel();
    super.dispose();
  }

  void _runProgress() {
    final start = DateTime.now().millisecondsSinceEpoch;
    const total = 2000;

    void update() {
      if (_disposed) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - start;
      final raw = (elapsed / total).clamp(0.0, 1.0);

      if (mounted) {
        setState(() {
          _progress = raw;
        });
      }

      if (raw < 1.0) {
        Future.delayed(const Duration(milliseconds: 16), update);
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_disposed) return;
          if (mounted) {
            setState(() {
              _isFading = true;
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_disposed) return;
              if (mounted) {
                FirstRunService.markCompleted();
                context.go('/home');
              }
            });
          }
        });
      }
    }

    update();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _isFading ? 0.0 : 1.0,
        child: GradientBackground(
          // 不再传 colors：走 V2.6 统一背景（暖粉白底 + 右上角暖光晕）
          child: Column(
            children: [
              // 中部弹性区：logo 组（logo/标题/副标题/装饰线）整体落在屏幕正中
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 32),
                      _buildTitle(),
                      const SizedBox(height: 10),
                      _buildSubtitle(),
                      const SizedBox(height: 20),
                      _buildLine(),
                    ],
                  ),
                ),
              ),
              // 进度条固定在底部，不挤占 logo 组的居中位置
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 48, bottom: 56),
                child: _buildProgress(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0.3, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(52),
              boxShadow: AppShadows.logo,
            ),
            // 2026-09-17 品牌升级：应用图标改为真实 logo 资产
            //（assets/icon/jia_cang_icon_1024.png，与桌面/安装图标同源）
            child: ClipRRect(
              borderRadius: BorderRadius.circular(52),
              child: Image.asset(
                'assets/icon/jia_cang_icon_1024.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 650),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: Text('家藏', style: AppTextStyles.splashTitle),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: Text('记录每个物品的故事', style: AppTextStyles.splashSubtitle),
          ),
        );
      },
    );
  }

  Widget _buildLine() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scaleX: value,
            alignment: Alignment.centerLeft,
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: AppColors.coral,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.shadowPrimary,
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: AppColors.coral,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: _progress > 0 ? 1.0 : 0.0,
            child: Text(
              '${(_progress * 100).round()}%',
              style: AppTextStyles.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
