import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/widgets/overview_stat_card.dart';
import 'package:jia_cang/widgets/status_badge.dart';

void main() {
  group('OverviewStatCard（统计概览卡）', () {
    testWidgets('渲染数字/单位/标签与图标', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OverviewStatCard(
              emoji: '📦',
              label: '物品总数',
              value: 128,
              unit: '件',
            ),
          ),
        ),
      );

      expect(find.text('128'), findsOneWidget);
      expect(find.text('件'), findsOneWidget);
      expect(find.text('物品总数'), findsOneWidget);
      // emoji 经 EmojiText 渲染（项目规范：禁止裸 Text(emoji)）
      expect(find.byEmojiText('📦'), findsOneWidget);
    });

    testWidgets('默认态为白底、hot 态为浅金底', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OverviewStatCard(emoji: '📦', label: '物品总数', value: 1),
                OverviewStatCard(
                  emoji: '⏰',
                  label: '即将到期',
                  value: 5,
                  highlighted: true,
                ),
              ],
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      );
      final decorations = containers
          .map((c) => c.decoration! as BoxDecoration)
          .toList();
      // 第一张：白底普通卡
      expect(
        decorations.any(
          (d) => d.color == AppColors.cardBg && d.border!.top.color == AppColors.border,
        ),
        isTrue,
      );
      // 第二张：浅金 hot 卡
      expect(
        decorations.any(
          (d) =>
              d.color == AppColors.goldSoft &&
              d.border!.top.color == AppColors.goldSoftBorder,
        ),
        isTrue,
      );
    });

    testWidgets('点击触发 onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewStatCard(
              emoji: '📦',
              label: '物品总数',
              value: 1,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('物品总数'));
      expect(tapped, isTrue);
    });
  });

  group('StatusBadge（状态徽标）', () {
    testWidgets('渲染文本且各类型使用对应状态色', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(text: '在库', type: BadgeType.ok),
                StatusBadge(text: '出借中', type: BadgeType.info),
                StatusBadge(text: '3 天后到期', type: BadgeType.warn),
                StatusBadge(text: '已逾期 2 天', type: BadgeType.danger),
                StatusBadge(text: '闲置 90+ 天', type: BadgeType.muted),
              ],
            ),
          ),
        ),
      );

      expect(find.text('在库'), findsOneWidget);
      expect(find.text('出借中'), findsOneWidget);
      expect(find.text('3 天后到期'), findsOneWidget);
      expect(find.text('已逾期 2 天'), findsOneWidget);
      expect(find.text('闲置 90+ 天'), findsOneWidget);

      Color? bgOf(String text) {
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text(text),
            matching: find.byType(Container),
          ).first,
        );
        return (container.decoration! as BoxDecoration).color;
      }

      expect(bgOf('在库'), AppColors.safeGreenBg);
      expect(bgOf('出借中'), AppColors.lendBlueBg);
      // V2.0：临期改珊瑚浅底、闲置改暖桃浅底（对齐水彩粉新色板）
      expect(bgOf('3 天后到期'), AppColors.coralSoft);
      expect(bgOf('已逾期 2 天'), AppColors.alertRedBg);
      expect(bgOf('闲置 90+ 天'), AppColors.statPeachBg);
    });
  });
}

/// 按 EmojiText.emoji 定位（同 emoji_picker_field_test 的做法）
extension EmojiTextFinder on CommonFinders {
  Finder byEmojiText(String emoji) {
    return find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'EmojiText' &&
          (w as dynamic).emoji == emoji,
    );
  }
}
