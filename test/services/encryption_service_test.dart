import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jia_cang/services/encryption_service.dart';

/// 加密服务 round-trip 与边界测试（AES-256-GCM）。
///
/// 覆盖目标：
/// - GCM 加解密 round-trip（encrypt → decrypt 返回原文）
/// - 空字符串、纯 ASCII、Unicode/emoji 等编码边界
/// - 密文篡改后 GCM 验签失败返回空字符串（GMAC 认证）
/// - nonce 不重用：同明文两次加密结果不同
/// - base64 非法/密文长度不足返回空
void main() {
  late EncryptionService service;

  // 固定的 32 字节测试密钥（AES-256）
  final testKey = Uint8List.fromList(
    List<int>.generate(32, (i) => (i * 7 + 3) % 256),
  );

  setUp(() async {
    service = EncryptionService.instance;
    await service.setKeyForTesting(testKey);
  });

  group('round-trip 加解密', () {
    test('纯 ASCII 字符串 round-trip', () async {
      const plaintext = 'hello world';
      final encrypted = await service.encrypt(plaintext);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plaintext)));
      expect(await service.decrypt(encrypted), equals(plaintext));
    });

    test('Unicode 中文 round-trip', () async {
      const plaintext = '你好世界，家藏 v1.0.8';
      final encrypted = await service.encrypt(plaintext);
      expect(await service.decrypt(encrypted), equals(plaintext));
    });

    test('emoji 与多字节字符 round-trip', () async {
      const plaintext = '🐱🐶 物品收纳 \u{1F389}';
      final encrypted = await service.encrypt(plaintext);
      expect(await service.decrypt(encrypted), equals(plaintext));
    });

    test('长字符串（跨多个 GCM 块）round-trip', () async {
      // 256 字节明文，GCM 内部按 16 字节块处理，验证多块链接正确
      final plaintext = 'a' * 256 + 'b' * 128;
      final encrypted = await service.encrypt(plaintext);
      expect(await service.decrypt(encrypted), equals(plaintext));
    });

    test('空字符串 encrypt 返回空，decrypt 空返回空', () async {
      expect(await service.encrypt(''), isEmpty);
      expect(await service.decrypt(''), isEmpty);
    });

    test('单字节字符串 round-trip', () async {
      const plaintext = 'x';
      final encrypted = await service.encrypt(plaintext);
      expect(await service.decrypt(encrypted), equals(plaintext));
    });

    test('正好 16 字节字符串 round-trip', () async {
      final plaintext = '0123456789abcdef';
      final encrypted = await service.encrypt(plaintext);
      expect(await service.decrypt(encrypted), equals(plaintext));
    });
  });

  group('GCM 认证与密文篡改', () {
    test('篡改密文中部字节后验签失败返回空', () async {
      const plaintext = 'sensitive-api-key-12345';
      final encrypted = await service.encrypt(plaintext);

      // 翻转 nonce 之后、mac 之前的某个字节（密文区）
      final bytes = Uint8List.fromList(base64.decode(encrypted));
      final cipherTextStart = 12; // nonce 长度
      final cipherTextEnd = bytes.length - 16; // 减去 mac
      if (cipherTextEnd > cipherTextStart) {
        bytes[cipherTextStart] ^= 0xFF;
      }
      final tampered = base64.encode(bytes);

      // GCM 验签失败，返回空
      expect(await service.decrypt(tampered), isEmpty);
    });

    test('篡改 GMAC 标签后验签失败返回空', () async {
      const plaintext = 'api-key-secret';
      final encrypted = await service.encrypt(plaintext);

      // 翻转最后一个字节（MAC 区）
      final bytes = Uint8List.fromList(base64.decode(encrypted));
      bytes[bytes.length - 1] ^= 0xFF;
      final tampered = base64.encode(bytes);

      expect(await service.decrypt(tampered), isEmpty);
    });

    test('篡改 nonce 后验签失败返回空', () async {
      const plaintext = 'api-key-secret';
      final encrypted = await service.encrypt(plaintext);

      // 翻转 nonce 的第一个字节
      final bytes = Uint8List.fromList(base64.decode(encrypted));
      bytes[0] ^= 0xFF;
      final tampered = base64.encode(bytes);

      expect(await service.decrypt(tampered), isEmpty);
    });

    test('base64 非法字符串解密返回空', () async {
      expect(await service.decrypt('!!!not-base64!!!'), isEmpty);
    });

    test('密文短于 nonce+mac 长度返回空', () async {
      // 只有 8 字节，短于 12(nonce)+16(mac)=28 字节
      final short = base64.encode(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]));
      expect(await service.decrypt(short), isEmpty);
    });
  });

  group('nonce 不重用', () {
    test('同明文两次加密结果不同（nonce 随机）', () async {
      const plaintext = 'same-plaintext';
      final encrypted1 = await service.encrypt(plaintext);
      final encrypted2 = await service.encrypt(plaintext);

      // nonce 随机，两次密文必不同
      expect(encrypted1, isNot(equals(encrypted2)));

      // 但都能解密回原文
      expect(await service.decrypt(encrypted1), equals(plaintext));
      expect(await service.decrypt(encrypted2), equals(plaintext));
    });
  });
}
