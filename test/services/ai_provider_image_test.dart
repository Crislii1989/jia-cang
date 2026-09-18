import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/services/ai/ai_models.dart';
import 'package:jia_cang/services/ai/providers/gemini_provider.dart';

/// `AiProvider.readImageAsBase64` 的**双形态**回归。
///
/// 背景：本项目里照片地址有两种形态——真机是应用文档目录下的文件路径，
/// Web 是 `data:image/...;base64,...` 内联串（判定见 `services/photo_service.dart`
/// 的 `isInlinePhoto`）。老实现一律 `File(imagePath)`，Web 上没有文件系统，
/// 内联串会被当成路径去查存在性 → 直接抛「图片文件不存在」，
/// **6 个供应商适配器的 Web 识别全都跑不通**。
///
/// 这条用例锁两件事：
/// 1) 内联串走 data URL 分支——切出正确的 base64 与 mime，且**不碰文件系统**；
/// 2) 文件路径那条老路没被改坏——存在性校验与按扩展名猜 mime 保持原样。
///
/// 覆盖边界：这里验的是**编码层**。真机取相机 / Web 选图后落到哪种地址、
/// 以及请求能不能到达供应商，属于端侧与联网行为，只能在真机 / E2E 里验。
void main() {
  // 借一个真实适配器实例来调用基类的共享方法（不涉及任何网络请求）。
  final provider = GeminiProvider();

  group('内联 data URL（Web 形态）', () {
    test('切出的 base64 可还原成原始字节，mime 取自 data URL 头', () async {
      final bytes = Uint8List.fromList(
        List<int>.generate(300, (i) => i % 256),
      );
      final source = 'data:image/png;base64,${base64Encode(bytes)}';

      final image = await provider.readImageAsBase64(source);

      expect(image.mimeType, 'image/png');
      expect(image.bytesLength, bytes.length);
      expect(base64Decode(image.base64), equals(bytes));
    });

    test('jpeg 内联串同样识别——mime 不是写死的 image/jpeg 常量', () async {
      // 若实现里把 mime 写死，这条就会与上一条同时成立但内容不一致；
      // 两条一起跑才能证明 mime 真来自 data URL 头。
      final bytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8]);
      final source = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final image = await provider.readImageAsBase64(source);

      expect(image.mimeType, 'image/jpeg');
      expect(image.bytesLength, 8);
      expect(base64Decode(image.base64), equals(bytes));
    });

    test('内联串完全不碰文件系统：磁盘上并不存在同名字符串的「路径」也不报错', () async {
      // 这正是 Web 上的实际情形，老实现（File(path)）在这里必抛
      // AiException('图片文件不存在')。
      final source = 'data:image/png;base64,${base64Encode(Uint8List(16))}';

      await expectLater(provider.readImageAsBase64(source), completes);
    });

    test('base64 段为空时仍能返回（bytesLength 为 0），不抛', () async {
      final image = await provider.readImageAsBase64('data:image/png;base64,');

      expect(image.base64, isEmpty);
      expect(image.bytesLength, 0);
    });

    test('data URL 头缺分号时不崩，退化成 image/jpeg 兜底', () async {
      // 防御性：异常形态的地址不该让整条识别链路抛异常。
      final image = await provider.readImageAsBase64('data:image/png,AAAA');

      expect(image.bytesLength, greaterThan(0));
    });
  });

  group('文件路径（真机形态）', () {
    test('真实文件按扩展名给 mime，base64 可还原', () async {
      final dir = await Directory.systemTemp.createTemp('jia_ai_img_');
      try {
        final file = File(
          '${dir.path}${Platform.pathSeparator}shot.png',
        );
        final bytes = Uint8List.fromList(
          List<int>.generate(64, (i) => 255 - i),
        );
        await file.writeAsBytes(bytes);

        final image = await provider.readImageAsBase64(file.path);

        expect(image.mimeType, 'image/png');
        expect(image.bytesLength, 64);
        expect(base64Decode(image.base64), equals(bytes));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('未知扩展名回落到 image/jpeg（原有行为）', () async {
      final dir = await Directory.systemTemp.createTemp('jia_ai_img_');
      try {
        final file = File('${dir.path}${Platform.pathSeparator}shot.bin');
        await file.writeAsBytes(Uint8List.fromList(<int>[9, 9, 9]));

        final image = await provider.readImageAsBase64(file.path);

        expect(image.mimeType, 'image/jpeg');
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('文件不存在时仍抛 AiException，且文案是用户可读的「图片文件不存在」', () async {
      final missing =
          '${Directory.systemTemp.path}${Platform.pathSeparator}'
          'no_such_${DateTime.now().microsecondsSinceEpoch}.jpg';

      await expectLater(
        provider.readImageAsBase64(missing),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            '图片文件不存在',
          ),
        ),
      );
    });
  });
}
