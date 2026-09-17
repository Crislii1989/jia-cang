import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/widgets/center_sheet.dart';
import 'package:jia_cang/widgets/floating_bar.dart';

/// 统一确认弹窗的契约测试（UI 统一规则 3.2）：
/// 标题/说明居中、取消 ghost + 确认 primary（danger 时红字），
/// 确认返回 result，取消/点遮罩返回 null。
void main() {
  Future<void> openDialog(
    WidgetTester tester, {
    bool danger = false,
    String? cancelLabel = '取消',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => CenterSheetConfirm.show<bool>(
                context: context,
                title: '删除房间',
                message: '确定删除「卧室」？此操作不可撤销。',
                confirmLabel: '删除',
                cancelLabel: cancelLabel,
                danger: danger,
                result: true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('普通确认：取消 ghost + 确认 primary，确认返回 true', (tester) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                confirmed = await CenterSheetConfirm.show<bool>(
                  context: context,
                  title: '删除房间',
                  message: '确定删除「卧室」？此操作不可撤销。',
                  confirmLabel: '删除',
                  result: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('删除房间'), findsOneWidget);
    expect(find.text('确定删除「卧室」？此操作不可撤销。'), findsOneWidget);
    // 两颗胶囊按钮
    expect(find.byType(FloatingBarButton), findsNWidgets(2));
    final tones = tester
        .widgetList<FloatingBarButton>(find.byType(FloatingBarButton))
        .map((b) => b.tone)
        .toList();
    expect(tones, contains(FloatingBarTone.ghost));
    expect(tones, contains(FloatingBarTone.primary));

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('危险确认：确认按钮为 danger tone；取消返回 null', (tester) async {
    bool? confirmed = true; // 预置非空，取消后应变 null
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                confirmed = await CenterSheetConfirm.show<bool>(
                  context: context,
                  title: '删除房间',
                  confirmLabel: '删除',
                  danger: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final confirmBtn = tester
        .widgetList<FloatingBarButton>(find.byType(FloatingBarButton))
        .firstWhere((b) => b.label == '删除');
    expect(confirmBtn.tone, FloatingBarTone.danger);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(confirmed, isNull);
  });

  testWidgets('单按钮提示：cancelLabel 传 null 只渲染一颗按钮', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => CenterSheetConfirm.show(
                context: context,
                title: '无法删除',
                message: '请先迁移物品。',
                confirmLabel: '我知道了',
                cancelLabel: null,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingBarButton), findsOneWidget);
    expect(find.text('我知道了'), findsOneWidget);
  });
}
