/// 外观皮肤（配色方案）系统
///
/// ## 为什么是「锚点 + 派生」而不是让用户填 60 个颜色
///
/// 全库颜色都从 [AppColors] 取值（60+ 个令牌、近千处引用）。如果每套皮肤都
/// 要用户逐个填色，既没人愿意填，也一定会填出「主色换了但描边还是粉色」这种
/// 破绽。所以：
///
/// - **用户只编辑 7 个锚点色**（主色 / 页面底色 / 卡片底 / 主文字 / 次文字 /
///   分割线 / 光晕），其余令牌由锚点**派生**（变浅、变深、混白、带上透明度），
///   一套协调的界面自动成立。
/// - 内置皮肤可以给个别派生项**打精确补丁**（[exact]），默认皮肤
///   「暖粉珊瑚」就把全部 60 个令牌都钉成改造前的精确值——**默认外观零变化**，
///   这是硬要求，否则老用户一升级会以为界面坏了。
///
/// ## 什么不跟着皮肤变
///
/// 语义色（成功 / 警告 / 危险 / 信息 / 逾期红）与身份色（分类身份色、房间身份色、
/// 订单平台品牌色、收纳层级三色、首页四色 pastel 渐变轮转）**固定不变**：
/// 前者变了会让状态语义失真（比如绿色皮肤里的「危险」不该变绿），
/// 后者是这套设计的视觉签名（彩虹 pastel），换皮肤也要保留。
library;

import 'package:flutter/material.dart';

/// 混色：`t=0` 取 [a]，`t=1` 取 [b]（中间即按比例混合，含 alpha）。
Color mixColor(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;

/// 压暗：朝黑色插值。
Color darkenColor(Color c, [double t = 0.12]) => mixColor(c, Colors.black, t);

/// 提亮：朝白色插值。
Color lightenColor(Color c, [double t = 0.2]) => mixColor(c, Colors.white, t);

/// 一套配色方案。
///
/// [exact] 是「令牌名 → 精确颜色」的覆盖表；查询用 [AppColors] 里的私有
/// `_t()` 完成（先查 [exact]，再落到派生值）。令牌名的常量集中在
/// [SkinTokens] 里，避免各处手写字符串写错。
@immutable
class AppSkin {
  /// 稳定 id：内置皮肤固定（`builtin_*`），自定义皮肤为 `custom_<毫秒时间戳>`。
  final String id;
  final String name;
  final bool builtIn;

  // ── 7 个锚点（用户可编辑） ──
  /// 主色：按钮底、选中态、强调文字
  final Color primary;
  /// 页面底色
  final Color bg;
  /// 卡片/悬浮条底色
  final Color cardBg;
  /// 主文字
  final Color ink;
  /// 次文字
  final Color ink2;
  /// 分割线 / 描边
  final Color line;
  /// 背景右上角光晕（**需自带 alpha**，派生用 `glow.withValues(alpha: 0)` 收尾）
  final Color glow;

  /// 精确覆盖表（令牌名 → 颜色）。默认皮肤塞满全部令牌。
  final Map<String, Color> exact;

  /// 精确覆盖表里的渐变类令牌（`heroGradient` 三个色标）。
  final List<Color>? exactGradient;

  const AppSkin({
    required this.id,
    required this.name,
    required this.primary,
    required this.bg,
    required this.cardBg,
    required this.ink,
    required this.ink2,
    required this.line,
    required this.glow,
    this.builtIn = false,
    this.exact = const {},
    this.exactGradient,
  });

  bool get isDefault => id == 'builtin_coral';

  AppSkin copyWith({
    String? id,
    String? name,
    Color? primary,
    Color? bg,
    Color? cardBg,
    Color? ink,
    Color? ink2,
    Color? line,
    Color? glow,
    Map<String, Color>? exact,
    List<Color>? exactGradient,
  }) {
    return AppSkin(
      id: id ?? this.id,
      name: name ?? this.name,
      builtIn: builtIn,
      primary: primary ?? this.primary,
      bg: bg ?? this.bg,
      cardBg: cardBg ?? this.cardBg,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      line: line ?? this.line,
      glow: glow ?? this.glow,
      exact: exact ?? this.exact,
      exactGradient: exactGradient ?? this.exactGradient,
    );
  }

  /// 序列化（自定义皮肤存本地；内置皮肤不落盘）
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'primary': primary.toARGB32(),
    'bg': bg.toARGB32(),
    'cardBg': cardBg.toARGB32(),
    'ink': ink.toARGB32(),
    'ink2': ink2.toARGB32(),
    'line': line.toARGB32(),
    'glow': glow.toARGB32(),
  };

  /// 反序列化：坏数据不抛异常，回落到默认皮肤（宁可少一套皮肤，不能让开屏崩）
  factory AppSkin.fromJson(Map<String, dynamic> json) {
    Color c(String key, Color fallback) {
      final v = json[key];
      if (v is int) return Color(v);
      return fallback;
    }

    final d = AppSkins.coral;
    return AppSkin(
      id: (json['id'] as String?) ?? 'custom_unknown',
      name: (json['name'] as String?) ?? '自定义皮肤',
      primary: c('primary', d.primary),
      bg: c('bg', d.bg),
      cardBg: c('cardBg', d.cardBg),
      ink: c('ink', d.ink),
      ink2: c('ink2', d.ink2),
      line: c('line', d.line),
      glow: c('glow', d.glow),
    );
  }
}

