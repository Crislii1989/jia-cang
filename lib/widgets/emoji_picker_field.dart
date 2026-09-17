/// 项目统一的 emoji 候选库与选择器。
///
/// 「选择图标」是**下拉字段形式**：收起时是一行与 `AppDropdownButton`
/// 同款外观的字段（当前图标 + 展开箭头，高 44），点击弹出居中选图面板
/// （`showCenterSheet`），面板里是纯图标宫格——不显示任何文字标签
/// （emoji 本身已经足够表意，中文名只保留在无障碍语义里），点选后自动收起。
/// 这样表单里不再被宫格占掉一大片空间（用户反馈见 2026-09-16 流水）。
///
/// 所有 emoji 都通过 `EmojiText`（NotoColorEmoji）渲染，
/// 避免系统字体裁剪导致「矩形叉标」。
///
/// 候选库来源：Unicode 官方 emoji 清单（Emoji 1.0 ~ 17.0）中与家居收纳、
/// 日用物品相关的条目，已按「拿取场景」分组排序，常用项排在前面。
/// 新增候选时注意：
/// - 同一个列表内 emoji 不能重复（面板里会出现两个一样的格子）；
/// - 只用单码点 / 带 VS16 的字符，不用 ZWJ 组合序列（部分字体缺字形）；
/// - 新增后跑 `test/widgets/emoji_picker_field_test.dart` 校验重复与数量。
library;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'center_sheet.dart';
import 'emoji_text.dart';

/// 一个 emoji 候选：图标本身 + 中文名。
///
/// 中文名**不出现在宫格里**，只用于无障碍朗读（`Semantics.label`）。
class EmojiOption {
  final String emoji;
  final String label;
  const EmojiOption(this.emoji, this.label);
}

