import 'package:go_router/go_router.dart';
import 'package:jia_cang/screen/home_page.dart';
import 'package:jia_cang/screen/inventory_page.dart';
import 'package:jia_cang/screen/item_detail_page.dart';
import 'package:jia_cang/screen/storage_page.dart';
import 'package:jia_cang/screen/category_page.dart';
import 'package:jia_cang/widgets/main_shell.dart';
import 'package:jia_cang/screen/splash_page.dart';
import 'package:jia_cang/screen/add_item_page.dart';
import 'package:jia_cang/screen/order-import-page.dart';
import 'package:jia_cang/screen/me_page.dart';
import 'package:jia_cang/screen/me/data_backup_page.dart';
import 'package:jia_cang/screen/me/check_update_page.dart';
import 'package:jia_cang/screen/me/ai_settings_page.dart';
import 'package:jia_cang/screen/scan/scan_page.dart';

/// 创建应用路由。根据 [initialLocation] 决定启动页：首次启动显示 splash，否则直接进入首页。
GoRouter createAppRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/add_item',
        builder: (context, state) =>
            AddItemPage(initialValues: state.extra as AddItemInitialValues?),
      ),
      GoRoute(
        path: '/edit_item/:id',
        builder: (context, state) =>
            AddItemPage(itemId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/order-import',
        builder: (context, state) => const OrderImportPage(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoryPage(),
      ),
      GoRoute(
        path: '/data-backup',
        builder: (context, state) => const DataBackupPage(),
      ),
      GoRoute(
        path: '/check-update',
        builder: (context, state) => const CheckUpdatePage(),
      ),
      GoRoute(
        path: '/ai-settings',
        builder: (context, state) => const AiSettingsPage(),
      ),
      GoRoute(path: '/scan', builder: (context, state) => const ScanPage()),
      GoRoute(
        path: '/detail/:id',
        builder: (context, state) =>
            ItemDetailPage(itemId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          // 物品库
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryPage(),
              ),
            ],
          ),
          // 收纳位置管理
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/storage',
                builder: (context, state) => const StoragePage(),
              ),
            ],
          ),
          // 个人中心
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/me', builder: (context, state) => const MePage()),
            ],
          ),
        ],
      ),
    ],
  );
}