/// 令牌名常量：`exact` 覆盖表的键，避免手写字符串出错。
class SkinTokens {
  SkinTokens._();

  // 品牌 / 按钮
  static const coral = 'coral';
  static const coralDeep = 'coralDeep';
  static const coralSoft = 'coralSoft';
  static const coralTile = 'coralTile';
  static const btnPrimaryBg = 'btnPrimaryBg';
  static const btnPrimaryFg = 'btnPrimaryFg';
  static const btnSoftBg = 'btnSoftBg';
  static const btnSoftFg = 'btnSoftFg';
  static const btnTextFg = 'btnTextFg';
  static const chipSelectedBg = 'chipSelectedBg';
  static const chipSelectedFg = 'chipSelectedFg';
  static const chipBg = 'chipBg';
  static const chipBorder = 'chipBorder';
  static const chipFg = 'chipFg';
  static const btnGhostBg = 'btnGhostBg';
  static const btnGhostBorder = 'btnGhostBorder';
  static const btnGhostFg = 'btnGhostFg';
  static const navActive = 'navActive';
  static const navInactive = 'navInactive';
  static const addFab = 'addFab';
  static const addFabShadow = 'addFabShadow';
  static const btnPrimaryShadow = 'btnPrimaryShadow';

  // 中性面
  static const blushBg = 'blushBg';
  static const background = 'background';
  static const cardBg = 'cardBg';
  static const navBarBg = 'navBarBg';
  static const actionBarBg = 'actionBarBg';
  static const bgGlow = 'bgGlow';
  static const glowFade = 'glowFade';
  static const barShadow = 'barShadow';
  static const floatHairline = 'floatHairline';
  static const floatHairlineSoft = 'floatHairlineSoft';
  static const floatCardShadow = 'floatCardShadow';
  static const floatCardShadowStrong = 'floatCardShadowStrong';
  static const cardShadow = 'cardShadow';
  static const shadowCard = 'shadowCard';
  static const shadowDark = 'shadowDark';
  static const shadowPrimary = 'shadowPrimary';
  static const cellDivider = 'cellDivider';
  static const reminderDivider = 'reminderDivider';

  // 文字
  static const textPrimary = 'textPrimary';
  static const textSecondary = 'textSecondary';
  static const textHint = 'textHint';
  static const blushInk = 'blushInk';
  static const blushInk2 = 'blushInk2';
  static const blushInk3 = 'blushInk3';

  // 描边
  static const border = 'border';
  static const divider = 'divider';
  static const blushLine = 'blushLine';

  // 装饰
  static const goldSoft = 'goldSoft';
  static const greetInk = 'greetInk';
  static const greetSub = 'greetSub';
  static const greetHeart = 'greetHeart';
  static const homeHouseIcon = 'homeHouseIcon';
  static const catLabel = 'catLabel';
  static const reminderDate = 'reminderDate';
  static const reminderMuted = 'reminderMuted';
  static const photoAddBg = 'photoAddBg';
  static const photoAddBorder = 'photoAddBorder';
  static const expiryRowBorder = 'expiryRowBorder';
  static const expiryHint = 'expiryHint';
}

/// 内置皮肤集合。
class AppSkins {
  AppSkins._();

  static const String defaultId = 'builtin_coral';