/// 收纳空间（房间 / 柜体 / 箱子）可选图标。
///
/// 顺序按「起居 → 厨房 → 卫浴 → 电器 → 衣物 → 箱包 → 工具 → 文书 →
/// 文具 → 健康 → 休闲 → 杂物」排列，与用户挑图标时的心理归类一致。
const List<EmojiOption> kSpaceEmojiOptions = [
  // 起居 / 家具
  EmojiOption('🛋️', '沙发'),
  EmojiOption('🛏️', '床'),
  EmojiOption('🪑', '椅凳'),
  EmojiOption('🚪', '门'),
  EmojiOption('🪟', '窗'),
  EmojiOption('🪞', '镜子'),
  EmojiOption('🗄️', '文件柜'),
  EmojiOption('🪆', '套娃'),
  EmojiOption('🖼️', '挂画'),
  EmojiOption('🕯️', '蜡烛'),
  EmojiOption('🪴', '绿植'),
  EmojiOption('🌱', '幼苗'),
  EmojiOption('🧱', '墙面'),
  EmojiOption('🪵', '木料'),
  // 厨房 / 餐厨
  EmojiOption('🍳', '锅具'),
  EmojiOption('🍚', '米面'),
  EmojiOption('🥫', '罐头'),
  EmojiOption('🧂', '调料'),
  EmojiOption('🍽️', '餐具'),
  EmojiOption('🥢', '筷子'),
  EmojiOption('🔪', '刀具'),
  EmojiOption('🥤', '杯具'),
  EmojiOption('☕', '咖啡'),
  EmojiOption('🫖', '茶壶'),
  EmojiOption('🧋', '奶茶'),
  EmojiOption('🥛', '牛奶'),
  EmojiOption('🧃', '果汁'),
  EmojiOption('🍶', '酒壶'),
  EmojiOption('🍷', '红酒'),
  EmojiOption('🍺', '啤酒'),
  EmojiOption('🍯', '蜂蜜'),
  EmojiOption('🧈', '黄油'),
  EmojiOption('🍞', '面包'),
  EmojiOption('🥚', '蛋类'),
  EmojiOption('🥣', '碗'),
  EmojiOption('🫙', '罐子'),
  EmojiOption('🍱', '便当'),
  EmojiOption('🍫', '零食'),
  EmojiOption('🧊', '冷藏'),
  // 卫浴 / 清洁
  EmojiOption('🛁', '浴缸'),
  EmojiOption('🚿', '淋浴'),
  EmojiOption('🚽', '马桶'),
  EmojiOption('🚰', '龙头'),
  EmojiOption('🧼', '香皂'),
  EmojiOption('🧴', '瓶装'),
  EmojiOption('🧻', '纸品'),
  EmojiOption('🧹', '清洁'),
  EmojiOption('🧽', '海绵'),
  EmojiOption('🪣', '水桶'),
  EmojiOption('🪥', '牙刷'),
  EmojiOption('🪒', '剃刀'),
  EmojiOption('🪠', '皮搋子'),
  EmojiOption('🧯', '消防'),
  // 电器 / 数码
  EmojiOption('📺', '电视'),
  EmojiOption('🖥️', '台式机'),
  EmojiOption('💻', '笔记本'),
  EmojiOption('📱', '手机'),
  EmojiOption('🎧', '耳机'),
  EmojiOption('🎮', '游戏'),
  EmojiOption('🕹️', '摇杆'),
  EmojiOption('🔌', '线材'),
  EmojiOption('🔋', '电池'),
  EmojiOption('🪫', '低电量'),
  EmojiOption('💡', '灯具'),
  EmojiOption('📷', '相机'),
  EmojiOption('🎥', '摄像机'),
  EmojiOption('⌚', '手表'),
  EmojiOption('🖨️', '打印'),
  EmojiOption('🖱️', '鼠标'),
  EmojiOption('⌨️', '键盘'),
  EmojiOption('🔊', '音箱'),
  EmojiOption('📻', '收音机'),
  EmojiOption('📡', '天线'),
  EmojiOption('💿', '光盘'),
  EmojiOption('📼', '磁带'),
  EmojiOption('☎️', '座机'),
  EmojiOption('🔦', '手电'),
  // 衣物 / 穿戴
  EmojiOption('👔', '衬衫'),
  EmojiOption('👕', '上衣'),
  EmojiOption('👚', '女装'),
  EmojiOption('👖', '裤装'),
  EmojiOption('👗', '裙装'),
  EmojiOption('🧥', '外套'),
  EmojiOption('👟', '运动鞋'),
  EmojiOption('👞', '皮鞋'),
  EmojiOption('👠', '高跟鞋'),
  EmojiOption('👡', '凉鞋'),
  EmojiOption('👢', '长靴'),
  EmojiOption('🥾', '靴子'),
  EmojiOption('🥿', '平底鞋'),
  EmojiOption('🩴', '拖鞋'),
  EmojiOption('🧢', '帽子'),
  EmojiOption('🎩', '礼帽'),
  EmojiOption('👒', '女帽'),
  EmojiOption('🧣', '围巾'),
  EmojiOption('🧤', '手套'),
  EmojiOption('🧦', '袜子'),
  EmojiOption('🕶️', '眼镜'),
  EmojiOption('⛑️', '安全帽'),
  EmojiOption('💄', '美妆'),
  EmojiOption('💍', '首饰'),
  EmojiOption('🎀', '蝴蝶结'),
  // 箱包 / 织物
  EmojiOption('👜', '手提包'),
  EmojiOption('👛', '钱包'),
  EmojiOption('👝', '手包'),
  EmojiOption('🎒', '背包'),
  EmojiOption('🧳', '行李箱'),
  EmojiOption('🧺', '洗衣篮'),
  EmojiOption('🧵', '线团'),
  EmojiOption('🧶', '毛线'),
  EmojiOption('🪡', '针线'),
  EmojiOption('🧷', '别针'),
  // 工具 / 五金
  EmojiOption('🔧', '扳手'),
  EmojiOption('🪛', '螺丝刀'),
  EmojiOption('🔨', '锤子'),
  EmojiOption('🧰', '工具箱'),
  EmojiOption('🛠️', '工具组'),
  EmojiOption('🔩', '螺丝'),
  EmojiOption('🪚', '锯子'),
  EmojiOption('🪓', '斧头'),
  EmojiOption('⛏️', '镐'),
  EmojiOption('🪝', '挂钩'),
  EmojiOption('🪜', '梯子'),
  EmojiOption('🧲', '磁铁'),
  EmojiOption('🪤', '捕鼠夹'),
  EmojiOption('🔗', '链接'),
  EmojiOption('⛓️', '铁链'),
  EmojiOption('🛞', '轮子'),
  // 书籍 / 文书
  EmojiOption('📚', '书籍'),
  EmojiOption('📖', '书'),
  EmojiOption('📕', '小说'),
  EmojiOption('📓', '笔记本'),
  EmojiOption('📒', '账本'),
  EmojiOption('📔', '日记'),
  EmojiOption('🗃️', '文件盒'),
  EmojiOption('🗂️', '收纳册'),
  EmojiOption('📄', '文件'),
  EmojiOption('📃', '单据'),
  EmojiOption('📋', '剪贴板'),
  EmojiOption('📇', '名片册'),
  EmojiOption('🎫', '票据'),
  EmojiOption('💳', '卡片'),
  EmojiOption('📰', '报纸'),
  EmojiOption('📅', '日历'),
  // 文具
  EmojiOption('✏️', '铅笔'),
  EmojiOption('✒️', '钢笔'),
  EmojiOption('🖊️', '圆珠笔'),
  EmojiOption('🖍️', '蜡笔'),
  EmojiOption('🖌️', '画笔'),
  EmojiOption('📏', '直尺'),
  EmojiOption('📐', '三角尺'),
  EmojiOption('📌', '图钉'),
  EmojiOption('📎', '回形针'),
  EmojiOption('🖇️', '联动夹'),
  // 健康 / 母婴
  EmojiOption('💊', '药品'),
  EmojiOption('🩹', '创可贴'),
  EmojiOption('🩺', '听诊器'),
  EmojiOption('🌡️', '体温计'),
  EmojiOption('🩻', 'X光片'),
  EmojiOption('🦷', '口腔'),
  EmojiOption('🩼', '拐杖'),
  EmojiOption('🧪', '试剂'),
  EmojiOption('🍼', '母婴'),
  EmojiOption('🐾', '宠物'),
  // 休闲 / 运动
  EmojiOption('🧸', '玩偶'),
  EmojiOption('🧩', '拼图'),
  EmojiOption('🎲', '骰子'),
  EmojiOption('🎯', '靶心'),
  EmojiOption('🎨', '颜料'),
  EmojiOption('🎭', '面具'),
  EmojiOption('🪁', '风筝'),
  EmojiOption('🛹', '滑板'),
  EmojiOption('🛼', '旱冰鞋'),
  EmojiOption('🚲', '自行车'),
  EmojiOption('⛺', '帐篷'),
  EmojiOption('🎸', '吉他'),
  EmojiOption('🎹', '电子琴'),
  EmojiOption('🎺', '小号'),
  EmojiOption('🪈', '笛子'),
  EmojiOption('🏺', '陶罐'),
  EmojiOption('🏆', '奖杯'),
  EmojiOption('🏅', '奖牌'),
  // 杂物 / 出行
  EmojiOption('🔑', '钥匙'),
  EmojiOption('🗝️', '老钥匙'),
  EmojiOption('🔒', '锁'),
  EmojiOption('🌂', '雨伞'),
  EmojiOption('🎁', '礼盒'),
  EmojiOption('🛒', '购物车'),
  EmojiOption('🚗', '车库'),
  EmojiOption('✈️', '出行'),
  EmojiOption('🧭', '指南针'),
  EmojiOption('📦', '杂物'),
];

