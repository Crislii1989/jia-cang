/// 统一颜色令牌。**所有页面取色只走这里**（禁写 Color(0x…) 字面量）。
///
/// ## 与皮肤系统的关系（2026-09-17 起）
///
/// 令牌分两类：
///
/// 1. **跟随皮肤（动态 getter）**——品牌色、中性面、文字三级、描边、阴影、
///    首页装饰色。它们由当前 [AppSkin] 解析：先查该皮肤的精确覆盖表，
///    没有则按锚点色派生（见 [_t] 的派生公式）。
/// 2. **固定常量（static const）**——语义色（成功/警告/危险/信息/逾期红）、
///    身份色（分类、房间、订单平台品牌、收纳层级、首页四色 pastel 轮转）。
///    这些**故意不随皮肤变**：状态语义不能因为换了绿色皮肤就把「危险」变绿；
///    pastel 轮转是设计的视觉签名。
///
/// 默认皮肤 [AppSkins.coral] 把全部动态令牌钉成了改造前的精确值，
/// 所以「不换皮肤」时的渲染与旧版本完全一致。
///
/// ⚠️ 动态令牌不能再进 `const` 表达式（运行时才能确定），
/// 写法上用 `final` 或直接在 build 里取用。
library;

import 'package:flutter/material.dart';

import 'app_skin.dart';

class AppColors {
  AppColors._();

  // ── 当前皮肤 ──
  //
  // 用可变静态持有：近千处调用点写的是 `AppColors.coral` 这种静态取值，
  // 若改成 `context.skin.coral` 需要改遍全库；这里保持静态 API 不变，
  // 由皮肤 provider 在切换时调用 [applySkin]，再让根节点重建即全局生效。
  static AppSkin _skin = AppSkins.coral;

  /// 皮肤变更计数：每次 [applySkin] 自增。
  ///
  /// 用途：路由页面的 key（见 `app_router.dart` 的 `_skinKeyed`）。
  /// **为什么必须换 key**：`const HomePage()` 这类页面在祖辈重建时会被
  /// Element 复用——`updateChild` 里 `child.widget == newWidget`（同一个
  /// const 规范化实例）会直接短路，**连 build 都不会调用**，页面内部
  /// 那些 `const _XxxSection()` 同理。于是「重建整棵树」对 const 子树
  /// 完全无效，换肤后它们纹丝不动。换成新 key 会让 Element 重新挂载，
  /// 整棵子树才会用新配色重新 build。
  static int skinRevision = 0;

  /// 当前生效的皮肤
  static AppSkin get skin => _skin;

  /// 应用皮肤（只改数据，刷新由调用方触发根节点重建）
  static void applySkin(AppSkin skin) {
    _skin = skin;
    skinRevision++;
  }

  /// 令牌解析：精确覆盖优先，否则用派生值。
  static Color _t(String token, Color derived) => _skin.exact[token] ?? derived;

  /// 派生的三级文字色（多处复用，避免公式散落）
  static Color get _ink3 =>
      _skin.exact[SkinTokens.blushInk3] ?? mixColor(_skin.ink2, _skin.bg, 0.5);

  // ── 兼容保留：旧金色系 ──
  //
  // 全局改版后不再用于按钮或页面底色，仅少量装饰/图表引用，保持常量。
  static const int _primaryInt = 0xFFFFB800;

  static const primary = Color(_primaryInt);
  static const primaryLight = Color(0xFFFFE9B0);
  static const primaryDark = Color(0xFFE5A500);
  static const accentGold = Color(0xFFE5A500);
  static const primaryMid = Color(0xFFFFD460);
  static const primaryDeep = Color(0xFFFF9E40);

