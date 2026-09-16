/// 统一颜色常量
///
/// 应用主色调：
/// - 金色 (#FFB800) 作为主色
/// - 暖白 (#FFF8E7 / #FFE9B0) 作为背景
/// - 深棕 (#3D2B1F) 作为文字主色
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── 主色 ──
  static const int _primaryInt = 0xFFFFB800;
  static const int _bgInt = 0xFFFFF8E7;
  static const int _textInt = 0xFF3D2B1F;

  // ── 品牌色 ──
  static const primary = Color(_primaryInt);
  static const primaryLight = Color(0xFFFFE9B0);
  static const primaryDark = Color(0xFFE5A500);
  static const accentGold = Color(0xFFE5A500);
  static const primaryMid = Color(0xFFFFD460);
  static const primaryDeep = Color(0xFFFF9E40);

  // ── 背景色 ──
  static const background = Color(_bgInt);
  static const backgroundLight = Color(0xFFFFE9B0);
  static const cardBg = Colors.white;

  // ── 文字色 ──
  static const textPrimary = Color(_textInt);
  static const textSecondary = Color(0xFF8B7355);
  static const textHint = Color(0xFFB8A48E);

  // ── 装饰色 ──
  static const border = Color(0xFFF0E4D0);
  static const divider = Color(0xFFF0E4D0);

  // ── 语义色 ──
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

  // ── 额外背景色 ──
  static const accentLightBg = Color.fromARGB(255, 241, 198, 77);
  static const shimmerGold = Color(0xFFFFB800);
  static const shimmerOrange = Color(0xFFFF8C42);
  static const shimmerRed = Color(0xFFFF6B6B);
  static const shimmerGreen = Color(0xFF6BCB77);

  // ── 渐变起始色（快捷操作） ──
  static const gradientGold = Color(0xFFFFD460);
  static const gradientOrange = Color(0xFFFF9E6C);
  static const gradientOrangeEnd = Color(0xFFFF7A30);
  static const gradientGreen = Color(0xFF7EE08A);
  static const gradientGreenEnd = Color(0xFF4BC25A);
  static const gradientBlue = Color(0xFF8AB4FF);
  static const gradientBlueEnd = Color(0xFF5588EE);

  // ── 标签色 ──
  static const tagNew = Color(0xFF3A9E4A);
  static const tagNewBg = Color(0xFFD4F5D9);
  static const tagUrgent = Color(0xFFFF6B6B);
  static const tagNormal = Color(0xFF5B9BFF);

  // ── 阴影色（带透明度） ──
  static const shadowPrimary = Color(0x1FFFB800);
  static const shadowDark = Color(0x0D3D2B1F);
  static const shadowCard = Color(0x1AFFB800);

  // ── UI 改版令牌（高保真稿 docs/ui-hifi-mockups.html V1.x，2026-09） ──
  /// 浅金底：临期/闲置等「hot 态」统计卡与提醒强调
  static const goldSoft = Color(0xFFFFF4D6);
  /// hot 态卡片描边
  static const goldSoftBorder = Color(0xFFF2D488);
  /// hot 态图标块底色
  static const goldTile = Color(0xFFFFE49A);
  /// 普通图标块底色（中性暖灰）
  static const neutralTile = Color(0xFFF5EFE4);

  /// 在库（绿）
  static const safeGreen = Color(0xFF3E9B4F);
  static const safeGreenBg = Color(0xFFE6F4EA);
  /// 出借中（蓝）
  static const lendBlue = Color(0xFF4A7FB5);
  static const lendBlueBg = Color(0xFFE8F0F8);
  /// 临期文字（浅金底上的深金棕，保证对比度）
  static const warnBrown = Color(0xFFB27E00);
  /// 逾期（红，替换旧 coral 色 danger 用于徽标/旋钮）
  static const alertRed = Color(0xFFD64545);
  static const alertRedBg = Color(0xFFFDE8E8);

  // ── V2.0 水彩粉 / 珊瑚色系令牌（docs/ui-hifi-mockups.html V2.0，2026-09-16） ──
  //
  // 用户参考图定调：暖粉白底 + 珊瑚主色 + 彩虹 pastel 数字色块。
  // 本轮先用于「首页 + 底部悬浮胶囊导航」，其余页面下一轮跟进统一。
  /// 主色：珊瑚（点击态、当前 Tab、主按钮）
  static const coral = Color(0xFFF2705B);
  /// 主色加深：链接文字 / 按压态
  static const coralDeep = Color(0xFFDD5B46);
  /// 主色浅底：hot 态卡片底色
  static const coralSoft = Color(0xFFFFE9E2);
  /// hot 态图标/数字块底色
  static const coralTile = Color(0xFFFFD9CC);
  /// 暖粉白页面底色
  static const blushBg = Color(0xFFFBF3EE);
  /// 深暖棕文字主色
  static const blushInk = Color(0xFF4A3733);
  /// 次级文字
  static const blushInk2 = Color(0xFF9A817B);
  /// 三级文字/占位
  static const blushInk3 = Color(0xFFC3ABA4);
  /// 边框 / 分隔线
  static const blushLine = Color(0xFFF3DED7);

  /// 首页统计迷你卡数字色块（4 色轮转：物品总数 / 即将到期 / 出借中 / 长期闲置）
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

  // ── V2.6 令牌（docs/ui-hifi-mockups.html V2.6 / 线框图 V2.15，2026-09-16） ──
  //
  // 本轮把「全局背景 + 悬浮条语言」统一到所有页面：
  // 背景只剩一层右上角放射渐变；底部导航与详情/添加页的操作条共用同一套悬浮圆角条规格。

  /// 全局背景的右上角光晕（rgba(255,164,112,.52)，叠在 blushBg 上）
  static const bgGlow = Color(0x85FFA470);

  /// 光晕渐隐端（同色全透明）——光晕外圈必须淡到 0，否则会出现硬边圆环
  static const glowFade = Color(0x00FFA470);

  /// 底部导航条底：半透明白 .86（透出全局背景）
  static const navBarBg = Color(0xDBFFFFFF);

  /// 底部操作条条底：半透明白 .92（比导航条实一档——它托的是按钮，要保证对比度）
  static const actionBarBg = Color(0xEBFFFFFF);

  /// 悬浮条投影（rgba(150,90,70,.14)）
  static const barShadow = Color(0x24965A46);

  /// 悬浮条描边（rgba(255,255,255,.9)，给白底方块一圈极浅的高光边）
  static const floatHairline = Color(0xE6FFFFFF);

  /// 浅一档的高光边（rgba(255,255,255,.75)，水彩渐变卡片用）
  static const floatHairlineSoft = Color(0xBFFFFFFF);

  /// 悬浮卡片投影（rgba(150,90,70,.10) / 0 3px 12px）——搜索胶囊、提醒卡组
  static const floatCardShadow = Color(0x1A965A46);

  /// 稍重的悬浮卡片投影（rgba(150,90,70,.12) / 0 3px 9px）——水彩统计卡、分类大圆
  static const floatCardShadowStrong = Color(0x1F965A46);

  /// 中央添加钮投影（rgba(247,156,132,.45)）
  static const addFabShadow = Color(0x73F79C84);

  /// 主按钮投影（rgba(242,112,91,.35)）
  static const btnPrimaryShadow = Color(0x59F2705B);

  /// 导航条当前 Tab（珊瑚粉）
  static const navActive = Color(0xFFE8807F);

  /// 导航条未选中（暖棕）
  static const navInactive = Color(0xFF9A7C5C);

  /// 中央添加钮底色
  static const addFab = Color(0xFFF79C84);

  /// 首页问候语
  static const greetInk = Color(0xFF6B3B33);

  /// 首页副标题 / 日期
  static const greetSub = Color(0xFFB48D82);

  /// 问候语后面那颗小爱心
  static const greetHeart = Color(0xFFC98A79);

  /// 头部线描房子图标
  static const homeHouseIcon = Color(0xFF8E6E65);

  // ── 首页竖排统计高卡（4 张，粉 / 绿 / 蓝 / 紫水彩渐变底） ──
  /// 卡内数字与线性图标色（与各自渐变底同色系深色）
  static const statHighPinkFg = Color(0xFFD9534A);
  static const statHighGreenFg = Color(0xFF3E9B5B);
  static const statHighBlueFg = Color(0xFF3F7DC0);
  static const statHighPurpleFg = Color(0xFF7B5FC7);
  /// 卡内标签（统一暖灰）
  static const statHighLabel = Color(0xFF6F5A52);
  /// 四张渐变底（158deg，三档：浓 → 中 → 几乎白）
  static const statHighPink = [Color(0xFFF9D5D1), Color(0xFFFCEBE6), Color(0xFFFDF7F3)];
  static const statHighGreen = [Color(0xFFD3E7CE), Color(0xFFEAF3E6), Color(0xFFF6FAF3)];
  static const statHighBlue = [Color(0xFFD0E0F0), Color(0xFFE8F0F8), Color(0xFFF4F8FC)];
  static const statHighPurple = [Color(0xFFDED4F1), Color(0xFFEEE9F8), Color(0xFFF8F5FC)];

  // ── 首页分类大圆的 pastel 渐变底（粉 / 蓝 / 绿 / 紫轮转） ──
  static const catPink = [Color(0xFFF6CBC6), Color(0xFFFCEAE6)];
  static const catBlue = [Color(0xFFCCDEF1), Color(0xFFEBF2F9)];
  static const catGreen = [Color(0xFFD0E7CB), Color(0xFFEBF4E8)];
  static const catPurple = [Color(0xFFDACFF0), Color(0xFFEFEAF9)];
  /// 分类标签文字
  static const catLabel = Color(0xFF5C4740);

  // ── 首页提醒卡组 ──
  /// 行间细分割线
  static const reminderDivider = Color(0xFFF7EAE4);
  /// 右侧日期（三级文字）
  static const reminderDate = Color(0xFFC3ABA4);
  /// 状态小字三档
  static const reminderDanger = Color(0xFFD9534A);
  static const reminderWarn = Color(0xFFE0764F);
  static const reminderMuted = Color(0xFF9A817B);
}