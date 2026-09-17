import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_skin.dart';
import '../../constants/design_metrics.dart';
import '../../providers/skin_provider.dart';
import '../../widgets/center_sheet.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/pill_content.dart';
import '../../widgets/section_title.dart';
import '../../widgets/skin_preview.dart';
import '../../widgets/toast_utils.dart';
import 'appearance_edit_page.dart';
import 'appearance_top_bar.dart';

/// 外观（配色皮肤）页面 —— 我的 → 设置 → 外观。
///
/// 结构：
/// 1. **当前配色**：大预览 + 名称，说明「已应用到全部页面」；
/// 2. **预置配色**：6 套内置方案，点一下即全应用换色；
/// 3. **我的配色**：用户自定义方案，可编辑 / 删除；
/// 4. 底部「新建一套配色」入口。
///
/// 每行左侧的 7 个小圆点是这套配色的**7 个锚点色**（主色 / 底色 / 卡底 /
/// 主文字 / 次文字 / 分割线 / 光晕）——其余 60 个令牌都由它们派生，
/// 所以看到这 7 个点基本就看到了整套界面。
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = DesignMetrics.of(context);
    final state = ref.watch(skinManagerProvider);
    final active = state.active;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const AppearanceTopBar(title: '外观', subtitle: '换一套配色，全部页面一起变'),
              Expanded(
                child: ListView(
                  // 横向留白只由各 section 自带（DesignMetrics.pageMargin），
                  // ListView 只留纵向 padding —— 全库统一规则
                  padding: EdgeInsets.only(top: 4 * k, bottom: 28 * k),
                  children: [
                    _CurrentSkinCard(skin: active, k: k),
                    SizedBox(height: 20 * k),
                    SectionTitle(
                      title: '预置配色',
                      titleSize: 13 * k,
                      titleColor: AppColors.blushInk,
                    ),
                    SizedBox(height: 10 * k),
                    _SkinGroup(
                      k: k,
                      children: [
                        for (final s in AppSkins.builtIns)
                          _SkinRow(
                            k: k,
                            skin: s,
                            active: s.id == active.id,
                            onTap: () => _apply(context, ref, s),
                          ),
                      ],
                    ),
                    SizedBox(height: 20 * k),
                    SectionTitle(
                      title: '我的配色',
                      titleSize: 13 * k,
                      titleColor: AppColors.blushInk,
                    ),
                    SizedBox(height: 10 * k),
                    if (state.custom.isEmpty)
                      _EmptyCustomHint(k: k)
                    else
                      _SkinGroup(
                        k: k,
                        children: [
                          for (final s in state.custom)
                            _SkinRow(
                              k: k,
                              skin: s,
                              active: s.id == active.id,
                              onTap: () => _apply(context, ref, s),
                              onEdit: () => context.push(
                                '/appearance-edit',
                                extra: AppearanceEditArgs(
                                  skin: s,
                                  isNew: false,
                                ),
                              ),
                              onDelete: () => _delete(context, ref, s),
                            ),
                        ],
                      ),
                    SizedBox(height: 12 * k),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignMetrics.pageMargin,
                      ),
                      child: _AddSkinButton(
                        k: k,
                        onTap: () => context.push(
                          '/appearance-edit',
                          extra: AppearanceEditArgs(
                            skin: AppSkins.draftFrom(active, name: '我的配色'),
                            isNew: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 应用一套皮肤。换肤是低频操作，这里给一句短提示确认「确实生效了」。
  ///
  /// 顺序：**先弹提示再换肤**。换肤会让本页整体重新挂载（页面 key 带皮肤版本号，
  /// 见 `app_router.dart` 的 `_skinKeyed`），提示要用当前还活着的 context 去取
  /// Overlay——反过来的话 context 可能已经失活。
  void _apply(BuildContext context, WidgetRef ref, AppSkin skin) {
    ToastUtils.show(context, '已切换到「${skin.name}」');
    ref.read(skinManagerProvider.notifier).select(skin);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AppSkin skin,
  ) async {
    final ok = await CenterSheetConfirm.show<bool>(
      context: context,
      title: '删除「${skin.name}」？',
      message: '删除后这套配色会被永久清除。若它正在使用，将回到默认配色「暖粉珊瑚」。',
      confirmLabel: '删除',
      danger: true,
      result: true,
    );
    if (ok != true) return;
    // 等用户点弹窗的这段时间里，本页有可能已经不在了（例如别处换了肤导致重挂载）。
    // 先确认还活着再用 context 取 Overlay。
    if (!context.mounted) return;
    // 同 _apply：先提示再删。删掉当前皮肤会回落默认配色并触发本页重挂，
    // 那时这个 context 已经失活，就没法再取 Overlay 弹提示了。
    ToastUtils.show(context, '已删除「${skin.name}」');
    await ref.read(skinManagerProvider.notifier).removeCustom(skin.id);
  }
}

/// 当前配色卡：大预览 + 名称 + 状态说明。
class _CurrentSkinCard extends StatelessWidget {
  final AppSkin skin;
  final double k;

  const _CurrentSkinCard({required this.skin, required this.k});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Container(
        padding: EdgeInsets.all(14 * k),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16 * k),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.floatCardShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 78 * k,
              height: 104 * k,
              child: FittedBox(child: SkinPreview(skin: skin)),
            ),
            SizedBox(width: 14 * k),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前配色',
                    style: TextStyle(
                      fontSize: 10.5 * k,
                      color: AppColors.blushInk3,
                    ),
                  ),
                  SizedBox(height: 4 * k),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          skin.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15 * k,
                            fontWeight: FontWeight.w800,
                            color: AppColors.blushInk,
                          ),
                        ),
                      ),
                      SizedBox(width: 6 * k),
                      _Tag(
                        k: k,
                        text: skin.builtIn ? '内置' : '自定义',
                        solid: !skin.builtIn,
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * k),
                  Text(
                    '已应用到全部页面。\n按钮、背景、文字与光晕都来自这一套配色。',
                    style: TextStyle(
                      fontSize: 11 * k,
                      height: 1.5,
                      color: AppColors.blushInk2,
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
}

/// 小标签（内置 / 自定义）
class _Tag extends StatelessWidget {
  final double k;
  final String text;
  final bool solid;

  const _Tag({required this.k, required this.text, this.solid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * k, vertical: 2 * k),
      decoration: BoxDecoration(
        color: solid ? AppColors.coral : AppColors.coralSoft,
        borderRadius: BorderRadius.circular(5 * k),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5 * k,
          fontWeight: FontWeight.w700,
          color: solid ? Colors.white : AppColors.coralDeep,
        ),
      ),
    );
  }
}