  // ── 背景（跟随皮肤） ──
  /// 全局页面底色
  static Color get background => _t(SkinTokens.background, blushBg);
  /// 已废弃：旧版浅金底，随全局改版不再使用
  static const backgroundLight = Color(0xFFFFE9B0);
  /// 卡片/悬浮条底
  static Color get cardBg => _t(SkinTokens.cardBg, _skin.cardBg);
  /// 暖粉白页面底色（V2.0 令牌，与 [background] 同源）
  static Color get blushBg => _t(SkinTokens.blushBg, _skin.bg);

  // ── 文字（跟随皮肤） ──
  static Color get textPrimary => _t(SkinTokens.textPrimary, _skin.ink);
  static Color get textSecondary => _t(SkinTokens.textSecondary, _skin.ink2);
  static Color get textHint => _t(SkinTokens.textHint, _ink3);
  /// 深暖棕文字主色（V2.0 令牌）
  static Color get blushInk => _t(SkinTokens.blushInk, _skin.ink);
  /// 次级文字
  static Color get blushInk2 => _t(SkinTokens.blushInk2, _skin.ink2);
  /// 三级文字/占位
  static Color get blushInk3 => _t(SkinTokens.blushInk3, _ink3);

  // ── 描边 / 分割线（跟随皮肤） ──
  static Color get border => _t(SkinTokens.border, _skin.line);
  static Color get divider => _t(SkinTokens.divider, _skin.line);
  /// 边框 / 分隔线（V2.0 令牌）
  static Color get blushLine => _t(SkinTokens.blushLine, _skin.line);

  // ── 语义色（固定，不随皮肤变） ──
  static const success = Color(0xFF6BCB77);
  static const successLight = Color(0xFFD4F5D9);
  static const warning = Color(0xFFFF8C42);
  static const warningLight = Color(0xFFFFD4B8);
  static const danger = Color(0xFFFF6B6B);
  static const dangerLight = Color(0xFFFFD4D4);
  static const info = Color(0xFF5B9BFF);
  static const infoLight = Color(0xFFD4E8FF);
  static const purple = Color(0xFF9B7BFF);
  static const purpleLight = Color(0xFFE4DAFF);
  static const teal = Color(0xFF4ECDC4);
  static const statusUsing = Color(0xFF3A9E4A);
  static const statusUsingBg = Color(0xFFD4F5D9);
  static const selectedBg = Color(0xFFD4E8FF);
  static const accentLight = Color(0xFFFFE066);
  static const accentLightBg = Color.fromARGB(255, 241, 198, 77);

  // ── shimmer / 渐变（固定） ──
  static const shimmerGold = Color(0xFFFFB800);
  static const shimmerOrange = Color(0xFFFF8C42);
  static const shimmerRed = Color(0xFFFF6B6B);
  static const shimmerGreen = Color(0xFF6BCB77);
  static const gradientGold = Color(0xFFFFD460);
  static const gradientOrange = Color(0xFFFF9E6C);
  static const gradientOrangeEnd = Color(0xFFFF7A30);
  static const gradientGreen = Color(0xFF7EE08A);
  static const gradientGreenEnd = Color(0xFF4BC25A);
  static const gradientBlue = Color(0xFF8AB4FF);
  static const gradientBlueEnd = Color(0xFF5588EE);

  // ── 标签色（固定） ──
  static const tagNew = Color(0xFF3A9E4A);
  static const tagNewBg = Color(0xFFD4F5D9);
  static const tagUrgent = Color(0xFFFF6B6B);
  static const tagNormal = Color(0xFF5B9BFF);

  // ── 阴影（跟随皮肤：色相跟文字色走，避免彩色皮肤上出现突兀的暖棕影子） ──
  static Color get shadowPrimary =>
      _t(SkinTokens.shadowPrimary, _skin.primary.withValues(alpha: 0.12));
  static Color get shadowDark =>
      _t(SkinTokens.shadowDark, _skin.ink.withValues(alpha: 0.05));
  static Color get shadowCard =>
      _t(SkinTokens.shadowCard, _skin.ink.withValues(alpha: 0.10));