  // ────────────────────────────── 1. 暖粉珊瑚（默认，全令牌钉死） ─────────────
  //
  // 这一套的 exact 表就是改造前 app_colors.dart 的全部取值，
  // 目的是让「默认皮肤」与旧版本渲染**像素级一致**。
  // 改这里的值 = 改全局默认外观，请先确认设计稿。
  static const AppSkin coral = AppSkin(
    id: defaultId,
    name: '暖粉珊瑚',
    builtIn: true,
    primary: Color(0xFFF2705B),
    bg: Color(0xFFFBF3EE),
    cardBg: Colors.white,
    ink: Color(0xFF4A3733),
    ink2: Color(0xFF9A817B),
    line: Color(0xFFF3DED7),
    glow: Color(0x85FFA470),
    exact: {
      // 品牌 / 按钮
      SkinTokens.coral: Color(0xFFF2705B),
      SkinTokens.coralDeep: Color(0xFFDD5B46),
      SkinTokens.coralSoft: Color(0xFFFFE9E2),
      SkinTokens.coralTile: Color(0xFFFFD9CC),
      SkinTokens.btnPrimaryBg: Color(0xFFF2705B),
      SkinTokens.btnPrimaryFg: Colors.white,
      SkinTokens.btnSoftBg: Color(0xFFFFE9E2),
      SkinTokens.btnSoftFg: Color(0xFFDD5B46),
      SkinTokens.btnTextFg: Color(0xFFDD5B46),
      SkinTokens.chipSelectedBg: Color(0xFFF2705B),
      SkinTokens.chipSelectedFg: Colors.white,
      SkinTokens.chipBg: Colors.white,
      SkinTokens.chipBorder: Color(0xFFF3DED7),
      SkinTokens.chipFg: Color(0xFF9A817B),
      SkinTokens.btnGhostBg: Colors.white,
      SkinTokens.btnGhostBorder: Color(0xFFF3DED7),
      SkinTokens.btnGhostFg: Color(0xFF4A3733),
      SkinTokens.navActive: Color(0xFFE8807F),
      SkinTokens.navInactive: Color(0xFF9A7C5C),
      SkinTokens.addFab: Color(0xFFF79C84),
      SkinTokens.addFabShadow: Color(0x73F79C84),
      SkinTokens.btnPrimaryShadow: Color(0x59F2705B),
      // 中性面
      SkinTokens.blushBg: Color(0xFFFBF3EE),
      SkinTokens.background: Color(0xFFFBF3EE),
      SkinTokens.cardBg: Colors.white,
      SkinTokens.navBarBg: Color(0xDBFFFFFF),
      SkinTokens.actionBarBg: Color(0xEBFFFFFF),
      SkinTokens.bgGlow: Color(0x85FFA470),
      SkinTokens.glowFade: Color(0x00FFA470),
      SkinTokens.barShadow: Color(0x24965A46),
      SkinTokens.floatHairline: Color(0xE6FFFFFF),
      SkinTokens.floatHairlineSoft: Color(0xBFFFFFFF),
      SkinTokens.floatCardShadow: Color(0x1A965A46),
      SkinTokens.floatCardShadowStrong: Color(0x1F965A46),
      SkinTokens.cardShadow: Color(0x124D3733),
      SkinTokens.shadowCard: Color(0x1AFFB800),
      SkinTokens.shadowDark: Color(0x0D3D2B1F),
      SkinTokens.shadowPrimary: Color(0x1FFFB800),
      SkinTokens.cellDivider: Color(0xFFFAF0EA),
      SkinTokens.reminderDivider: Color(0xFFF7EAE4),
      // 文字
      SkinTokens.textPrimary: Color(0xFF3D2B1F),
      SkinTokens.textSecondary: Color(0xFF8B7355),
      SkinTokens.textHint: Color(0xFFB8A48E),
      SkinTokens.blushInk: Color(0xFF4A3733),
      SkinTokens.blushInk2: Color(0xFF9A817B),
      SkinTokens.blushInk3: Color(0xFFC3ABA4),
      // 描边
      SkinTokens.border: Color(0xFFF0E4D0),
      SkinTokens.divider: Color(0xFFF0E4D0),
      SkinTokens.blushLine: Color(0xFFF3DED7),
      // 装饰
      SkinTokens.goldSoft: Color(0xFFFFF4D6),
      SkinTokens.greetInk: Color(0xFF6B3B33),
      SkinTokens.greetSub: Color(0xFFB48D82),
      SkinTokens.greetHeart: Color(0xFFC98A79),
      SkinTokens.homeHouseIcon: Color(0xFF8E6E65),
      SkinTokens.catLabel: Color(0xFF5C4740),
      SkinTokens.reminderDate: Color(0xFFC3ABA4),
      SkinTokens.reminderMuted: Color(0xFF9A817B),
      SkinTokens.photoAddBg: Color(0xFFFFF7F3),
      SkinTokens.photoAddBorder: Color(0xFFF0B7A6),
      SkinTokens.expiryRowBorder: Color(0xFFF6C4B4),
      SkinTokens.expiryHint: Color(0xFFC25A3C),
    },
    exactGradient: [Color(0xFFFFB9A5), Color(0xFFF2705B), Color(0xFFDD5B46)],
  );

