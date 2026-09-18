import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../photo_service.dart';
import 'ai_models.dart';
import 'ai_provider_type.dart';

/// AI Provider 抽象接口
///
/// 所有供应商适配器实现此接口，由 [AiProviderRegistry] 注册并通过 [AiConfigManager] 调度。
/// 新增供应商步骤：
/// 1. 在 [AiProviderType] 添加枚举项
/// 2. 在 [aiProviderMetas] 添加展示元数据
/// 3. 实现 [AiProvider] 接口的子类
/// 4. 在 [AiProviderRegistry] 注册
abstract class AiProvider {
  /// 供应商类型
  AiProviderType get type;

  /// 默认模型名（用户未配置时使用）
  String get defaultModel => aiProviderMetas[type]!.defaultModel;

  /// 默认 BaseURL（用户未配置时使用）
  String get defaultBaseUrl;

  /// 图片识别入口
  ///
  /// [imagePath] 本地图片文件路径
  /// [config] 调用配置（API Key / 模型 / BaseURL）
  /// [prompt] 自定义提示词，为空时使用默认 kAiVisionPrompt
  /// 实现需处理：图片读取、编码、HTTP 调用、响应解析、错误转换、耗时统计
  Future<AiVisionResult> recognizeImage({
    required String imagePath,
    required AiCallConfig config,
    String? prompt,
  });

  /// 测试连接（用于设置页"测试"按钮）
  ///
  /// 子类应重写此方法，发送一个轻量请求验证 API Key 和网络连通性。
  /// 默认实现抛出未实现错误，避免空实现导致误报"连接成功"。
  Future<void> testConnection(AiCallConfig config) async {
    throw UnimplementedError('$type 未实现 testConnection');
  }

  // ============ 共享工具方法 ============

  /// 读取图片并 base64 编码。
  ///
  /// [imagePath] 有**两种形态**——照片地址本身就是双形态的，判定见
  /// `services/photo_service.dart` 的 [isInlinePhoto]：
  /// - 真机：应用文档目录下的文件绝对路径 → 用 `dart:io` 读文件；
  /// - Web：`data:image/<mime>;base64,<data>` 内联地址 → 直接切出 base64 段。
  ///
  /// 老实现一律 `File(imagePath)`：Web 上没有可用文件系统，内联地址会被当成
  /// 路径去查存在性，必然抛「图片文件不存在」，于是**所有供应商的 Web 识别
  /// 都死在这一步**。分流放在这里，6 个适配器共用同一方法即可一起修好。
  Future<({String base64, String mimeType, int bytesLength})> readImageAsBase64(
    String imagePath,
  ) async {
    if (isInlinePhoto(imagePath)) {
      // data:image/jpeg;base64,<data> —— mime 在冒号与分号之间，数据在逗号之后
      final comma = imagePath.indexOf(',');
      if (comma < 0) {
        throw AiException('图片数据格式不正确', providerId: type.name);
      }
      final header = imagePath.substring(0, comma);
      final payload = imagePath.substring(comma + 1);
      final semicolon = header.indexOf(';');
      return (
        base64: payload,
        mimeType: semicolon > 0
            ? header.substring(header.indexOf(':') + 1, semicolon)
            : 'image/jpeg',
        bytesLength: decodeInlinePhoto(imagePath).length,
      );
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw AiException('图片文件不存在', providerId: type.name);
    }
    final bytes = await file.readAsBytes();
    return (
      base64: base64Encode(bytes),
      mimeType: _guessMime(imagePath),
      bytesLength: bytes.length,
    );
  }

  String _guessMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// 把 DioException 转换为业务友好的 AiException
  AiException wrapDioError(DioException e) {
    final status = e.response?.statusCode;
    String msg;
    switch (status) {
      case 400:
        msg = '请求格式错误或 API Key 无效';
        break;
      case 401:
        msg = 'API Key 无效或已过期';
        break;
      case 403:
        msg = 'API Key 无权限，请检查是否启用了对应服务';
        break;
      case 429:
        msg = '请求过于频繁或额度已用尽，请稍后重试';
        break;
      case final int n when n >= 500:
        msg = '供应商服务端错误（$n），请稍后重试';
        break;
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          msg = '网络超时，请检查网络连接';
        } else if (e.type == DioExceptionType.connectionError) {
          msg = '无法连接服务，请检查网络或代理设置';
        } else {
          msg = e.response?.data.toString() ?? e.message ?? '请求失败';
        }
    }
    return AiException(msg, providerId: type.name, statusCode: status);
  }
}
