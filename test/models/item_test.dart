import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/item.dart';

void main() {
  group('Item', () {
    final fixedDate = DateTime(2026, 9, 1);

    test('Item.create generates unique IDs', () {
      final item1 = Item.create(name: 'Test');
      final item2 = Item.create(name: 'Test');
      expect(item1.id, isNot(equals(item2.id)));
    });

    test('Item.create uses default values', () {
      final item = Item.create(name: 'Test');
      expect(item.location, '未知');
      expect(item.status, 'safe');
      expect(item.categoryKey, '');
      expect(item.expiryDate, isNull);
      expect(item.note, '');
      expect(item.photos, isEmpty);
      expect(item.createdAt.isAfter(DateTime.now().subtract(const Duration(minutes: 1))), isTrue);
    });

    test('Item.create accepts custom values and createdAt', () {
      final item = Item.create(
        name: '笔记本电脑',
        location: '办公室',
        categoryKey: 'electronics',
        cabinetId: 'cabinet_1',
        slotId: 'slot_1',
        expiryDate: fixedDate,
        note: '公司配发',
        createdAt: fixedDate,
      );
      expect(item.name, '笔记本电脑');
      expect(item.location, '办公室');
      expect(item.categoryKey, 'electronics');
      expect(item.cabinetId, 'cabinet_1');
      expect(item.slotId, 'slot_1');
      expect(item.expiryDate, fixedDate);
      expect(item.note, '公司配发');
      expect(item.createdAt, fixedDate);
    });

    test('copyWith creates a new instance with updated fields', () {
      final item = Item(
        id: '1',
        name: 'Old',
        location: '客厅',
        createdAt: fixedDate,
      );
      final updated = item.copyWith(name: 'New', location: '卧室');
      expect(updated.id, '1');
      expect(updated.name, 'New');
      expect(updated.location, '卧室');
      expect(updated.createdAt, fixedDate);
      expect(updated, isNot(same(item)));
    });

    test('value equality: same values == equal', () {
      final a = Item(
        id: '1',
        name: 'Same',
        location: '客厅',
        createdAt: fixedDate,
      );
      final b = Item(
        id: '1',
        name: 'Same',
        location: '客厅',
        createdAt: fixedDate,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('value equality: different values != equal', () {
      final a = Item(id: '1', name: 'A', createdAt: fixedDate);
      final b = Item(id: '2', name: 'B', createdAt: fixedDate);
      expect(a, isNot(equals(b)));
    });

    test('toString includes field values', () {
      final item = Item(
        id: '1',
        name: 'Test',
        location: '客厅',
        createdAt: fixedDate,
      );
      final str = item.toString();
      expect(str, contains('Test'));
      expect(str, contains('客厅'));
    });

    test('photos list round-trips through copyWith', () {
      final item = Item(
        id: '1',
        name: 'Test',
        photos: const ['a.jpg', 'b.jpg'],
        createdAt: fixedDate,
      );
      final updated = item.copyWith(photos: const ['c.jpg']);
      expect(updated.photos, ['c.jpg']);
      expect(item.photos, ['a.jpg', 'b.jpg']);
    });
  });
}