  // ── 状态身份色（固定：在库绿 / 出借蓝） ──
  static const safeGreen = Color(0xFF3E9B4F);
  static const safeGreenBg = Color(0xFFE6F4EA);
  static const lendBlue = Color(0xFF4A7FB5);
  static const lendBlueBg = Color(0xFFE8F0F8);
  /// 临期文字（浅金底上的深金棕，保证对比度）
  static const warnBrown = Color(0xFFB27E00);
  /// 逾期（红）
  static const alertRed = Color(0xFFD64545);
  static const alertRedBg = Color(0xFFFDE8E8);

  // ── 品牌色 / 主色（跟随皮肤） ──
  /// 主色（默认皮肤为珊瑚）
  static Color get coral => _t(SkinTokens.coral, _skin.primary);
  /// 主色加深：链接文字 / 按压态
  static Color get coralDeep =>
      _t(SkinTokens.coralDeep, darkenColor(_skin.primary, 0.12));
  /// 主色浅底：hot 态卡片底色
  static Color get coralSoft =>
      _t(SkinTokens.coralSoft, mixColor(_skin.primary, _skin.cardBg, 0.86));
  /// hot 态图标/数字块底色
  static Color get coralTile =>
      _t(SkinTokens.coralTile, mixColor(_skin.primary, _skin.cardBg, 0.74));

  // ── 首页统计迷你卡色块 / 四色 pastel 轮转（固定：设计视觉签名） ──
  static const statPeach = Color(0xFFD97B4F);
  static const statPeachBg = Color(0xFFFFE3D3);
  static const statCoral = Color(0xFFDD5B46);
  static const statCoralBg = Color(0xFFFFE9E2);
  static const statPurple = Color(0xFF8A6FD1);
  static const statPurpleBg = Color(0xFFE9E2F8);
  static const statBlue = Color(0xFF5B8AC4);
  static const statBlueBg = Color(0xFFDCE8F7);
  static const statGreen = Color(0xFF4E9E68);
  static const statGreenBg = Color(0xFFDFF0E4);

  // ── 全局背景光晕（跟随皮肤） ──
  /// 右上角光晕（自带 alpha，叠在页面底色上）
  static Color get bgGlow => _t(SkinTokens.bgGlow, _skin.glow);
  /// 光晕渐隐端（同色全透明）——外圈必须淡到 0，否则出现硬边圆环
  static Color get glowFade =>
      _t(SkinTokens.glowFade, _skin.glow.withValues(alpha: 0));

  // ── 悬浮条 / 悬浮卡（跟随皮肤） ──
  /// 底部导航条底：半透明白 .86（透出全局背景）
  static Color get navBarBg =>
      _t(SkinTokens.navBarBg, cardBg.withValues(alpha: 0.86));
  /// 底部操作条条底：半透明白 .92（托按钮，需保证对比度）
  static Color get actionBarBg =>
      _t(SkinTokens.actionBarBg, cardBg.withValues(alpha: 0.92));
  /// 悬浮条投影
  static Color get barShadow =>
      _t(SkinTokens.barShadow, _skin.ink.withValues(alpha: 0.14));
  /// 悬浮条描边（白底方块的一圈极浅高光边）
  static Color get floatHairline =>
      _t(SkinTokens.floatHairline, Colors.white.withValues(alpha: 0.90));
  /// 浅一档的高光边（水彩渐变卡片用）
  static Color get floatHairlineSoft =>
      _t(SkinTokens.floatHairlineSoft, Colors.white.withValues(alpha: 0.75));
  /// 悬浮卡片投影——搜索胶囊、提醒卡组
  static Color get floatCardShadow =>
      _t(SkinTokens.floatCardShadow, _skin.ink.withValues(alpha: 0.10));
  /// 稍重的悬浮卡片投影——水彩统计卡、分类大圆
  static Color get floatCardShadowStrong =>
      _t(SkinTokens.floatCardShadowStrong, _skin.ink.withValues(alpha: 0.12));
  /// 中央添加钮投影
  static Color get addFabShadow =>
      _t(SkinTokens.addFabShadow, addFab.withValues(alpha: 0.45));
  /// 主按钮投影
  static Color get btnPrimaryShadow =>
      _t(SkinTokens.btnPrimaryShadow, _skin.primary.withValues(alpha: 0.35));

