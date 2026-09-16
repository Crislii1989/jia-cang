import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/services/photo_service.dart';

/// PhotoService 的异常兜底回归。
///
/// 背景：相机调用在部分端不可用（Web 预览 iframe 无相机授权、Windows 桌面端
/// image_picker 直接抛 StateError、无摄像头设备 NotFoundError），此前异常直接
/// 漏到调用方，导致 `_isPicking` 卡死、界面「点了没反应」。
/// 修复后服务层必须接住所有异常并转成错误文案。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoService 异常兜底', () {
    test('pickFromCamera 在平台不支持/无插件时返回错误文案而不是抛异常', () async {
      // 测试环境没有任何 image_picker 插件实现，
      // pickImage 会抛 MissingPluginException —— 必须被服务层接住。
      final result = await PhotoService.instance.pickFromCamera();

      expect(result.entries, isEmpty, reason: '不应产生任何照片条目');
      expect(result.error, isNotNull, reason: '必须返回用户可读的错误提示');
      expect(result.error, isNotEmpty);
    });

    test('错误文案不应是技术性堆栈（不得包含 Exception/Error 字样）', () async {
      final result = await PhotoService.instance.pickFromCamera();
      final msg = result.error ?? '';
      expect(msg.contains('Exception'), isFalse, reason: '文案: $msg');
      expect(msg.contains('Error'), isFalse, reason: '文案: $msg');
    });

    test('pickFromGallery 在平台不支持/无插件时同样兜住（remaining=1 单选路径）', () async {
      final result = await PhotoService.instance.pickFromGallery(remaining: 1);
      expect(result.entries, isEmpty);
      expect(result.error, isNotNull);
    });

    test('pickFromGallery 多选路径（remaining>=2）同样兜住', () async {
      final result = await PhotoService.instance.pickFromGallery(remaining: 3);
      expect(result.entries, isEmpty);
      expect(result.error, isNotNull);
    });
  });
}
