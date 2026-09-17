import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 非 Web 平台：把旧名的 SQLite 数据库文件搬为新名。
///
/// drift_flutter 的 native 落盘是 `<目录>/<库名>.sqlite`（目录由
/// database.dart 传入的 getApplicationSupportDirectory 决定）。
/// 仅当旧文件存在且新文件不存在时复制一次；journal/WAL 伴生文件
/// 一并带上（不存在就跳过）。
///
/// 迁移是尽力而为的：任何一步失败都会静默放弃，**旧文件从不删除**
/// —— 最坏情况只是历史数据暂未带入新库，绝不会丢数据。
Future<void> migrateLegacyDatabaseStorage({
  required String legacyName,
  required String newName,
}) async {
  try {
    final dir = await getApplicationSupportDirectory();
    final old = File(p.join(dir.path, '$legacyName.sqlite'));
    if (!await old.exists()) return;
    final neu = File(p.join(dir.path, '$newName.sqlite'));
    if (await neu.exists()) return; // 已迁移过，或已在新库上产生数据

    await old.copy(neu.path);
    for (final suffix in const ['-journal', '-wal']) {
      final side = File(p.join(dir.path, '$legacyName.sqlite$suffix'));
      if (await side.exists()) {
        await side.copy(p.join(dir.path, '$newName.sqlite$suffix'));
      }
    }
  } catch (_) {
    // 静默失败：不阻断启动，见函数注释。
  }
}