  /// 导航条当前 Tab
  static Color get navActive =>
      _t(SkinTokens.navActive, mixColor(_skin.primary, _skin.cardBg, 0.16));
  /// 导航条未选中
  static Color get navInactive => _t(SkinTokens.navInactive, _skin.ink2);
  /// 中央添加钮底色
  static Color get addFab =>
      _t(SkinTokens.addFab, mixColor(_skin.primary, _skin.cardBg, 0.28));

  // ── 首页问候区（跟随皮肤） ──
  static Color get greetInk =>
      _t(SkinTokens.greetInk, mixColor(_skin.ink, _skin.primary, 0.30));
  static Color get greetSub =>
      _t(SkinTokens.greetSub, mixColor(_skin.ink2, _skin.bg, 0.25));
  static Color get greetHeart =>
      _t(SkinTokens.greetHeart, mixColor(_skin.primary, _skin.ink, 0.30));
  static Color get homeHouseIcon => _t(SkinTokens.homeHouseIcon, _skin.ink2);

  // ── 首页统计高卡 / 分类大圆的 pastel 渐变（固定） ──
  static const statHighPinkFg = Color(0xFFD9534A);
  static const statHighGreenFg = Color(0xFF3E9B5B);
  static const statHighBlueFg = Color(0xFF3F7DC0);
  static const statHighPurpleFg = Color(0xFF7B5FC7);
  static const statHighLabel = Color(0xFF6F5A52);
  static const statHighPink = [Color(0xFFF9D5D1), Color(0xFFFCEBE6), Color(0xFFFDF7F3)];
  static const statHighGreen = [Color(0xFFD3E7CE), Color(0xFFEAF3E6), Color(0xFFF6FAF3)];
  static const statHighBlue = [Color(0xFFD0E0F0), Color(0xFFE8F0F8), Color(0xFFF4F8FC)];
  static const statHighPurple = [Color(0xFFDED4F1), Color(0xFFEEE9F8), Color(0xFFF8F5FC)];
  static const catPink = [Color(0xFFF6CBC6), Color(0xFFFCEAE6)];
  static const catBlue = [Color(0xFFCCDEF1), Color(0xFFEBF2F9)];
  static const catGreen = [Color(0xFFD0E7CB), Color(0xFFEBF4E8)];
  static const catPurple = [Color(0xFFDACFF0), Color(0xFFEFEAF9)];
  /// 分类标签文字（跟随皮肤）
  static Color get catLabel => _t(SkinTokens.catLabel, _skin.ink);

  // ── 首页提醒卡组 ──
  /// 行间细分割线（跟随皮肤）
  static Color get reminderDivider =>
      _t(SkinTokens.reminderDivider, mixColor(_skin.line, _skin.cardBg, 0.30));
  /// 右侧日期（三级文字，跟随皮肤）
  static Color get reminderDate => _t(SkinTokens.reminderDate, _ink3);
  /// 状态小字（语义，固定）
  static const reminderDanger = Color(0xFFD9534A);
  static const reminderWarn = Color(0xFFE0764F);
  /// 状态小字第三档（跟随皮肤）
  static Color get reminderMuted => _t(SkinTokens.reminderMuted, _skin.ink2);

