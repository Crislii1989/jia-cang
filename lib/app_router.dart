import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:jia_cang/constants/app_colors.dart';
import 'package:jia_cang/constants/app_skin.dart';
import 'package:jia_cang/screen/home/home_page.dart';
import 'package:jia_cang/screen/inventory/inventory_page.dart';
import 'package:jia_cang/screen/item_detail_page.dart';
import 'package:jia_cang/screen/storage/storage_page.dart';
import 'package:jia_cang/screen/category/category_page.dart';
import 'package:jia_cang/widgets/main_shell.dart';
import 'package:jia_cang/screen/splash_page.dart';
import 'package:jia_cang/screen/add_item_page.dart';
import 'package:jia_cang/screen/order_import/order_import_page.dart';
import 'package:jia_cang/screen/me/me_page.dart';
import 'package:jia_cang/screen/me/appearance_page.dart';
import 'package:jia_cang/screen/me/appearance_edit_page.dart';
import 'package:jia_cang/screen/me/data_backup_page.dart';
import 'package:jia_cang/screen/me/check_update_page.dart';
import 'package:jia_cang/screen/me/ai_settings_page.dart';
import 'package:jia_cang/screen/scan/scan_page.dart';

/// 给页面外套一层「跟随皮肤」的 key。
///
/// **为什么需要**：`const HomePage()` 这种页面，在祖辈（MaterialApp / Router）
/// 重建时会被 Element 复用——`updateChild` 里 `child.widget == newWidget`
/// 是同一个 const 规范化实例，直接短路，**连 build 都不会调用**；页面内部
/// 那些 `const _XxxSection()` 同理。所以「换配色 → 重建整棵树」对 const 子树
/// 完全无效，换肤后界面纹丝不动。
///
/// 挂上带 [AppColors.skinRevision] 的 key 之后，换肤时 key 变化 →
/// Element 重新挂载 → 整页（含所有 const 子块）按新配色重新 build。
/// 代价是换肤会重置当前页面的局部状态（滚动位置等）——低频操作，可接受。
///
/// [tag] 只是为了让不同路由的 key 不重名（同层级不会冲突，但便于调试）。
Widget _skinKeyed(String tag, Widget child) =>
    KeyedSubtree(key: ValueKey('$tag-${AppColors.skinRevision}'), child: child);

/// 创建应用路由。根据 [initialLocation] 决定启动页：首次启动显示 splash，否则直接进入首页。
GoRouter createAppRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => _skinKeyed('splash', const SplashPage()),
      ),
      GoRoute(
        path: '/add_item',
        builder: (context, state) => _skinKeyed(
          'add_item',
          AddItemPage(initialValues: state.extra as AddItemInitialValues?),
        ),
      ),
      GoRoute(
        path: '/edit_item/:id',
        builder: (context, state) => _skinKeyed(
          'edit_item',
          AddItemPage(itemId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/order-import',
        builder: (context, state) =>
            _skinKeyed('order_import', const OrderImportPage()),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) =>
            _skinKeyed('categories', const CategoryPage()),
      ),
      GoRoute(
        path: '/data-backup',
        builder: (context, state) =>
            _skinKeyed('data_backup', const DataBackupPage()),
      ),
      GoRoute(
        path: '/check-update',
        builder: (context, state) =>
            _skinKeyed('check_update', const CheckUpdatePage()),
      ),
      GoRoute(
        path: '/ai-settings',
        builder: (context, state) =>
            _skinKeyed('ai_settings', const AiSettingsPage()),
      ),
      // 外观（配色皮肤）：列表 + 新建/编辑
      GoRoute(
        path: '/appearance',
        builder: (context, state) =>
            _skinKeyed('appearance', const AppearancePage()),
      ),
      GoRoute(
        path: '/appearance-edit',
        builder: (context, state) {
          final args = state.extra as AppearanceEditArgs?;
          return _skinKeyed(
            'appearance_edit',
            // 没有 extra 时（比如直接输网址进来）以「新建」兜底，
            // 别抛异常——路由参数丢了也要能用
            AppearanceEditPage(
              args:
                  args ??
                  AppearanceEditArgs(
                    skin: AppSkins.draftFrom(AppColors.skin, name: '我的配色'),
                    isNew: true,
                  ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => _skinKeyed('scan', const ScanPage()),
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (context, state) => _skinKeyed(
          'detail',
          ItemDetailPage(itemId: state.pathParameters['id']!),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _skinKeyed('shell', MainShell(navigationShell: navigationShell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) =>
                    _skinKeyed('home', const HomePage()),
              ),
            ],
          ),
          // 物品库
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) =>
                    _skinKeyed('inventory', const InventoryPage()),
              ),
            ],
          ),
          // 收纳位置管理
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/storage',
                builder: (context, state) =>
                    _skinKeyed('storage', const StoragePage()),
              ),
            ],
          ),
          // 个人中心
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => _skinKeyed('me', const MePage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
