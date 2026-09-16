import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/widgets/emoji_picker_field.dart';
import 'package:jia_cang/widgets/emoji_text.dart';

/// EmojiPickerField 是「选择图标」的下拉字段选择器，所有收纳空间 / 分类 /
/// 头像的图标选择都走它。这里锁住五条契约：
/// 1. 收起时是紧凑下拉字段：只显示当前图标 + 展开箭头，不铺开候选宫格；
/// 2. 点击字段弹出选图面板，面板里只显示图标、不显示中文名；
/// 3. 点按某个图标即选中并收起，回调回来的是 emoji 本身；
/// 4. 候选库已扩容且每个库内部无重复；
/// 5. 历史遗留图标（不在候选库里）作为「当前使用」置顶，避免选不回来。
void main() {
  /// 用少量候选做交互测试：全部同屏可见，避免宫格滚动影响点击命中。
  const smallOptions = [
    EmojiOption('🛋️', '沙发'),
    EmojiOption('🛏️', '床'),
    EmojiOption('📺', '电视'),
  ];

  /// 按 emoji 精确定位图标。
  Finder emojiCell(String emoji) => find.byWidgetPredicate(
        (w) => w is EmojiText && w.emoji == emoji,
      );

  /// 模拟真实调用方：宿主持有选中值、回调里 setState 重建
  /// （EmojiPickerField 是受控组件，字段上的图标由外部 value 驱动）。
  Future<void> pumpPicker(
    WidgetTester tester, {
    required String value,
    required List<EmojiOption> options,
    ValueChanged<String>? onChanged,
  }) async {
    var selected = value;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => EmojiPickerField(
                value: selected,
                options: options,
                onChanged: (v) {
                  selected = v;
                  onChanged?.call(v);
                  setState(() {});
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('收起时是紧凑下拉字段，不铺开候选宫格', (tester) async {
    await pumpPicker(
      tester,
      value: '🛋️',
      options: smallOptions,
    );
    await tester.pumpAndSettle();

    // 字段上只有当前图标一个 EmojiText，候选没有铺开
    expect(emojiCell('🛋️'), findsOneWidget);
    expect(emojiCell('🛏️'), findsNothing);
    expect(emojiCell('📺'), findsNothing);
    // 字段不显示中文名
    expect(find.text('沙发'), findsNothing);
    expect(find.byType(EmojiPickerField), findsOneWidget);
  });

  testWidgets('点字段弹出面板，点选图标回调并收起', (tester) async {
    String? picked;
    await pumpPicker(
      tester,
      value: '🛋️',
      options: smallOptions,
      onChanged: (v) => picked = v,
    );
    await tester.pumpAndSettle();

    // 打开面板
    await tester.tap(find.byType(EmojiPickerField));
    await tester.pumpAndSettle();
    expect(find.text('选择图标'), findsOneWidget);
    // 面板里候选铺开，且只显示图标、不显示中文名
    expect(emojiCell('🛏️'), findsOneWidget);
    expect(find.text('床'), findsNothing);

    // 点按「床」格 -> 回调拿到该格 emoji，面板自动收起
    await tester.tap(emojiCell('🛏️'));
    await tester.pumpAndSettle();

    expect(picked, '🛏️');
    expect(find.text('选择图标'), findsNothing);
    // 收起后字段上的当前图标已更新
    expect(emojiCell('🛏️'), findsOneWidget);
    expect(emojiCell('🛋️'), findsNothing);
  });

  testWidgets('候选库已扩容且每个库内部无重复', (tester) async {
    expect(kSpaceEmojiOptions.length, greaterThanOrEqualTo(60));
    expect(kCategoryEmojiOptions.length, greaterThanOrEqualTo(50));
    expect(kAvatarEmojiOptions.length, greaterThanOrEqualTo(30));

    for (final list in [
      kSpaceEmojiOptions,
      kCategoryEmojiOptions,
      kAvatarEmojiOptions,
    ]) {
      final set = list.map((o) => o.emoji).toSet();
      expect(set.length, list.length,
          reason: '候选库 ${list.length} 项，去重后仅 ${set.length} 个 emoji');
    }
  });

  testWidgets('历史遗留图标（不在候选库里）作为「当前使用」置顶', (tester) async {
    await pumpPicker(
      tester,
      value: '🦖',
      options: smallOptions,
    );
    await tester.pumpAndSettle();

    // 打开面板检查候选顺序
    await tester.tap(find.byType(EmojiPickerField));
    await tester.pumpAndSettle();

    final emojis =
        tester.widgetList<EmojiText>(find.byType(EmojiText)).map((e) => e.emoji);
    // 不在候选库里的老图标被前置到第一位
    expect(emojis.first, '🦖');
    // 原候选库仍然可用
    expect(emojis, contains('🛋️'));
  });
}
