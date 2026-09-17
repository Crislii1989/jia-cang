import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/item.dart';
import 'package:jia_cang/models/reminder_entry.dart';
import 'package:jia_cang/providers/item_providers.dart';

/// 用内存数据替换 Items AsyncNotifier（绕过数据库依赖）
class _FakeItems extends Items {
  final List<Item> items;
  _FakeItems(this.items);

  @override
  Future<List<Item>> build() async => items;
}

Item item({
  required String id,
  String status = 'safe',
  DateTime? expiryDate,
  DateTime? createdAt,
  DateTime? lastTouchedAt,
}) {
  return Item(
    id: id,
    name: id,
    status: status,
    expiryDate: expiryDate,
    createdAt: createdAt ?? DateTime.now(),
    lastTouchedAt: lastTouchedAt,
  );
}

Future<ProviderContainer> containerOf(List<Item> items) async {
  final container = ProviderContainer(
    overrides: [itemsProvider.overrideWith(() => _FakeItems(items))],
  );
  await container.read(itemsProvider.future);
  return container;
}

void main() {
  final today = DateTime.now();
  DateTime dayOffset(int d) => DateTime(today.year, today.month, today.day + d);

  group('即将到期 / 已逾期 口径（V2.0 首页）', () {
    test('今天到期与 3 天内到期计入「即将到期」，不含已过期', () async {
      final c = await containerOf([
        item(id: 'today', expiryDate: dayOffset(0)),
        item(id: 'in3', expiryDate: dayOffset(3)),
        item(id: 'in5', expiryDate: dayOffset(5)),
        item(id: 'overdue', expiryDate: dayOffset(-1)),
      ]);
      addTearDown(c.dispose);

      expect(c.read(expiringSoonCountProvider), 2);
      expect(
        c.read(expiringSoonItemsProvider).map((i) => i.id).toSet(),
        {'today', 'in3'},
      );
    });

    test('已过期物品归入 overdue，且不计入即将到期', () async {
      final c = await containerOf([
        item(id: 'overdue2', expiryDate: dayOffset(-2)),
        item(id: 'overdue9', expiryDate: dayOffset(-9)),
      ]);
      addTearDown(c.dispose);

      expect(c.read(overdueItemsProvider).length, 2);
      expect(c.read(expiringSoonCountProvider), 0);
    });

    test('已用完 / 已丢失的物品不再催到期', () async {
      final c = await containerOf([
        item(id: 'used', status: 'used', expiryDate: dayOffset(-2)),
        item(id: 'lost', status: 'lost', expiryDate: dayOffset(1)),
      ]);
      addTearDown(c.dispose);

      expect(c.read(overdueItemsProvider), isEmpty);
      expect(c.read(expiringSoonItemsProvider), isEmpty);
    });
  });

  group('长期闲置 / 出借中 口径', () {
    test('闲置按最近接触满 180 天且在库', () async {
      final c = await containerOf([
        item(
          id: 'idle200',
          createdAt: today.subtract(const Duration(days: 200)),
        ),
        item(id: 'new10', createdAt: today.subtract(const Duration(days: 10))),
        // 已借出不算闲置
        item(
          id: 'lent200',
          status: 'lent',
          createdAt: today.subtract(const Duration(days: 200)),
        ),
      ]);
      addTearDown(c.dispose);

      expect(c.read(idleItemsProvider).map((i) => i.id), ['idle200']);
      expect(c.read(idleCountProvider), 1);
      expect(c.read(lentCountProvider), 1);
    });

    test('lastTouchedAt 优先于 createdAt（登记久但最近动过 → 不算闲置）', () async {
      final c = await containerOf([
        item(
          id: 'touched',
          createdAt: today.subtract(const Duration(days: 300)),
          lastTouchedAt: today.subtract(const Duration(days: 30)),
        ),
        item(
          id: 'untouched',
          createdAt: today.subtract(const Duration(days: 100)),
          lastTouchedAt: today.subtract(const Duration(days: 200)),
        ),
      ]);
      addTearDown(c.dispose);

      expect(c.read(idleItemsProvider).map((i) => i.id), ['untouched']);
    });
  });

  group('homeReminders 聚合与排序', () {
    test('按 逾期 → 临期 → 闲置 排序，并带出对应徽标文案', () async {
      final c = await containerOf([
        item(
          id: 'idle',
          createdAt: today.subtract(const Duration(days: 200)),
          lastTouchedAt: today.subtract(const Duration(days: 190)),
        ),
        item(id: 'soon', expiryDate: dayOffset(2)),
        item(id: 'over', expiryDate: dayOffset(-3)),
      ]);
      addTearDown(c.dispose);

      final list = c.read(homeRemindersProvider);
      expect(list.map((r) => r.kind).toList(), [
        ReminderKind.overdue,
        ReminderKind.expiring,
        ReminderKind.idle,
      ]);
      expect(list[0].badgeText, '已逾期 3 天');
      expect(list[1].badgeText, '2 天后到期');
      expect(list[2].badgeText, '闲置 190 天');
    });

    test('无任何异常物品时返回空列表（首页走空态）', () async {
      final c = await containerOf([item(id: 'normal')]);
      addTearDown(c.dispose);
      expect(c.read(homeRemindersProvider), isEmpty);
    });

    test('条数上限 4 条，超出部分不展示', () async {
      final c = await containerOf([
        for (int i = 1; i <= 6; i++) item(id: 'o$i', expiryDate: dayOffset(-i)),
      ]);
      addTearDown(c.dispose);
      expect(c.read(homeRemindersProvider).length, 4);
    });
  });
}
