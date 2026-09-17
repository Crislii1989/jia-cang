# UI 统一规则清单（v2 · 2026-09-17）

> 本清单是全库页面 UI 的**唯一标准**。新页面按此写；改动旧页面时顺手对齐；审计以此为准。
> 违反任意一条都算回归，评审时直接打回。
>
> v2 新增：**外观皮肤（配色方案）系统**——颜色令牌从常量变成「跟随当前皮肤」，
> 见第 2 节的 2.5~2.7。写新页面前务必读这三条。

## 1. 布局与缩放

| # | 规则 | 落地物 |
|---|------|--------|
| 1.1 | 新页面尺寸一律经 `DesignMetrics.of(context)` 比例缩放（设计稿 320 机型），**禁止写死 px**。存量页面固定像素是已知债务，只约束新代码 | `lib/constants/design_metrics.dart` |
| 1.2 | 宽视口靠 `AppCanvas` 限宽 430，不逐页自写限宽 | `lib/widgets/app_canvas.dart` |
| 1.3 | ListView 页横向边距**只允许一处**：各 section 自带 pageMargin，ListView 本体只留垂直 padding | — |
| 1.4 | 滚动区（垂直无界）里的 Column 子树**禁止 Expanded/Flexible**，用固定高 SizedBox | — |
| 1.5 | 圆角卡片有子内容顶边（色条/头图）必须 `clipBehavior: Clip.antiAlias` | — |

## 2. 色彩

| # | 规则 | 落地物 |
|---|------|--------|
| 2.1 | 颜色一律取 `AppColors` 令牌，**禁止手写 `Color(0x…)` 字面量**（等于既有令牌值的直接替换，新色先加令牌再用） | `lib/constants/app_colors.dart` |
| 2.2 | 按钮芯片只用「按钮色彩」令牌段；主按钮实心珊瑚无渐变 | — |
| 2.3 | 身份色保留项不算违规：分类身份色、房间身份色、订单平台品牌渐变、收纳层级三色 | — |
| 2.4 | 涨红跌绿等市场配色约定不适用于本应用（非金融场景） | — |
| 2.5 | **AppColors 的动态令牌跟随皮肤**（品牌/中性面/文字三级/描边/阴影/装饰），语义色与身份色固定不变。新增动态令牌必须：① 在 `app_colors.dart` 里写成 getter 并给出派生公式 `_t(SkinTokens.x, 派生值)`；② 在 `SkinTokens` 加同名 key。**动态令牌不能进 `const` 表达式**（写 `final` 或在 build 里取） | `app_colors.dart` / `app_skin.dart` |
| 2.6 | **新增路由必须在 `app_router.dart` 用 `_skinKeyed('tag', page)` 包一层**。原因：`const XxxPage()` 在祖辈重建时会被 Element 复用（同实例直接短路、连 build 都不调），不换 key 就换不了色 | `lib/app_router.dart` |
| 2.7 | 默认皮肤 `AppSkins.coral` 的 exact 表 = 改造前的精确取值，**改它等于改全局默认外观**，必须先对设计稿 | `lib/constants/app_skin.dart` |

## 3. 组件复用

| # | 规则 | 落地物 |
|---|------|--------|
| 3.1 | 弹窗一律 `showCenterSheet` + `CenterSheetSurface`（居中、四角圆角 24）；页面内 setState 控制的浮层用 `CenterModalShell`；**禁止手写 AlertDialog/showModalBottomSheet**。⚠️ `showCenterSheet` 只负责居中/圆角/遮罩，**内边距要自己用 `CenterSheetSurface` 垫**，否则内容贴边被圆角切 | `lib/widgets/center_sheet.dart` |
| 3.2 | 确认/提示类对话框一律 `CenterSheetConfirm.show`（取消 ghost + 确认 primary，危险动作 `danger: true`） | `lib/widgets/center_sheet.dart` |
| 3.3 | 底部悬浮操作条一律 `FloatingBar` + `FloatingBarButton`（sideInset 14 / 高 60 / 按钮 40 / 圆角 20）；确认/取消、主要/次要/危险用 tone 区分 | `lib/widgets/floating_bar.dart` |
| 3.4 | Toast 一律 `ToastUtils.show`，**禁止 SnackBar** | `lib/widgets/toast_utils.dart` |
| 3.5 | emoji 文字一律 `EmojiText`；图标选择一律 `EmojiPickerField`；胶囊「图标+文字」用 `PillContent`（内容组整体居中） | widgets |
| 3.6 | 背景只有一层 `GradientBackground` 右上暖光晕；页面**禁止再画装饰色斑、禁止 BackdropFilter/毛玻璃** | `lib/widgets/gradient_background.dart` |
| 3.7 | 取色器一律 `ColorPickerSheet.show`（自绘 HSV，不引第三方包）；皮肤缩略图一律 `SkinPreview`（在固定 120×160 设计空间里画，外层用 FittedBox 缩放） | widgets |

## 4. 文案与细节

| # | 规则 |
|---|------|
| 4.1 | 状态中文映射唯一来源：safe→在库 / lent→借出 / lost→丢失 / used→已用（与 inventory_page `_statusLabels` 同源，别各写各的） |
| 4.2 | 破坏性动作文案统一「确定删除「名字」？此操作不可撤销/恢复。」句式 |
| 4.3 | 排序文案唯一来源 `sort_type.dart`（kSortLabels / kSortFullLabels）；排序 chip 默认文案「排序」 |

## 5. 统一动作记录

### 2026-09-17（外观皮肤系统）
- **引入皮肤（配色方案）系统**：7 个锚点色（主色/页面底色/卡片底/主文字/次文字/分割线/光晕）+ 派生令牌；
  内置 6 套（暖粉珊瑚为默认，像素级等于改造前），用户可新建/编辑/删除自定义配色，
  入口在「我的 → 设置 → 外观」，存 SharedPreferences（`SkinStore`）。
- 全库约 450 处 `const` 因动态令牌被拆除（这是换肤的必要代价）。
- 弹窗统一：12 处裸 `AlertDialog`（storage ×6 / category / ai_settings / data_backup ×2 / db_gate / check_update）全部迁入 `CenterSheetConfirm` / `showCenterSheet` 外壳。
- 色彩统一：6 个文件手写的 `Color(0xFFF0E4D0)` 归位 `AppColors.border`；`Color(0xBFFFFFFF)` 归位 `AppColors.floatHairlineSoft`。
- 死代码清理：22 个零引用文件 + 7 个零引用符号删除（详见 commit）。

## 6. 存量债务（不阻塞统一标准，挂账待拍板）

- 老页面（storage/me 部分区块）仍用固定 px，未过 `DesignMetrics`。
- 「对齐/居中」类视觉反馈先用 widget test 量（tester.getRect），再动代码。
- lint：12 条 `unnecessary_underscores` info 级风格提示，可随下一次触碰相关文件时顺手清。
- 外观页尚未画进 `ui-hifi-mockups.html` / `ui-redesign-wireframes.html`（两份设计稿还是 v2.7，没有 S6 外观页）。
- 深色系皮肤没做：派生规则假设「浅底 + 深字」，深色底要另一套对比度约束。
