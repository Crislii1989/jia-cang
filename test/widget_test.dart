import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/category.dart';
import 'package:jia_cang/providers/category_provider.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/screen/home/home_page.dart';

void main() {
  testWidgets('HomePage renders correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 首页概览四卡的数据源（V2.0）：直接覆盖叶子 provider，避免触碰真实数据库
          itemCountProvider.overrideWith((ref) => 3),
          expiringSoonCountProvider.overrideWith((ref) => 1),
          lentCountProvider.overrideWith((ref) => 0),
          idleCountProvider.overrideWith((ref) => 2),
          // 提醒流：无提醒时走空态
          homeRemindersProvider.overrideWith((ref) => []),
          availableCategoriesProvider.overrideWith(
            (ref) => const [Category('food', '餐厨', emoji: '🍳')],
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // 问候语（默认昵称小橘）
    expect(find.textContaining('小橘'), findsOneWidget);
    // 竖排统计迷你卡四张（V2.0 新形态）
    expect(find.text('物品总数'), findsOneWidget);
    expect(find.text('即将到期'), findsOneWidget);
    expect(find.text('出借中'), findsOneWidget);
    expect(find.text('长期闲置'), findsOneWidget);
    // 无提醒时的空态
    expect(find.text('一切妥当，暂无待处理提醒'), findsOneWidget);
  });
}

