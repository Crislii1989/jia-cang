/// 桌面 / 移动端：SQLite 使用真实文件加上系统级文件锁，
/// 不存在 Web 端 IndexedDB 那种「连接悬挂后无法恢复」的问题，
/// 因此这里不删除任何文件（避免误伤真实数据），只由调用方重连数据库。
Future<void> deleteLocalDatabase(String name) async {}

/// 非 Web 端不需要靠重载页面来释放连接。
void reloadPage() {}
