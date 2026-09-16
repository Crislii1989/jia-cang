import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// 单张照片在表单中的状态
enum PhotoStatus { uploading, success, failed }

/// 表单中的照片条目。
///
/// [path] 是照片的「地址」——真机上是应用文档目录下的文件绝对路径，
/// Web 上是 `data:image/...;base64,...` 形式的内联地址（见 [isInlinePhoto]）。
class PhotoEntry {
  final String path;
  final PhotoStatus status;
  const PhotoEntry({required this.path, required this.status});

  PhotoEntry copyWith({String? path, PhotoStatus? status}) =>
      PhotoEntry(path: path ?? this.path, status: status ?? this.status);
}

/// 照片处理结果
class PickResult {
  final List<PhotoEntry> entries; // 本次成功加入的照片
  final String? error; // 校验失败原因（格式/大小超限等）

  const PickResult({this.entries = const [], this.error});
}

/// 判断照片地址是否为内联 data URL。
///
/// Web 端没有可供 dart:io 读写的文件系统，照片改为把字节以 base64
/// 内联进同一条记录；真机仍是文件路径。两种形态共用 `Item.photos`
/// 这一个字符串列表字段，所有渲染点都必须先判定再决定
/// 用 `Image.memory` 还是 `Image.file`（见 `widgets/photo_image.dart`）。
bool isInlinePhoto(String source) => source.startsWith('data:image/');

/// 把内联 data URL 还原成图片字节。非内联地址返回空。
Uint8List decodeInlinePhoto(String source) {
  final comma = source.indexOf(',');
  if (comma < 0) return Uint8List(0);
  try {
    return base64Decode(source.substring(comma + 1));
  } catch (_) {
    return Uint8List(0);
  }
}

/// 把图片字节包装成内联 data URL。
String inlinePhotoSource(Uint8List bytes, String format) {
  final mime = format == 'png' ? 'image/png' : 'image/jpeg';
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

/// 照片服务：负责选图、校验、落盘（真机）或内联编码（Web）。
///
/// 约束：仅接受 JPG/PNG，单张不超过 5MB，每次最多补齐到上限。
class PhotoService {
  PhotoService._();
  static final PhotoService instance = PhotoService._();

  static const int maxPhotos = 10;
  static const int maxBytes = 5 * 1024 * 1024; // 5MB

  final _picker = ImagePicker();
  final _uuid = const Uuid();

  /// 从相册多选照片，返回可用的照片地址条目。
  /// [remaining] 为当前还能添加几张（上限 - 已有数）。
  /// 注意：当 remaining=1 时使用 pickImage（单选），因为 pickMultiImage 要求 limit>=2。
  Future<PickResult> pickFromGallery({required int remaining}) async {
    if (remaining <= 0) {
      return const PickResult(error: '最多添加 $maxPhotos 张照片');
    }

    if (remaining == 1) {
      // pickMultiImage 要求 limit>=2，单选时使用 pickImage
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return const PickResult();
      return _accept(x);
    }

    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      limit: remaining,
    );
    if (picked.isEmpty) return const PickResult();

    final entries = <PhotoEntry>[];
    String? error;

    for (final x in picked) {
      final result = await _accept(x);
      if (result.error != null) {
        error = result.error;
        continue;
      }
      entries.addAll(result.entries);
    }

    return PickResult(entries: entries, error: error);
  }

  /// 调用相机拍摄单张照片。
  Future<PickResult> pickFromCamera() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x == null) return const PickResult();
    return _accept(x);
  }

  /// 校验并落地单张照片。
  ///
  /// 校验与保存都基于「读出来的字节」，而不是文件路径后缀：
  /// Web 端选图返回的是 blob 地址，根本没有后缀，按后缀判断会把
  /// 合法的 jpg/png 一并拒掉（用户看到的就是「选了 png 却说仅支持 JPG/PNG」）。
  Future<PickResult> _accept(XFile file) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      return const PickResult(error: '图片读取失败，请重试');
    }

    final format = _detectFormat(file, bytes);
    if (format == null) {
      return const PickResult(error: '仅支持 JPG / PNG 格式');
    }
    if (bytes.length > maxBytes) {
      return const PickResult(error: '单张照片不能超过 5MB');
    }

    final stored = await _store(bytes, format);
    if (stored == null) {
      return const PickResult(error: '图片保存失败，请重试');
    }
    return PickResult(
      entries: [PhotoEntry(path: stored, status: PhotoStatus.success)],
    );
  }

  /// 识别图片真实格式，返回 'jpg' / 'png'，无法识别返回 null。
  ///
  /// 依次尝试三条线索，任一命中即返回：
  /// 1. 文件名后缀（`XFile.name` 在 Web 上仍是用户选的原始文件名）；
  /// 2. MIME 类型；
  /// 3. 字节魔数 —— 最可靠的一条，后缀/MIME 都可能缺失或造假。
  String? _detectFormat(XFile file, Uint8List bytes) {
    for (final candidate in [file.name, file.path]) {
      final ext = p.extension(candidate).toLowerCase();
      if (ext == '.jpg' || ext == '.jpeg') return 'jpg';
      if (ext == '.png') return 'png';
    }

    final mime = file.mimeType?.toLowerCase() ?? '';
    if (mime == 'image/jpeg' || mime == 'image/jpg') return 'jpg';
    if (mime == 'image/png') return 'png';

    if (_hasPngSignature(bytes)) return 'png';
    if (_hasJpegSignature(bytes)) return 'jpg';
    return null;
  }

  /// PNG 魔数：89 50 4E 47 0D 0A 1A 0A
  bool _hasPngSignature(Uint8List b) {
    const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (b.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (b[i] != signature[i]) return false;
    }
    return true;
  }

  /// JPEG 魔数：FF D8 FF
  bool _hasJpegSignature(Uint8List b) {
    return b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;
  }

  /// 落地照片：
  /// - Web：编码成内联 data URL 直接返回（浏览器无本地文件系统可用）；
  /// - 真机：写入应用文档目录下的 item_photos 子目录，返回新路径。
  Future<String?> _store(Uint8List bytes, String format) async {
    if (kIsWeb) return inlinePhotoSource(bytes, format);

    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'item_photos'));
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      final dest = p.join(dir.path, '${_uuid.v4()}.$format');
      await File(dest).writeAsBytes(bytes, flush: true);
      return dest;
    } catch (_) {
      return null;
    }
  }

  /// 删除已被移除的照片（编辑模式下清理孤儿文件）。
  /// 内联地址没有对应文件，直接忽略。
  Future<void> deleteFile(String path) async {
    if (isInlinePhoto(path)) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