  // ── 按钮色彩（跟随皮肤；所有页面按钮一律取这一段） ──
  /// 主按钮底色：实心主色
  static Color get btnPrimaryBg => _t(SkinTokens.btnPrimaryBg, coral);
  /// 主按钮文字/图标：白
  static Color get btnPrimaryFg => _t(SkinTokens.btnPrimaryFg, Colors.white);
  /// 幽灵（次要）按钮底色
  static Color get btnGhostBg => _t(SkinTokens.btnGhostBg, cardBg);
  /// 幽灵按钮描边
  static Color get btnGhostBorder => _t(SkinTokens.btnGhostBorder, blushLine);
  /// 幽灵按钮描边宽度
  static const btnGhostBorderWidth = 1.5;
  /// 幽灵按钮文字/图标
  static Color get btnGhostFg => _t(SkinTokens.btnGhostFg, blushInk);
  /// 软性按钮底色
  static Color get btnSoftBg => _t(SkinTokens.btnSoftBg, coralSoft);
  /// 软性按钮文字/图标
  static Color get btnSoftFg => _t(SkinTokens.btnSoftFg, coralDeep);
  /// 文字按钮 / 链接型按钮前景色
  static Color get btnTextFg => _t(SkinTokens.btnTextFg, coralDeep);
  /// 危险行动（删除、清空）——固定语义色
  static const btnDangerFg = alertRed;
  static const btnDangerBg = alertRedBg;
  /// 选中态标签底色
  static Color get chipSelectedBg => _t(SkinTokens.chipSelectedBg, coral);
  /// 选中态标签文字/图标
  static Color get chipSelectedFg => _t(SkinTokens.chipSelectedFg, Colors.white);
  /// 未选中标签底色
  static Color get chipBg => _t(SkinTokens.chipBg, cardBg);
  /// 未选中标签描边
  static Color get chipBorder => _t(SkinTokens.chipBorder, blushLine);
  /// 未选中标签文字
  static Color get chipFg => _t(SkinTokens.chipFg, _skin.ink2);

  // ── 详情页 / 添加页（V2.7 令牌） ──
  /// 详情页沉浸大图的渐变（跟随皮肤）
  static List<Color> get heroGradient =>
      _skin.exactGradient ??
      [
        mixColor(_skin.primary, Colors.white, 0.35),
        _skin.primary,
        darkenColor(_skin.primary, 0.12),
      ];
  /// 信息组行间极浅分割线
  static Color get cellDivider =>
      _t(SkinTokens.cellDivider, mixColor(_skin.line, _skin.cardBg, 0.45));
  /// 新增照片虚线块描边
  static Color get photoAddBorder =>
      _t(SkinTokens.photoAddBorder, mixColor(_skin.primary, _skin.cardBg, 0.55));
  /// 新增照片虚线块底色
  static Color get photoAddBg =>
      _t(SkinTokens.photoAddBg, mixColor(_skin.primary, _skin.cardBg, 0.93));
  /// hot 态提示卡底色（临期/闲置强调；非默认皮肤跟随主色浅底）
  static Color get goldSoft =>
      _t(SkinTokens.goldSoft, mixColor(_skin.primary, _skin.cardBg, 0.88));
  /// hot 态卡片描边（无生产引用，保留常量）
  static const goldSoftBorder = Color(0xFFF2D488);
  /// hot 态图标块底色（无生产引用，保留常量）
  static const goldTile = Color(0xFFFFE49A);
  /// 普通图标块底色（中性暖灰）
  static const neutralTile = Color(0xFFF5EFE4);
  /// 详情页删除旋钮描边（危险语义，固定）
  static const delKnobBorder = Color(0xFFF0B9B9);
  /// 详情页删除旋钮投影（危险语义，固定）
  static const delKnobShadow = Color(0x2ED64545);
  /// 卡片投影
  static Color get cardShadow =>
      _t(SkinTokens.cardShadow, _skin.ink.withValues(alpha: 0.07));
  /// 详情页「到期日」条描边
  static Color get expiryRowBorder =>
      _t(SkinTokens.expiryRowBorder, mixColor(_skin.primary, _skin.cardBg, 0.70));
  /// 到期日条里「还剩 N 天」的强调色
  static Color get expiryHint =>
      _t(SkinTokens.expiryHint, darkenColor(_skin.primary, 0.20));
}
