import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/providers/item_providers.dart';
import 'package:jia_cang/screen/home_page.dart';

void main() {
  testWidgets('HomePage renders correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemCountProvider.overrideWith((ref) => 3),
          weeklyNewCountProvider.overrideWith((ref) => 2),
          monthlyNewCountProvider.overrideWith((ref) => 5),
          recentItemsProvider.overrideWith((ref) => [
            Item(
              id: '1',
              name: '测试物品',
              location: '客厅',
              createdAt: DateTime(2026, 9, 1),
            ),
          ]),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // 问候语（默认昵称小橘）
    expect(find.textContaining('小橘'), findsOneWidget);
    // 数据卡片
    expect(find.text('物品总数'), findsOneWidget);
    expect(find.text('本月新增'), findsOneWidget);
  });
}
