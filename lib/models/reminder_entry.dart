import 'item.dart';

/// 首页「提醒」条目的紧急度分类。
///
/// 与 `StatusBadge` 的 `BadgeType` 映射关系见 `home/reminder_section.dart`：
/// - [overdue]  → danger（红）
/// - [expiring] → warn（珊瑚）
/// - [idle]     → muted（中性）
enum ReminderKind { overdue, expiring, idle }

/// 首页「提醒」模块的单条数据（纯展示模型，不落库）。
///
/// 由 `homeRemindersProvider` 从物品列表聚合而来：
/// 已到期 → 即将到期 → 长期闲置，三种来源共用同一个条目结构。
class ReminderEntry {
  /// 物品本身（点击「去处理」跳详情用）
  final Item item;

  /// 紧急度分类
  final ReminderKind kind;

  /// 徽标文案，如「已逾期 2 天」「3 天后到期」「闲置 90+ 天」
  final String badgeText;

  const ReminderEntry({
    required this.item,
    required this.kind,
    required this.badgeText,
  });
}
