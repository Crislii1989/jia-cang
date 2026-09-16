import 'dart:js_interop';

/// Web 端：删除 drift 存放在 IndexedDB 里的数据库。
///
/// drift 在缺少 SharedArrayBuffer 的浏览器上会降级为 `sharedIndexedDb`
/// 存储实现，数据库以同名的 IndexedDB 记录保存（这里就是 `shiwuji`）。
/// 一旦该记录处于半打开 / 损坏状态，新的打开请求会永久挂起 ——
/// 所有查询都不返回、界面一直转圈、点击新增也没有任何反应。
/// 这种状态只能整库删除后重建，因此提供一个显式的清理入口。
Future<void> deleteLocalDatabase(String name) async {
  try {
    final factory = _indexedDb;
    if (factory == null) return;
    // 刻意不 await：若还有别的标签页持有该库的连接，
    // deleteDatabase 会一直处于 blocked 状态。这里发起删除后立刻返回，
    // 由调用方紧接着重载页面，用页面卸载来释放本标签页的连接。
    _IDBFactory(factory).deleteDatabase(name);
  } catch (_) {
    // 删除失败也要让调用方继续重载，用户可以再试一次
  }
}

/// 重载当前页面（清理数据库后使用）。
void reloadPage() => _reload();

@JS('indexedDB')
external JSObject? get _indexedDb;

@JS('location.reload')
external void _reload();

extension type _IDBFactory(JSObject _) implements JSObject {
  external JSObject deleteDatabase(String name);
}