/// 物品分类可选图标。
const List<EmojiOption> kCategoryEmojiOptions = [
  // 数码 / 电器
  EmojiOption('📱', '手机'),
  EmojiOption('💻', '电脑'),
  EmojiOption('🖥️', '台式机'),
  EmojiOption('⌨️', '键盘'),
  EmojiOption('🖱️', '鼠标'),
  EmojiOption('🖨️', '打印机'),
  EmojiOption('📺', '电视'),
  EmojiOption('📻', '收音机'),
  EmojiOption('🎧', '音频'),
  EmojiOption('🔊', '音箱'),
  EmojiOption('🎮', '游戏'),
  EmojiOption('📷', '摄影'),
  EmojiOption('🎥', '录像'),
  EmojiOption('⌚', '穿戴'),
  EmojiOption('🔌', '电料'),
  EmojiOption('🔋', '电池'),
  EmojiOption('💡', '照明'),
  EmojiOption('❄️', '制冷'),
  EmojiOption('💨', '通风'),
  EmojiOption('🔥', '取暖'),
  // 家居 / 家具
  EmojiOption('🏠', '家居'),
  EmojiOption('🛋️', '沙发'),
  EmojiOption('🛏️', '床品'),
  EmojiOption('🪑', '家具'),
  EmojiOption('🪟', '窗饰'),
  EmojiOption('🪞', '镜子'),
  EmojiOption('🖼️', '装饰'),
  EmojiOption('🕯️', '香薰'),
  EmojiOption('🪴', '绿植'),
  EmojiOption('🌿', '园艺'),
  EmojiOption('🧺', '织物'),
  EmojiOption('🧹', '吸尘'),
  // 厨房 / 餐厨
  EmojiOption('🍳', '厨具'),
  EmojiOption('🍽️', '餐具'),
  EmojiOption('🥢', '筷勺'),
  EmojiOption('🔪', '刀剪'),
  EmojiOption('🫖', '茶具'),
  EmojiOption('🧂', '调料'),
  EmojiOption('🍚', '粮油'),
  EmojiOption('🫙', '密封罐'),
  // 食品 / 饮料
  EmojiOption('🧊', '生鲜'),
  EmojiOption('🥚', '蛋奶'),
  EmojiOption('🥛', '乳品'),
  EmojiOption('🍞', '烘焙'),
  EmojiOption('🍫', '零食'),
  EmojiOption('🥫', '罐装'),
  EmojiOption('🍯', '蜂蜜'),
  EmojiOption('☕', '饮品'),
  EmojiOption('🧃', '饮料'),
  EmojiOption('🍷', '酒水'),
  // 洗护 / 清洁
  EmojiOption('🧴', '洗护'),
  EmojiOption('🧼', '洗涤'),
  EmojiOption('🧻', '纸品'),
  EmojiOption('🧽', '清洁'),
  EmojiOption('🪥', '口腔'),
  EmojiOption('🪒', '剃须'),
  EmojiOption('💄', '美妆'),
  // 衣物 / 配饰
  EmojiOption('👔', '衣物'),
  EmojiOption('👕', '上装'),
  EmojiOption('👖', '裤装'),
  EmojiOption('👗', '裙装'),
  EmojiOption('🧥', '外套'),
  EmojiOption('👟', '鞋履'),
  EmojiOption('🩴', '拖鞋'),
  EmojiOption('👜', '箱包'),
  EmojiOption('🎒', '背包'),
  EmojiOption('🧢', '帽子'),
  EmojiOption('🧣', '围巾'),
  EmojiOption('🧦', '袜子'),
  EmojiOption('🕶️', '眼镜'),
  EmojiOption('💍', '珠宝'),
  // 工具 / 五金
  EmojiOption('🔧', '工具'),
  EmojiOption('🧰', '五金'),
  EmojiOption('🔨', '维修'),
  EmojiOption('📏', '量具'),
  EmojiOption('🔩', '配件'),
  EmojiOption('🧲', '磁铁'),
  EmojiOption('🔦', '手电'),
  EmojiOption('🧯', '安全'),
  // 文具 / 办公
  EmojiOption('✏️', '文具'),
  EmojiOption('📄', '办公'),
  EmojiOption('📚', '书籍'),
  EmojiOption('📖', '读物'),
  EmojiOption('📓', '本册'),
  EmojiOption('🗂️', '收纳'),
  EmojiOption('🗃️', '档案'),
  // 健康 / 母婴
  EmojiOption('💊', '药品'),
  EmojiOption('🩹', '医疗'),
  EmojiOption('🩺', '器械'),
  EmojiOption('🌡️', '健康'),
  EmojiOption('🦷', '牙齿'),
  EmojiOption('🩻', '影像'),
  EmojiOption('🍼', '母婴'),
  EmojiOption('🐾', '宠物'),
  // 休闲 / 运动
  EmojiOption('🧸', '玩具'),
  EmojiOption('🎨', '手作'),
  EmojiOption('🎵', '乐器'),
  EmojiOption('🏋️', '运动'),
  EmojiOption('🚲', '骑行'),
  EmojiOption('⛺', '露营'),
  EmojiOption('🛹', '滑板'),
  EmojiOption('🧩', '拼图'),
  EmojiOption('🏆', '奖杯'),
  // 出行 / 杂物
  EmojiOption('🧳', '旅行'),
  EmojiOption('🚗', '车品'),
  EmojiOption('✈️', '出行'),
  EmojiOption('🔑', '钥匙'),
  EmojiOption('🔒', '锁具'),
  EmojiOption('🌂', '雨具'),
  EmojiOption('🎁', '礼品'),
  EmojiOption('🛒', '日用'),
  EmojiOption('🏺', '摆件'),
  EmojiOption('🪙', '收藏'),
  EmojiOption('💳', '卡证'),
  EmojiOption('📦', '杂物'),
];

