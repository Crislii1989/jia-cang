import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jia_cang/app_router.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/app_skin.dart';
import 'package:jia_cang/providers/skin_provider.dart';
import 'package:jia_cang/screen/me/appearance_edit_page.dart';
import 'package:jia_cang/screen/me/appearance_page.dart';
import 'package:jia_cang/services/skin_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 复刻 `MyApp` 的换肤重建链路：watch 皮肤版本号 → 重建 `MaterialApp.router`
/// → 各路由 builder 重跑 → [AppColors.skinRevision] 变化让页面 key 变化 →
/// 当前页整体重新挂载。
///
/// 少了这一层包壳，测试就绕开了真实环境里最要命的那段时序——「保存的一瞬间，
/// 正在发起保存的那一页自己正被换掉」。这正是「保存后停在编辑页」那个 bug 的根源。
class _SkinRebuildHarness extends ConsumerWidget {
  final GoRouter router;

  const _SkinRebuildHarness({required this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(skinManagerProvider.select((s) => s.revision));
    return MaterialApp.router(routerConfig: router);
  }
}

/// 外观皮肤系统（2026-09-17）的回归测试。
///
/// 重点锁三件事：
/// 1. **默认皮肤不许改观感**——[AppSkins.coral] 的 exact 表必须等于设计稿基准的
///    精确取值，改了就等于改全局默认外观；
/// 2. **换皮肤只换该换的**——品牌/中性/文字随锚点走，语义色（危险/成功）
///    与身份色（状态绿蓝）必须纹丝不动；
/// 3. **自定义皮肤的增删改落盘**，删掉正在用的那套要回落默认。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // 每个用例从「默认皮肤 + 无自定义」开始：SkinStore 是静态状态，会跨用例残留
    AppColors.applySkin(AppSkins.coral);
    await SkinStore.load();
  });

  group('默认皮肤 = 设计稿基准的精确取值', () {
    test('品牌色与中性面', () {
      expect(AppColors.coral, const Color(0xFFF2705B));
      expect(AppColors.coralDeep, const Color(0xFFDD5B46));
      expect(AppColors.coralSoft, const Color(0xFFFFE9E2));
      expect(AppColors.blushBg, const Color(0xFFFBF3EE));
      expect(AppColors.background, const Color(0xFFFBF3EE));
      expect(AppColors.cardBg, Colors.white);
      expect(AppColors.bgGlow, const Color(0x85FFA470));
    });

    test('文字三级与描边', () {
      expect(AppColors.textPrimary, const Color(0xFF3D2B1F));
      expect(AppColors.blushInk, const Color(0xFF4A3733));
      expect(AppColors.blushInk2, const Color(0xFF9A817B));
      expect(AppColors.blushInk3, const Color(0xFFC3ABA4));
      expect(AppColors.blushLine, const Color(0xFFF3DED7));
      expect(AppColors.border, const Color(0xFFF0E4D0));
    });

    test('按钮与导航条令牌', () {
      expect(AppColors.btnPrimaryBg, const Color(0xFFF2705B));
      expect(AppColors.btnPrimaryFg, Colors.white);
      expect(AppColors.btnSoftFg, const Color(0xFFDD5B46));
      expect(AppColors.chipSelectedBg, const Color(0xFFF2705B));
      expect(AppColors.navActive, const Color(0xFFE8807F));
      expect(AppColors.navInactive, const Color(0xFF9A7C5C));
      expect(AppColors.addFab, const Color(0xFFF79C84));
      expect(AppColors.navBarBg, const Color(0xDBFFFFFF));
      expect(AppColors.actionBarBg, const Color(0xEBFFFFFF));
    });

    test('详情页沉浸大图渐变', () {
      expect(AppColors.heroGradient, const [
        Color(0xFFFFB9A5),
        Color(0xFFF2705B),
        Color(0xFFDD5B46),
      ]);
    });

    test('isDefault 只认默认皮肤', () {
      expect(AppSkins.coral.isDefault, isTrue);
      expect(AppSkins.mint.isDefault, isFalse);
      expect(AppSkins.builtIns.length, 6);
      expect(AppSkins.builtIns.first.id, AppSkins.defaultId);
    });
  });

  group('换皮肤：该变的变，不该变的不变', () {
    test('锚点色与派生令牌跟随新皮肤', () {
      AppColors.applySkin(AppSkins.mint);
      expect(AppColors.coral, AppSkins.mint.primary);
      expect(AppColors.blushBg, AppSkins.mint.bg);
      expect(AppColors.blushInk, AppSkins.mint.ink);
      // 派生：白色卡底、半透明导航条底
      expect(AppColors.cardBg, AppSkins.mint.cardBg);
      expect(AppColors.navBarBg.a, closeTo(0.86, 0.01));
      // 派生：按钮软底 = 主色与卡底混合，一定比主色浅
      expect(
        AppColors.coralSoft.computeLuminance(),
        greaterThan(AppSkins.mint.primary.computeLuminance()),
      );
      // 派生：主色加深要更深
      expect(
        AppColors.coralDeep.computeLuminance(),
        lessThan(AppSkins.mint.primary.computeLuminance()),
      );
    });

    test('语义色与身份色不随皮肤变', () {
      final dangerBefore = AppColors.danger;
      final successBefore = AppColors.success;
      final safeGreenBefore = AppColors.safeGreen;
      final alertBefore = AppColors.alertRed;
      final statPeachBefore = AppColors.statPeach;

      AppColors.applySkin(AppSkins.lilac);

      expect(AppColors.danger, dangerBefore);
      expect(AppColors.success, successBefore);
      expect(AppColors.safeGreen, safeGreenBefore);
      expect(AppColors.alertRed, alertBefore);
      expect(AppColors.statPeach, statPeachBefore);
    });

    test('applySkin 会推进皮肤版本号（路由换 key 的依据）', () {
      final before = AppColors.skinRevision;
      AppColors.applySkin(AppSkins.mist);
      expect(AppColors.skinRevision, before + 1);
    });

    test('派生皮肤的非法渐变回落到锚点派生值', () {
      AppColors.applySkin(AppSkins.mist);
      expect(AppColors.heroGradient.length, 3);
      expect(AppColors.heroGradient[1], AppSkins.mist.primary);
    });
  });

  group('AppSkin 序列化', () {
    test('toJson / fromJson 往返一致', () {
      final src = AppSkins.draftFrom(AppSkins.caramel, name: '焦糖 2 号');
      final back = AppSkin.fromJson(src.toJson());
      expect(back.id, src.id);
      expect(back.name, '焦糖 2 号');
      expect(back.primary, src.primary);
      expect(back.bg, src.bg);
      expect(back.cardBg, src.cardBg);
      expect(back.ink, src.ink);
      expect(back.ink2, src.ink2);
      expect(back.line, src.line);
      expect(back.glow, src.glow);
      expect(back.builtIn, isFalse);
    });

    test('坏数据不抛异常，回落到默认皮肤的值', () {
      final back = AppSkin.fromJson({'id': 'custom_x', 'primary': '不是颜色'});
      expect(back.primary, AppSkins.coral.primary);
      expect(back.bg, AppSkins.coral.bg);
    });

    test('自定义皮肤 id 唯一且带 custom_ 前缀', () {
      final a = AppSkins.draftFrom(AppSkins.coral, name: 'A');
      final b = AppSkins.blankDraft(name: 'B');
      expect(a.id, startsWith('custom_'));
      expect(b.id, startsWith('custom_'));
      expect(a.id == b.id, isFalse);
    });
  });

  group('SkinStore 持久化', () {
    test('新增自定义皮肤后可读回，并能切换为当前', () async {
      final skin = AppSkins.draftFrom(AppSkins.coral, name: '夜色');
      await SkinStore.upsertCustom(skin);
      await SkinStore.setActive(skin);

      expect(SkinStore.custom.length, 1);
      expect(SkinStore.active.id, skin.id);
      expect(AppColors.coral, skin.primary);
    });

    test('删除当前皮肤会回落到默认', () async {
      final skin = AppSkins.draftFrom(AppSkins.coral, name: '待删');
      await SkinStore.upsertCustom(skin);
      await SkinStore.setActive(skin);
      await SkinStore.deleteCustom(skin.id);

      expect(SkinStore.custom, isEmpty);
      expect(SkinStore.active.id, AppSkins.defaultId);
      expect(AppColors.coral, AppSkins.coral.primary);
    });

    test('删除非当前皮肤不影响当前皮肤', () async {
      final keep = AppSkins.draftFrom(AppSkins.coral, name: '保留');
      final drop = AppSkins.draftFrom(AppSkins.coral, name: '丢弃');
      await SkinStore.upsertCustom(keep);
      await SkinStore.upsertCustom(drop);
      await SkinStore.setActive(keep);
      await SkinStore.deleteCustom(drop.id);

      expect(SkinStore.custom.length, 1);
      expect(SkinStore.active.id, keep.id);
    });
  });

  group('外观页', () {
    /// 默认测试视口只有 800×600，ListView 是懒加载的——「我的配色」「新建一套
    /// 配色」在视口之外，压根不会被 build，断言必然找不到。给一块足够高的屏幕。
    Future<void> pumpAppearance(WidgetTester tester) async {
      tester.view.physicalSize = const Size(430 * 2, 2600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AppearancePage())),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('列出 6 套预置配色与新建入口', (tester) async {
      await pumpAppearance(tester);

      for (final s in AppSkins.builtIns) {
        expect(find.text(s.name), findsWidgets);
      }
      expect(find.text('新建一套配色'), findsOneWidget);
      expect(find.text('预置配色'), findsOneWidget);
      expect(find.text('我的配色'), findsOneWidget);
    });

    testWidgets('点第 2 套预置配色后全局配色跟随', (tester) async {
      await pumpAppearance(tester);
      expect(AppColors.coral, AppSkins.coral.primary);

      await tester.tap(find.text(AppSkins.mint.name).first);
      await tester.pumpAndSettle();

      expect(AppColors.coral, AppSkins.mint.primary);
      expect(AppColors.blushBg, AppSkins.mint.bg);

      // 换肤会弹一句 Toast，它内部是 2 秒后移除的定时器：不把它跑完，
      // 测试结束时会报 `A Timer is still pending`。
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('自定义皮肤为空时给出提示', (tester) async {
      await pumpAppearance(tester);
      expect(find.textContaining('还没有自定义配色'), findsOneWidget);
    });
  });

  group('新建配色 → 保存并应用', () {
    /// 走**真实路由**（[createAppRouter]）而不是直接 pump 一个页面：
    /// `_save` 里那句 `context.pop()` 只有在真实路由栈上才有意义。
    ///
    /// ⚠️ 覆盖边界：这条用例锁的是「保存这条链路的整体行为」（能落盘、能生效、
    /// 能回到列表、不抛异常），**不是** `_save` 内部那句「先 pop 再落盘」的顺序。
    /// 顺序问题在 widget test 里复现不出来——测试里的 SharedPreferences 是内存
    /// mock，await 全在微任务里跑完，帧还没机会插进来；而浏览器端的真存储是跨
    /// 事件循环的异步，换肤引发的重挂载正好能落在 await 中间。所以顺序那条
    /// 只能在真实浏览器里验（见 `.workbuddy/verify/2026-09-17/` 的 E2E 记录）。
    testWidgets('保存后回到列表、落盘并生效，且不抛异常', (tester) async {
      tester.view.physicalSize = const Size(430 * 2, 2600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final router = createAppRouter(initialLocation: '/appearance');
      await tester.pumpWidget(
        ProviderScope(child: _SkinRebuildHarness(router: router)),
      );
      await tester.pumpAndSettle();
      expect(find.text('我的配色'), findsOneWidget);

      router.push(
        '/appearance-edit',
        extra: AppearanceEditArgs(
          skin: AppSkins.draftFrom(AppColors.skin, name: '测试配色'),
          isNew: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('新建配色'), findsOneWidget);
      expect(find.text('保存并应用'), findsOneWidget);

      await tester.tap(find.text('保存并应用'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('新建配色'), findsNothing, reason: '保存后应已离开编辑页');
      expect(find.text('我的配色'), findsOneWidget, reason: '应回到外观列表');
      expect(find.text('测试配色'), findsWidgets, reason: '新配色应出现在列表里');

      expect(SkinStore.custom.length, 1);
      expect(SkinStore.active.id, SkinStore.custom.first.id, reason: '新建即应用');
      expect(find.text('自定义'), findsOneWidget, reason: '当前配色应标为自定义');

      // Toast 内部有 2 秒定时器，不跑完会报 `A Timer is still pending`
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
