import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import '../daos/item_dao.dart';
import '../daos/room_dao.dart';
import '../daos/cabinet_dao.dart';
import '../daos/slot_dao.dart';
import '../daos/import_history_dao.dart';
import '../daos/category_dao.dart';
import '../daos/settings_dao.dart';
import '../utils/local_database_reset.dart' as reset;

part 'generated/database_provider.g.dart';

/// 数据库实例 Provider
///
/// 必须 keepAlive：数据库连接的生命周期应与整个 App 一致，而不是跟着页面走。
/// 若使用 autoDispose，当某个页面（如收纳页按浏览维度分支 watch 不同 provider）
/// 切换视图导致依赖链短暂失效时，本 provider 会被销毁并 close()，随后又被重建、
/// 重新打开同一个数据库文件。在 Web 端（drift 降级到 sharedIndexedDb 时尤其明显）
/// 「上一个连接尚未完全释放就重开」会互相锁死，所有查询永久挂起，
/// 界面表现为一直转圈、写入成功也不刷新。
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  // close() 在连接处于半打开状态时可能抛错；这里忽略它，
  // 避免 provider 销毁过程中冒出未处理异常。
  ref.onDispose(() => db.close().ignore());
  return db;
}

/// 打开本地数据库允许等待的最长时间。
///
/// Web 端首次打开需要下载 sqlite3.wasm / drift_worker.js 并初始化
/// IndexedDB 存储，慢一些是正常的；本地预览环境 20 秒足够。
const Duration kDatabaseOpenTimeout = Duration(seconds: 20);

/// 数据库可用性探测（带超时）。
///
/// 存在的意义是「把静默挂起变成看得见的问题」：
/// 一旦 Web 端 drift 的连接挂起（多标签页抢同一份 IndexedDB、
/// 或历史版本遗留的悬挂连接），所有查询都不会返回也不报错 ——
/// 界面永远转圈、点新增没有任何反应，用户完全无从判断。
/// 启动闸门 DbGate 依赖本 provider，超时后给出重连 / 重建的入口。
@Riverpod(keepAlive: true)
Future<void> databaseReady(Ref ref) async {
  final db = ref.watch(databaseProvider);
  await db.customSelect('SELECT 1').get().timeout(kDatabaseOpenTimeout);
}

/// 数据库异常时的恢复操作（供 DbGate 的出错界面调用）。
@Riverpod(keepAlive: true)
class DatabaseRecovery extends _$DatabaseRecovery {
  @override
  Future<void> build() async {}

  /// 重试：丢弃当前（可能已挂起的）连接并重新打开，保留本地数据。
  void reconnect() {
    ref.invalidate(databaseProvider);
  }

  /// 重建：先删掉本地数据库文件再重新连接。
  ///
  /// Web 端会清空预览数据 —— 只有连接已经坏到重连也救不回来时才需要，
  /// 因此调用方必须给出明确的二次确认。
  Future<void> resetLocalData() async {
    await reset.deleteLocalDatabase(AppDatabase.databaseName);
    ref.invalidate(databaseProvider);
  }
}

/// DAO Providers
@riverpod
ItemDao itemDao(Ref ref) => ItemDao(ref.watch(databaseProvider));

@riverpod
RoomDao roomDao(Ref ref) => RoomDao(ref.watch(databaseProvider));

@riverpod
CabinetDao cabinetDao(Ref ref) => CabinetDao(ref.watch(databaseProvider));

@riverpod
SlotDao slotDao(Ref ref) => SlotDao(ref.watch(databaseProvider));

@riverpod
ImportHistoryDao importHistoryDao(Ref ref) =>
    ImportHistoryDao(ref.watch(databaseProvider));

@riverpod
CategoryDao categoryDao(Ref ref) => CategoryDao(ref.watch(databaseProvider));

@riverpod
SettingsDao settingsDao(Ref ref) => SettingsDao(ref.watch(databaseProvider));