/// 头像可选 emoji。
const List<EmojiOption> kAvatarEmojiOptions = [
  // 人物
  EmojiOption('🧑', '我'),
  EmojiOption('👩', '女生'),
  EmojiOption('👨', '男生'),
  EmojiOption('🧒', '小孩'),
  EmojiOption('👧', '女孩'),
  EmojiOption('👦', '男孩'),
  EmojiOption('👶', '宝宝'),
  EmojiOption('🧓', '长辈'),
  EmojiOption('🦸', '英雄'),
  EmojiOption('🧑‍🚀', '宇航员'),
  // 动物
  EmojiOption('🐱', '猫'),
  EmojiOption('🐶', '狗'),
  EmojiOption('🦊', '狐狸'),
  EmojiOption('🐻', '熊'),
  EmojiOption('🐼', '熊猫'),
  EmojiOption('🐨', '考拉'),
  EmojiOption('🐯', '老虎'),
  EmojiOption('🦁', '狮子'),
  EmojiOption('🐰', '兔子'),
  EmojiOption('🐹', '仓鼠'),
  EmojiOption('🐭', '小鼠'),
  EmojiOption('🐷', '小猪'),
  EmojiOption('🐵', '猴子'),
  EmojiOption('🦄', '独角兽'),
  EmojiOption('🦖', '恐龙'),
  EmojiOption('🦕', '长颈龙'),
  EmojiOption('🐢', '乌龟'),
  EmojiOption('🐙', '章鱼'),
  EmojiOption('🦭', '海豹'),
  EmojiOption('🦥', '树懒'),
  EmojiOption('🦔', '刺猬'),
  EmojiOption('🐧', '企鹅'),
  EmojiOption('🐤', '小鸡'),
  EmojiOption('🦉', '猫头鹰'),
  EmojiOption('🦜', '鹦鹉'),
  EmojiOption('🦩', '火烈鸟'),
  EmojiOption('🐠', '小鱼'),
  EmojiOption('🪼', '水母'),
  EmojiOption('🦋', '蝴蝶'),
  // 植物 / 自然
  EmojiOption('🌸', '樱花'),
  EmojiOption('🌻', '向日葵'),
  EmojiOption('🌷', '郁金香'),
  EmojiOption('🌵', '仙人掌'),
  EmojiOption('🍄', '蘑菇'),
  EmojiOption('🍀', '四叶草'),
  EmojiOption('⭐', '星星'),
  EmojiOption('🌙', '月亮'),
  EmojiOption('☀️', '太阳'),
  EmojiOption('🌈', '彩虹'),
  EmojiOption('☁️', '云朵'),
  EmojiOption('🔥', '火焰'),
  EmojiOption('❄️', '雪花'),
  EmojiOption('🪐', '星球'),
  EmojiOption('✨', '闪光'),
  // 兴趣
  EmojiOption('🎮', '游戏'),
  EmojiOption('🎵', '音乐'),
  EmojiOption('📷', '摄影'),
  EmojiOption('💻', '代码'),
  EmojiOption('🎨', '绘画'),
  EmojiOption('🚀', '火箭'),
  EmojiOption('🏠', '居家'),
  EmojiOption('☕', '咖啡'),
  EmojiOption('🍰', '甜点'),
  EmojiOption('🍉', '西瓜'),
  EmojiOption('🎁', '礼物'),
  EmojiOption('📚', '阅读'),
];

