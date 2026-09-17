import 'package:flutter/material.dart';

/// 统一尺寸常量
class AppDimensions {
  AppDimensions._();

  // ── 页面边距 ──
  static const double pageMarginHorizontal = 20;
  static const double pageMarginVertical = 12;

  // ── 卡片内边距 ──
  static const double cardPadding = 14;
  static const double cardPaddingLarge = 16;

  // ── 圆角 ──
  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 12;
  static const double borderRadiusLarge = 16;
  static const double borderRadiusExtraLarge = 18;
  static const double borderRadiusXLarge = 24;

  // ── 间距 ──
  static const double spacingExtraSmall = 4;
  static const double spacingSmall = 8;
  static const double spacingMedium = 12;
  static const double spacingLarge = 16;
  static const double spacingExtraLarge = 20;
  static const double spacingXXLarge = 24;

  // ── 图标尺寸 ──
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 24;
  static const double iconSizeLarge = 28;
  static const double iconSizeExtraLarge = 64;

  // ── 容器尺寸 ──
  static const double avatarSize = 44;
  static const double iconContainerSmall = 48;
  static const double iconContainerMedium = 52;
  static const double addButtonSize = 56;

  // ── 阴影 ──
  static const double shadowBlurSmall = 10;
  static const double shadowBlurMedium = 12;
  static const double shadowBlurLarge = 20;
  static const double shadowBlurExtraLarge = 48;

  // ── 常用 EdgeInsets ──
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageMarginHorizontal,
  );

  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);
  static const EdgeInsets cardPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: cardPaddingLarge,
    vertical: cardPadding,
  );

  // ── 常用 BoxConstraints ──
  static const BoxConstraints iconConstraints = BoxConstraints(
    minWidth: iconContainerSmall,
    maxWidth: iconContainerSmall,
    minHeight: iconContainerSmall,
    maxHeight: iconContainerSmall,
  );

  // ── 信息板三级行高（UI 改版定稿，全局统一） ──
  /// 小号：搜索条等工具型输入，34
  static const double rowHeightSmall = 34;
  /// 标准：普通信息板（列表 cell / 表单字段 / 入口行），40
  static const double rowHeightNormal = 40;
  /// 统计概览卡（图标块 40 + 双行文字），60
  static const double statCardHeight = 60;
  /// 统计卡图标块尺寸
  static const double statCardTileSize = 40;

  // ── S3 详情页 / S4 添加页（高保真稿 V2.6，2026-09-16 落地） ──
  //
  // 下面这些都是**设计稿（320 机型 / 内容宽 292）的绝对值**。
  // 落地时必须经 `DesignMetrics.of(context)` 换算后再用（`值 * k`），
  // 不要把常量直接当像素用——否则宽视口下又会横向拉伸。
  // 例外见 [delKnobSize] / [delKnobBottom] 的注释。

  /// 详情页沉浸大图：高度 / 圆角
  static const double heroHeight = 158;
  static const double heroRadius = 16;

  /// 大图上的返回圆钮：直径 / 距大图左上内缩（稿子 .icon-btn 30 + top/left 10）
  static const double heroBackSize = 30;
  static const double heroBackInset = 10;

  /// 大图底部轮播点：激活点宽 / 点高 / 间距 / 距大图底
  static const double heroDotActiveWidth = 14;
  static const double heroDotSize = 4;
  static const double heroDotGap = 4;
  static const double heroDotBottom = 9;

  /// 信息组单行：普通信息行最小高 / 表单行最小高 / 表单行内距
  static const double infoRowMinHeight = 40;
  static const double formRowMinHeight = 44;
  static const double formRowPadding = 12;

  /// 表单行标签列宽（稿子 .f-cell .lb width:64）
  // 76：容纳最宽标签「存放位置」4 字 + 必填星号不换行（64 会把 4 字标签
  // 挤成两行，2026-09-17 反馈）
  static const double formLabelWidth = 76;

  /// 信息行内的小图标块：边长 / 圆角
  static const double cellIconTile = 26;
  static const double cellIconTileRadius = 8;

  /// 备注行高度（稿子 `.f-cell min-height:140px`，标签与值都顶部对齐）
  static const double noteRowHeight = 140;

  /// 照片块：边长 / 圆角（稿子 .photo-tile 72 / .photo-add height 72）
  static const double photoTileSize = 72;
  static const double photoTileRadius = 14;

  /// 详情页删除旋钮：直径。
  /// **不缩放**——稿子里它与底部条按钮等高（都是 40），而悬浮条本身是
  /// 固定 chrome（不随内容缩放），所以旋钮也保持原尺寸才不会与条脱节。
  static const double delKnobSize = 40;

  /// 删除旋钮距屏幕左边（与 `FloatingBar.sideInset` 14 对齐，稿子 `left:14px`）
  static const double delKnobInset = 14;

  /// 删除旋钮距屏幕底：悬浮条顶（bottomGap 8 + height 60 = 68）再留 8。
  /// **不缩放**，理由同 [delKnobSize]。
  static const double delKnobBottom = 76;
}