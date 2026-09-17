import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart' as web;

/// Web 端：把旧名的本地数据库搬为新名。
///
/// drift 在 Web 上有两种落盘形态，改名迁移两种都要覆盖：
/// 1. **OPFS**（Chromium 系浏览器默认）：OPFS 根下 `drift_db/<库名>/`
///    目录，内含 `database`、可选的 `database-journal`，以及记录前两者
///    存在性的 2 字节 `meta` 文件（见 sqlite3 的 SimpleOpfsFileSystem）。
/// 2. **IndexedDB 降级**（浏览器无 OPFS 时）：sqlite3 的
///    IndexedDbFileSystem 以库名建 IDB 数据库，内含 `/database` 与
///    `/database-journal` 两个「文件」。
///
/// 迁移是尽力而为的：任何一步失败都会静默放弃，**旧库原样保留
/// （从不删除）**，新库按全新库打开 —— 最坏情况只是历史数据暂未
/// 带入新库，绝不会丢数据。
Future<void> migrateLegacyDatabaseStorage({
  required String legacyName,
  required String newName,
}) async {
  try {
    if (await _copyInOpfs(legacyName, newName)) return;
    await _copyFromIndexedDb(legacyName, newName);
  } catch (_) {
    // 静默失败：不阻断启动，见函数注释。
  }
}

/// OPFS 内旧库目录 → 新库目录的直接复制。
///
/// 返回 true 表示 OPFS 里存在旧库且已完成（或此前已完成）复制。
Future<bool> _copyInOpfs(String legacyName, String newName) async {
  final root = await _opfsRoot();
  if (root == null) return false;

  web.FileSystemDirectoryHandle driftRoot;
  web.FileSystemDirectoryHandle legacyDir;
  try {
    driftRoot = await root.getDirectoryHandle('drift_db').toDart;
    legacyDir = await driftRoot.getDirectoryHandle(legacyName).toDart;
  } on Object {
    return false; // OPFS 里没有旧库
  }

  // 新库目录已存在：已迁移过，或用户已在新版上产生数据，不再覆盖。
  try {
    await driftRoot.getDirectoryHandle(newName).toDart;
    return true;
  } on Object {
    // 继续首次迁移
  }

  final createDir = web.FileSystemGetDirectoryOptions(create: true);
  final createFile = web.FileSystemGetFileOptions(create: true);
  final newDir = await driftRoot.getDirectoryHandle(newName, createDir).toDart;

  var copiedMain = false;
  var copiedJournal = false;
  for (final entry in const ['database', 'database-journal']) {
    try {
      final handle = await legacyDir.getFileHandle(entry).toDart;
      final file = await handle.getFile().toDart;
      final bytes = (await file.arrayBuffer().toDart).toDart.asUint8List();
      final target = await newDir.getFileHandle(entry, createFile).toDart;
      final writable = await target
          .createWritable(web.FileSystemCreateWritableOptions(keepExistingData: false))
          .toDart;
      await writable.write(bytes.toJS).toDart;
      await writable.close().toDart;
      entry == 'database' ? copiedMain = true : copiedJournal = true;
    } on Object {
      // journal 可能不存在，跳过即可
    }
  }
  if (!copiedMain) return false;

  // 写 meta：两个字节分别标记主文件 / journal 是否存在
  final meta = Uint8List(2);
  meta[0] = 1;
  meta[1] = copiedJournal ? 1 : 0;
  final metaHandle = await newDir.getFileHandle('meta', createFile).toDart;
  final metaWriter = await metaHandle
      .createWritable(web.FileSystemCreateWritableOptions(keepExistingData: false))
      .toDart;
  await metaWriter.write(meta.toJS).toDart;
  await metaWriter.close().toDart;
  return true;
}

/// IndexedDB 降级形态的旧库 → 新库（或 OPFS 新库）的搬迁。
///
/// 读取走 sqlite3 的 IndexedDbFileSystem（与 drift 自身的
/// 「IndexedDB → OPFS」搬家工具同一套 API）；写入端优先 OPFS ——
/// 只要浏览器支持 OPFS，drift 打开新名数据库时也会优先选 OPFS，
/// 数据就能被读到；仅当 OPFS 完全不可用时才写入新名的 IDB VFS。
Future<void> _copyFromIndexedDb(String legacyName, String newName) async {
  Uint8List? mainBytes;
  Uint8List? journalBytes;
  final old = await IndexedDbFileSystem.open(dbName: legacyName);
  try {
    mainBytes = await _readVfsFile(old, '/database');
    journalBytes = await _readVfsFile(old, '/database-journal');
  } finally {
    await old.close();
  }
  if (mainBytes == null) return; // IDB 里没有旧库
  final main = mainBytes;

  final root = await _opfsRoot();
  if (root != null) {
    try {
      final driftRoot = await root
          .getDirectoryHandle('drift_db', web.FileSystemGetDirectoryOptions(create: true))
          .toDart;
      final newDir = await driftRoot
          .getDirectoryHandle(newName, web.FileSystemGetDirectoryOptions(create: true))
          .toDart;
      await _writeOpfsFile(newDir, 'database', main);
      if (journalBytes != null) {
        await _writeOpfsFile(newDir, 'database-journal', journalBytes);
      }
      final meta = Uint8List(2);
      meta[0] = 1;
      meta[1] = journalBytes != null ? 1 : 0;
      await _writeOpfsFile(newDir, 'meta', meta);
      return;
    } on Object {
      // OPFS 写入失败则尝试 IDB 写入
    }
  }

  final neu = await IndexedDbFileSystem.open(dbName: newName);
  try {
    const createFlags =
        SqlFlag.SQLITE_OPEN_CREATE | SqlFlag.SQLITE_OPEN_MAIN_DB;
    neu.xOpen(Sqlite3Filename('/database'), createFlags).file
      ..xWrite(main, 0)
      ..xClose();
    if (journalBytes != null) {
      neu.xOpen(Sqlite3Filename('/database-journal'), createFlags).file
        ..xWrite(journalBytes, 0)
        ..xClose();
    }
  } finally {
    await neu.close();
  }
}

/// 读取 IDB VFS 里的一个文件；不存在返回 null。
Future<Uint8List?> _readVfsFile(IndexedDbFileSystem vfs, String name) async {
  try {
    final handle = vfs.xOpen(Sqlite3Filename(name), 0);
    try {
      final size = handle.file.xFileSize();
      final bytes = Uint8List(size);
      handle.file.xRead(bytes, 0);
      return bytes;
    } finally {
      handle.file.xClose();
    }
  } on Object {
    return null;
  }
}

Future<void> _writeOpfsFile(
  web.FileSystemDirectoryHandle dir,
  String name,
  Uint8List bytes,
) async {
  final target = await dir
      .getFileHandle(name, web.FileSystemGetFileOptions(create: true))
      .toDart;
  final writable = await target
      .createWritable(web.FileSystemCreateWritableOptions(keepExistingData: false))
      .toDart;
  await writable.write(bytes.toJS).toDart;
  await writable.close().toDart;
}

Future<web.FileSystemDirectoryHandle?> _opfsRoot() async {
  try {
    return await web.window.navigator.storage.getDirectory().toDart;
  } on Object {
    return null;
  }
}