/// emoji 图标下拉选择器。
///
/// 用法：
/// ```dart
/// EmojiPickerField(
///   value: _selectedIcon,
///   options: kSpaceEmojiOptions,
///   onChanged: (v) => setState(() => _selectedIcon = v),
/// )
/// ```
///
/// 交互约定：
/// - 收起时是**一行下拉字段**（高 44，外观与 `AppDropdownButton` 一致），
///   左侧显示当前图标，右侧展开箭头——不再在表单里铺开宫格；
/// - 点击弹出居中选图面板，面板内**只显示图标**、不显示中文名；
/// - 面板中选中项高亮（金底 + 金边），点选后自动收起；
/// - 若 [value] 不在 [options] 中（历史数据里的老图标），
///   会把它作为「当前使用」插到最前面，避免出现「选不回来」的情况。
class EmojiPickerField extends StatefulWidget {
  final String value;
  final List<EmojiOption> options;
  final ValueChanged<String> onChanged;

  /// 选图面板的标题。
  final String title;

  const EmojiPickerField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.title = '选择图标',
  });

  @override
  State<EmojiPickerField> createState() => _EmojiPickerFieldState();
}

class _EmojiPickerFieldState extends State<EmojiPickerField> {
  /// 面板里实际展示的候选：把不在候选库里的当前值前置，保证「选得回来」。
  List<EmojiOption> get _options {
    if (widget.value.isEmpty) return widget.options;
    final exists = widget.options.any((o) => o.emoji == widget.value);
    if (exists) return widget.options;
    return [EmojiOption(widget.value, '当前使用'), ...widget.options];
  }

