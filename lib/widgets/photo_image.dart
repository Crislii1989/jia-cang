/// 照片渲染工具。
///
/// 照片地址有两种形态（见 `isInlinePhoto`）：
/// - 真机：应用文档目录下的文件路径 → `FileImage` / `Image.file`
/// - Web：`data:image/...;base64,...` 内联地址 → `MemoryImage` / `Image.memory`
///
/// 所有展示照片的地方都应经这里，不要直接写 `Image.file(File(path))`，
/// 否则在 Web 上一律渲染失败（`dart:io` 的文件读写不可用）。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/photo_service.dart';

/// 内联图片字节缓存。
///
/// data URL 的 base64 解码有成本（单张可能几 MB），而 Widget 的重建很频繁，
/// 因此按地址缓存解码结果。同一份 [Uint8List] 实例还能让 [MemoryImage]
/// 的相等性判断保持稳定，避免每帧都重新解码纹理。
final Map<String, Uint8List> _inlineBytesCache = <String, Uint8List>{};

Uint8List _inlineBytes(String source) {
  return _inlineBytesCache.putIfAbsent(
    source,
    () => decodeInlinePhoto(source),
  );
}

/// 把照片地址转成 [ImageProvider]（供 `PhotoView` / `DecorationImage` 等使用）。
ImageProvider photoImageProvider(String source) {
  if (isInlinePhoto(source)) return MemoryImage(_inlineBytes(source));
  return FileImage(File(source));
}

/// 统一渲染一张照片：自动区分内联地址与文件路径，并处理加载失败。
class PhotoImage extends StatelessWidget {
  /// 照片地址（文件路径或内联 data URL）
  final String source;

  /// 填充方式，默认铺满
  final BoxFit fit;

  /// 加载失败时的兜底内容
  final Widget Function(BuildContext context, Object error, StackTrace? stack)?
  errorBuilder;

  /// 图片对齐方式，透传给底层 Image
  final AlignmentGeometry alignment;

  const PhotoImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (isInlinePhoto(source)) {
      return Image.memory(
        _inlineBytes(source),
        fit: fit,
        alignment: alignment,
        errorBuilder: errorBuilder,
        gaplessPlayback: true,
      );
    }
    return Image.file(
      File(source),
      fit: fit,
      alignment: alignment,
      errorBuilder: errorBuilder,
    );
  }
}
