import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/models/enums/sort_type.dart';

void main() {
  group('sortTypeFromName 持久化解析', () {
    test('全部枚举值都能按 name 往返解析', () {
      for (final t in SortType.values) {
        expect(sortTypeFromName(t.name), t);
      }
    });

    test('未知 / 空值回退 newest', () {
      expect(sortTypeFromName('nope'), SortType.newest);
      expect(sortTypeFromName(null), SortType.newest);
      expect(sortTypeFromName(''), SortType.newest);
    });

    test('标签映射覆盖全部枚举值（下拉与 chip 不缺项）', () {
      for (final t in SortType.values) {
        expect(kSortLabels.containsKey(t), isTrue, reason: 'kSortLabels 缺 $t');
        expect(
          kSortFullLabels.containsKey(t),
          isTrue,
          reason: 'kSortFullLabels 缺 $t',
        );
      }
    });

    test('下拉顺序：名称固定在最后（2026-09-17 反馈）', () {
      expect(SortType.values.last, SortType.nameAsc);
    });

    test('文案：新增时间已改称登记时间（2026-09-17 反馈）', () {
      expect(kSortLabels[SortType.newest], '登记时间');
      expect(kSortFullLabels[SortType.newest], '登记时间（最新优先）');
      expect(kSortFullLabels[SortType.oldest], '登记时间（最早优先）');
    });
  });
}
