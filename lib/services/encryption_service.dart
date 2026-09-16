import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 应用本地敏感数据加密服务。
///
/// 使用 AES-256-GCM（带认证标签）加解密存储在 SQLite 中的 AI 配置等敏感字段。
/// 密文格式：`base64(nonce(12B) || ciphertext || mac(16B))`。
///
/// 密钥派生：PBKDF2-HMAC-SHA256，600000 次迭代（OWASP 2023 建议）。
/// 密钥存储：随机 password + salt 存于 FlutterSecureStorage，派生密钥缓存于内存。
///
/// 历史版本：v1（硬编码密钥 CBC）→ v2（随机密钥 10k CBC）→ v3（随机密钥 600k CBC）
/// → 当前 v4（随机密钥 600k GCM）。v4 不保留任何旧版回退路径，
/// 旧版加密的 AI 配置数据无法解密，用户需重新输入。
class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  static const int _keyLength = 32;
  static const int _nonceLength = 12;

  // ─── PBKDF2 迭代数（OWASP 2023 建议 PBKDF2-HMAC-SHA256 ≥ 600000） ───
  static const int _pbkdf2Iterations = 600000;

  // ─── 安全存储 key ───────────────────────────
  static const _secureStorage = FlutterSecureStorage();

  /// 当前密钥（v4，GCM）的 secure storage key。
  static const _kPasswordKey = 'enc_password_v4';
  static const _kSaltKey = 'enc_salt_v4';

  /// AES-256-GCM 算法单例（线程安全，可复用）。
  final _gcmAlgorithm = AesGcm.with256bits();

  /// 缓存的当前密钥（v4，PBKDF2 600k 派生，init 后填充）。
  SecretKey? _cachedKey;

  /// 初始化 —— 在 App 启动时调用一次。
  ///
  /// 从安全存储加载 password+salt，用 PBKDF2 派生 SecretKey；
  /// 首次安装时生成随机 password+salt 并写入安全存储。
  Future<void> init() async {
    _cachedKey = await _loadOrGenerateKey();
  }

  /// 从安全存储加载或生成当前密钥（v4）。
  ///
  /// 在 secure storage 不可用的平台（如 Web 调试环境），
  /// 降级为纯内存随机密钥 —— 仅当前 session 有效，重启后失效。
  Future<SecretKey> _loadOrGenerateKey() async {
    try {
      final storedPassword = await _secureStorage.read(key: _kPasswordKey);
      final storedSalt = await _secureStorage.read(key: _kSaltKey);

      if (storedPassword != null && storedSalt != null) {
        final keyBytes = _pbkdf2(
          utf8.encode(storedPassword),
          utf8.encode(storedSalt),
          _pbkdf2Iterations,
          _keyLength,
        );
        return SecretKey(keyBytes);
      }

      // 首次使用：生成随机 password 和 salt
      final random = Random.secure();
      final newPassword = _generateRandomBase64(32, random);
      final newSalt = _generateRandomBase64(16, random);

      await _secureStorage.write(key: _kPasswordKey, value: newPassword);
      await _secureStorage.write(key: _kSaltKey, value: newSalt);

      final keyBytes = _pbkdf2(
        utf8.encode(newPassword),
        utf8.encode(newSalt),
        _pbkdf2Iterations,
        _keyLength,
      );
      return SecretKey(keyBytes);
    } catch (e) {
      // Web 平台 flutter_secure_storage 可能未配置 Web 实现，
      // 降级为纯内存随机密钥（仅当前 session 有效）
      debugPrint(
        '[EncryptionService] secure storage 不可用，降级为内存密钥: $e',
      );
      final random = Random.secure();
      final fallbackPassword = _generateRandomBase64(32, random);
      final fallbackSalt = _generateRandomBase64(16, random);
      final keyBytes = _pbkdf2(
        utf8.encode(fallbackPassword),
        utf8.encode(fallbackSalt),
        _pbkdf2Iterations,
        _keyLength,
      );
      return SecretKey(keyBytes);
    }
  }

  String _generateRandomBase64(int byteLength, Random random) {
    final bytes = Uint8List.fromList(
      List<int>.generate(byteLength, (_) => random.nextInt(256)),
    );
    return base64.encode(bytes);
  }

  /// 获取当前密钥（必须已调用 init）。
  SecretKey get _currentKey {
    final key = _cachedKey;
    if (key == null) {
      throw StateError(
        'EncryptionService 未初始化，请在 App 启动时调用 init()',
      );
    }
    return key;
  }

  /// 测试用：直接注入当前密钥，绕过 secure storage 初始化。
  ///
  /// 用于 round-trip 加解密测试，验证 AES-256-GCM 实现的正确性
  ///（密文篡改验签失败、nonce 不重用、编码边界等）。
  @visibleForTesting
  Future<void> setKeyForTesting(Uint8List key) async {
    _cachedKey = SecretKey(key);
  }

  /// PBKDF2-HMAC-SHA256 密钥派生。
  Uint8List _pbkdf2(
    Uint8List password,
    Uint8List salt,
    int iterations,
    int derivedKeyLength,
  ) {
    final hmac = crypto.Hmac(crypto.sha256, password);
    final blocks = (derivedKeyLength / 32).ceil();
    final derivedKey = BytesBuilder();

    for (var i = 1; i <= blocks; i++) {
      var u = Uint8List.fromList([
        ...salt,
        (i >> 24) & 0xff,
        (i >> 16) & 0xff,
        (i >> 8) & 0xff,
        i & 0xff,
      ]);
      u = Uint8List.fromList(hmac.convert(u).bytes);
      final result = Uint8List.fromList(u);

      for (var j = 1; j < iterations; j++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var k = 0; k < result.length; k++) {
          result[k] ^= u[k];
        }
      }
      derivedKey.add(result);
    }

    return derivedKey.takeBytes().sublist(0, derivedKeyLength);
  }

  /// 加密明文，返回 `base64(nonce || ciphertext || mac)`。
  ///
  /// GCM 模式自动生成 16 字节 GMAC 认证标签附在密文末尾，
  /// 任何篡改都会在 [decrypt] 时验签失败。
  Future<String> encrypt(String plaintext) async {
    if (plaintext.isEmpty) return '';

    final key = _currentKey;
    final nonce = _generateRandomBytes(_nonceLength);
    final secretBox = await _gcmAlgorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    // 拼接 nonce + ciphertext + mac
    final combined = BytesBuilder()
      ..add(nonce)
      ..add(secretBox.cipherText)
      ..add(secretBox.mac.bytes);

    return base64.encode(combined.takeBytes());
  }

  /// 解密密文，验签失败返回空字符串。
  Future<String> decrypt(String ciphertext) async {
    if (ciphertext.isEmpty) return '';

    try {
      final combined = base64.decode(ciphertext);
      // 最小长度：nonce(12) + mac(16)，密文可为空（加密空串场景已被 encrypt 短路）
      if (combined.length < _nonceLength + 16) return '';

      final nonce = combined.sublist(0, _nonceLength);
      final mac = Mac(combined.sublist(combined.length - 16));
      final cipherText = combined.sublist(
        _nonceLength,
        combined.length - 16,
      );

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: mac,
      );

      final plainBytes = await _gcmAlgorithm.decrypt(
        secretBox,
        secretKey: _currentKey,
      );
      return utf8.decode(plainBytes);
    } catch (_) {
      // GCM 验签失败、base64 解码失败、密文长度不足等均返回空
      return '';
    }
  }

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