/// 行式白卡组：行间 1px 细线（与「我的 → 应用管理」同一套语言）
class _SkinGroup extends StatelessWidget {
  final double k;
  final List<Widget> children;

  const _SkinGroup({required this.k, required this.children});

  @override
  Widget build(BuildContext context) {
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
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) Container(height: 1, color: AppColors.cellDivider),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// 一行配色：缩略预览 + 名称 + 7 个锚点色点（+ 右侧操作）
class _SkinRow extends StatelessWidget {
  final double k;
  final AppSkin skin;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SkinRow({
    required this.k,
    required this.skin,
    required this.active,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  /// 该行是否是「我的配色」里的（可编辑/删除）
  bool get _editable => onEdit != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        color: active ? AppColors.coralSoft.withValues(alpha: 0.55) : null,
        padding: EdgeInsets.symmetric(horizontal: 12 * k, vertical: 10 * k),
        child: Row(
          children: [
            // 缩略预览（设计空间 120×160，等比缩到 45×60）
            SizedBox(
              width: 45 * k,
              height: 60 * k,
              child: FittedBox(child: SkinPreview(skin: skin)),
            ),
            SizedBox(width: 12 * k),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5 * k,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.coralDeep : AppColors.blushInk,
                    ),
                  ),
                  SizedBox(height: 8 * k),
                  _anchorDots(k),
                ],
              ),
            ),
            SizedBox(width: 8 * k),
            if (_editable) ...[
              _IconAction(
                k: k,
                icon: Icons.edit_outlined,
                color: AppColors.blushInk3,
                onTap: onEdit,
              ),
              SizedBox(width: 2 * k),
              _IconAction(
                k: k,
                icon: Icons.delete_outline,
                color: AppColors.alertRed,
                onTap: onDelete,
              ),
            ] else
              Icon(
                active ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18 * k,
                color: active
                    ? AppColors.coral
                    : AppColors.blushInk3.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }

  /// 7 个锚点色点
  Widget _anchorDots(double k) {
    final dot = 11 * k;
    final anchors = <Color>[
      skin.primary,
      skin.bg,
      skin.cardBg,
      skin.ink,
      skin.ink2,
      skin.line,
      skin.glow,
    ];
    return Row(
      children: [
        for (final c in anchors)
          Padding(
            padding: EdgeInsets.only(right: 4 * k),
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                // 浅色点在白卡上会看不见，统一描一圈极浅边
                border: Border.all(color: AppColors.blushLine, width: 0.8),
              ),
            ),
          ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final double k;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _IconAction({
    required this.k,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 32 * k,
        height: 32 * k,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9 * k)),
        child: Icon(icon, size: 17 * k, color: color),
      ),
    );
  }
}

/// 自定义配色为空时的提示块
class _EmptyCustomHint extends StatelessWidget {
  final double k;

  const _EmptyCustomHint({required this.k});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignMetrics.pageMargin),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18 * k, horizontal: 14 * k),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14 * k),
          border: Border.all(color: AppColors.blushLine),
        ),
        child: Text(
          '还没有自定义配色。\n点下面的按钮，挑 7 个颜色就能生成一套。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5 * k,
            height: 1.6,
            color: AppColors.blushInk3,
          ),
        ),
      ),
    );
  }
}

/// 「新建一套配色」按钮
class _AddSkinButton extends StatelessWidget {
  final double k;
  final VoidCallback onTap;

  const _AddSkinButton({required this.k, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 46 * k,
        decoration: BoxDecoration(
          color: AppColors.coralSoft,
          borderRadius: BorderRadius.circular(14 * k),
          border: Border.all(color: AppColors.coral.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: PillContent(
            label: '新建一套配色',
            leading: Icons.add,
            iconSize: 16 * k,
            labelStyle: TextStyle(
              fontSize: 13 * k,
              fontWeight: FontWeight.w700,
              color: AppColors.coralDeep,
            ),
          ),
        ),
      ),
    );
  }
}