  // ────────────────────────────── 2~6 派生皮肤 ──────────────────────────────
  //
  // 只给 7 个锚点，其余全部交由 app_colors.dart 的派生规则生成。
  // 深色系在这里不做（对比度要另一套约束），故 cardBg 一律白、ink 一律深色。

  static const AppSkin mint = AppSkin(
    id: 'builtin_mint',
    name: '薄荷青',
    builtIn: true,
    primary: Color(0xFF3FA98C),
    bg: Color(0xFFF1F7F4),
    cardBg: Colors.white,
    ink: Color(0xFF2F3E39),
    ink2: Color(0xFF7A948B),
    line: Color(0xFFDDEBE5),
    glow: Color(0x85A8E6D2),
  );

  static const AppSkin mist = AppSkin(
    id: 'builtin_mist',
    name: '雾霭蓝',
    builtIn: true,
    primary: Color(0xFF5B8AC4),
    bg: Color(0xFFF1F5FA),
    cardBg: Colors.white,
    ink: Color(0xFF33404E),
    ink2: Color(0xFF7E8FA3),
    line: Color(0xFFDCE5F0),
    glow: Color(0x85AFCBEA),
  );

  static const AppSkin lilac = AppSkin(
    id: 'builtin_lilac',
    name: '藕荷紫',
    builtIn: true,
    primary: Color(0xFF8A6FD1),
    bg: Color(0xFFF6F3FB),
    cardBg: Colors.white,
    ink: Color(0xFF3E3550),
    ink2: Color(0xFF8D82A3),
    line: Color(0xFFE7E0F3),
    glow: Color(0x85C6B4EF),
  );

  static const AppSkin matcha = AppSkin(
    id: 'builtin_matcha',
    name: '抹茶奶绿',
    builtIn: true,
    primary: Color(0xFF6BA05C),
    bg: Color(0xFFF4F7EF),
    cardBg: Colors.white,
    ink: Color(0xFF3A4632),
    ink2: Color(0xFF89957E),
    line: Color(0xFFE3EBD9),
    glow: Color(0x85C4DFA8),
  );

  static const AppSkin caramel = AppSkin(
    id: 'builtin_caramel',
    name: '焦糖奶茶',
    builtIn: true,
    primary: Color(0xFFC07A4A),
    bg: Color(0xFFFBF4EC),
    cardBg: Colors.white,
    ink: Color(0xFF46362C),
    ink2: Color(0xFF99836F),
    line: Color(0xFFF0E0CF),
    glow: Color(0x85E7BE92),
  );

  /// 内置皮肤顺序 = 界面上展示的顺序（第一项为默认）。
  static const List<AppSkin> builtIns = [
    coral,
    mint,
    mist,
    lilac,
    matcha,
    caramel,
  ];

  /// 自定义皮肤 id 的进程内序号（见 [nextCustomId]）
  static int _seq = 0;

  /// 生成一个不重复的自定义皮肤 id。
  ///
  /// **不能只用毫秒时间戳**：连点两次「新建一套配色」很容易落在同一毫秒，
  /// 两套皮肤拿到同一个 id —— 列表里看起来是两套，一保存就互相覆盖，
  /// 删一套还会把另一套一起删掉（测试里就是这么翻出来的）。
  static String nextCustomId() =>
      'custom_${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

  /// 供「新建自定义皮肤」预填：以当前皮肤为起点，用户改几个色就行。
  static AppSkin draftFrom(AppSkin base, {required String name}) {
    return AppSkin(
      id: nextCustomId(),
      name: name,
      primary: base.primary,
      bg: base.bg,
      cardBg: base.cardBg,
      ink: base.ink,
      ink2: base.ink2,
      line: base.line,
      glow: base.glow,
    );
  }

  /// 全新自定义皮肤的默认起点（柔和的灰蓝，怎么调都不会太丑）。
  static AppSkin blankDraft({required String name}) {
    return AppSkin(
      id: nextCustomId(),
      name: name,
      primary: const Color(0xFF7C9CB8),
      bg: const Color(0xFFF4F6F8),
      cardBg: Colors.white,
      ink: const Color(0xFF37414A),
      ink2: const Color(0xFF8593A0),
      line: const Color(0xFFE2E7EC),
      glow: const Color(0x85B9CFDF),
    );
  }
}
