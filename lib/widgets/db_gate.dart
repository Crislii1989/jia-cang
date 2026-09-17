import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../providers/database_provider.dart';
import '../utils/local_database_reset.dart' as reset;
import 'center_sheet.dart';
import 'gradient_background.dart';

/// 启动闸门：进入应用之前先确认本地数据库真的能用。
///
/// 为什么需要它：Web 端 drift 在缺少 SharedArrayBuffer 时会降级为
/// `sharedIndexedDb` 存储实现。一旦连接处于挂起状态（多个标签页抢同一份
/// IndexedDB、或历史版本遗留的悬挂连接），**所有查询既不返回也不报错** ——
/// 界面永远转圈、点「确认添加」没有任何反应。用户只能干等，无从判断。
///
/// 这里用一次带超时的探测把「静默挂起」变成看得见的错误页，
/// 并提供「重试」与「清理本地数据」两个自救入口。
class DbGate extends ConsumerWidget {
  final Widget child;

  const DbGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(databaseReadyProvider);

    return ready.when(
      data: (_) => child,
      loading: () => const _DbGatePage(
        emoji: '📦',
        title: '家藏',
        message: '正在打开本地数据…',
        busy: true,
      ),
      error: (error, _) => _DbGatePage(
        emoji: '⚠️',
        title: '本地数据打不开',
        message: _friendlyError(error),
        busy: false,
      ),
    );
  }

  /// 把技术异常翻译成用户能看懂、且指向解决办法的提示。
  String _friendlyError(Object error) {
    final raw = error.toString();
    if (raw.contains('TimeoutException')) {
      return '尝试打开本地数据库超过 '
          '${kDatabaseOpenTimeout.inSeconds} 秒仍无响应。\n\n'
          '常见原因：\n'
          '· 同一个地址开了多个标签页，互相锁住了本地数据；\n'
          '· 浏览器里残留了旧版本留下的坏连接。\n\n'
          '可以先关掉其他标签页再点「重试」；'
          '如果仍然不行，用「清理本地数据」重建。';
    }
    return '读取本地数据时出错：\n$raw';
  }
}

class _DbGatePage extends ConsumerWidget {
  final String emoji;
  final String title;
  final String message;
  final bool busy;

  const _DbGatePage({
    required this.emoji,
    required this.title,
    required this.message,
    required this.busy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 闸门位于 MaterialApp 之上，出错页需要自带一套 Material 环境
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '家藏',
      theme: ThemeData(primarySwatch: Colors.amber),
      home: Scaffold(
        body: GradientBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 44)),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (busy)
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.coral,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowCard,
                          blurRadius: 14,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.7,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (!busy) ...[
                    const SizedBox(height: 22),
                    _GateButton(
                      label: '重试',
                      filled: true,
                      onTap: () => ref
                          .read(databaseRecoveryProvider.notifier)
                          .reconnect(),
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 10),
                      _GateButton(
                        label: '清理本地数据并重载',
                        filled: false,
                        onTap: () => _confirmReset(context, ref),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await CenterSheetConfirm.show<bool>(
      context: context,
      title: '清理本地数据',
      message:
          '将删除浏览器中保存的全部本地数据（房间、柜体、物品等），'
          '然后重新载入应用。此操作不可撤销。\n\n'
          '仅在「重试」也打不开数据库时才需要这样做。',
      confirmLabel: '确认清理',
      danger: true,
      result: true,
    );
    if (ok != true) return;

    await ref.read(databaseRecoveryProvider.notifier).resetLocalData();
    // 必须整页重载才能彻底释放旧的 Web 数据库连接
    reset.reloadPage();
  }
}

class _GateButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _GateButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          // 主按钮 = 实心珊瑚（稿子 `.btn.primary` 无渐变），次要按钮 = 白底细粉线
          color: filled ? AppColors.btnPrimaryBg : AppColors.btnGhostBg,
          borderRadius: BorderRadius.circular(16),
          border: filled
              ? null
              : Border.all(
                  color: AppColors.btnGhostBorder,
                  width: AppColors.btnGhostBorderWidth,
                ),
          boxShadow: filled
              ? const [
                  BoxShadow(
                    color: AppColors.btnPrimaryShadow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: filled ? AppColors.btnPrimaryFg : AppColors.btnGhostFg,
            ),
          ),
        ),
      ),
    );
  }
}
