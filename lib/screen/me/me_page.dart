import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/design_metrics.dart';
import 'package:jia_cang/widgets/gradient_background.dart';
import 'package:jia_cang/widgets/toast_utils.dart';
import 'package:jia_cang/providers/profile_provider.dart';
import 'profile_header_section.dart';
import 'data_stats_section.dart';
import 'feature_menu_section.dart';
import 'edit_profile_modal.dart';

/// 「我的」页（高保真稿 S5，2026-09-16 按稿重排）。
///
/// 结构：顶部标题「我的」→ 资料卡 → 数据概览（2×2）→
/// 应用管理 / 设置 两组行式白卡。
///
/// 旧版页面自绘的三团圆形色斑已移除——全局背景**只有一层**右上角暖光晕
/// （[GradientBackground]，S1~S5 共用），各页不再私加装饰。
/// 右上角拍照（扫描识别）入口按用户要求隐藏，不再在本页显示。
class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {
  bool _showEditModal = false;

  @override
  Widget build(BuildContext context) {
    final k = DesignMetrics.of(context);

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            SafeArea(
              // 注意：横向边距由各 section 自带（与首页等其他页一致），
              // 这里只留垂直方向，避免双重边距把卡片挤窄
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
                children: [
                  // 顶部标题（稿子 .nav-top .ttl：17/800；拍照入口已按要求隐藏）
                  Text(
                    '我的',
                    style: TextStyle(
                      fontSize: 17 * k,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blushInk,
                    ),
                  ),
                  SizedBox(height: 14 * k),
                  ProfileHeaderSection(onEdit: _openEditModal),
                  SizedBox(height: 20 * k),
                  const DataStatsSection(),
                  SizedBox(height: 8 * k),
                  const FeatureMenuSection(),
                ],
              ),
            ),
            // 编辑资料弹窗走全局居中圆角底座（见 widgets/center_sheet.dart）
            if (_showEditModal) _buildEditModalOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditModalOverlay() {
    final profile = ref.read(profileManagerProvider).value ?? {};
    return EditProfileModal(
      currentNickname: profile['nickname'] ?? '小橘',
      currentEmoji: profile['avatar_emoji'] ?? '🧑',
      onClose: () => setState(() => _showEditModal = false),
      onConfirm: ({required String nickname, required String emoji}) {
        ref.read(profileManagerProvider.notifier).updateNickname(nickname);
        ref.read(profileManagerProvider.notifier).updateAvatarEmoji(emoji);
        setState(() => _showEditModal = false);
        ToastUtils.show(context, '资料已更新');
      },
    );
  }

  void _openEditModal() {
    setState(() => _showEditModal = true);
  }
}