  Future<void> _openPicker() async {
    final picked = await showCenterSheet<String>(
      context: context,
      builder: (_) => _EmojiPickerPanel(
        title: widget.title,
        options: _options,
        selected: widget.value,
      ),
    );
    if (picked != null && picked != widget.value) {
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        // 外观对齐 AppDropdownButton：奶油底 + 1.5 边框 + 8 圆角 + 高 44
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            if (widget.value.isNotEmpty) ...[
              EmojiText(emoji: widget.value, fontSize: 22),
            ],
            const Spacer(),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 选图面板：居中弹窗 + 纯图标宫格，点选后 `pop(emoji)` 回传。
class _EmojiPickerPanel extends StatelessWidget {
  final String title;
  final List<EmojiOption> options;
  final String selected;

  static const double _cellSize = 44;
  static const double _spacing = 10;

  const _EmojiPickerPanel({
    required this.title,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    // 宫格区域高度：小屏至少 3 行，大屏不超过 ~6 行
    final gridMaxHeight = (screenHeight * 0.42).clamp(3.0 * _cellSize + 2 * _spacing,
        6.0 * _cellSize + 5 * _spacing);

    return CenterSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: gridMaxHeight),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: _spacing,
                runSpacing: _spacing,
                children: [
                  for (final option in options) _buildCell(context, option),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, EmojiOption option) {
    final isSelected = option.emoji == selected;
    return Semantics(
      label: option.label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(option.emoji),
        child: Container(
          width: _cellSize,
          height: _cellSize,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.coralSoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.coral : AppColors.border,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Center(
            child: EmojiText(emoji: option.emoji, fontSize: _cellSize * 0.52),
          ),
        ),
      ),
    );
  }
}
