import 'package:bugsnag_flutter/bugsnag_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';
import 'constants/app_theme.dart';
import 'services/first_run_service.dart';
import 'services/encryption_service.dart';
import 'widgets/app_canvas.dart';
import 'widgets/db_gate.dart';
import 'utils/package_info_setup_web.dart'
    if (dart.library.io) 'utils/package_info_setup_io.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerPackageInfoPlus();

  // 手机端锁竖屏：全 App 按竖屏设计（悬浮条 / DesignMetrics 比例），
  // 横屏会拉出布局问题；桌面与 Web 端该调用是 no-op，不受影响。
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 加载 .env 配置文件（含 BUGSNAG_API_KEY 等敏感信息）
  // ⚠️ 这里踩过两次白屏，两点都必须容错：
  //   ① 部分静态托管会拦截点号开头的文件，assets/.env 直接返回 403/404；
  //   ② 加载失败后**再读 dotenv.env 会抛 NotInitializedError**（本次白屏真凶）。
  // 任一处抛出都会中断 main()，runApp() 不执行 → 纯白屏（已本地复现）。
  // Web 端整体跳过：Bugsnag 本就不支持 Web（MissingPluginException），
  // 跳过既无副作用，也省掉一次必然失败的 403 请求。
  var bugsnagApiKey = '';
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
      bugsnagApiKey = dotenv.env['BUGSNAG_API_KEY'] ?? '';
    } catch (e) {
      debugPrint('dotenv load skipped (.env unavailable): $e');
    }
  }

  // 启动 Bugsnag 崩溃监控，API Key 从 .env 读取
  // 注意：Bugsnag 仅支持 Android/iOS，Windows/Linux/macOS 会抛 MissingPluginException，
  // 必须 try-catch 否则会导致 runApp() 之前中断、窗口无法创建
  if (bugsnagApiKey.isNotEmpty) {
    try {
      await bugsnag.start(apiKey: bugsnagApiKey);
    } catch (e) {
      debugPrint('Bugsnag start skipped (platform unsupported): $e');
    }
  }

  await FirstRunService.init();
  await EncryptionService.instance.init();
  // 预加载首页背景图，避免首次渲染时闪烁
  await rootBundle.load('assets/icon/background1.jpg');
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _router = createAppRouter(
    initialLocation: FirstRunService.isFirstRun ? '/' : '/home',
  );

  @override
  Widget build(BuildContext context) {
    // DbGate：进入应用前先确认本地数据库能用。
    // 数据库连接挂起时界面会一直转圈、点击也没反应，
    // 这里把它变成一页能看懂、能自救的错误提示。
    return DbGate(
      child: MaterialApp.router(
        title: '家藏',
        theme: buildAppTheme(),
        // 应用纯中文：日期选择器等系统组件一并本地化为中文
        locale: const Locale('zh'),
        supportedLocales: const [Locale('zh'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
        // AppCanvas：宽视口（桌面 / 网页预览）把内容居中限宽到手机宽度。
        // 挂在 builder 上，所以所有路由与弹窗一并收敛；真机是 no-op。
        builder: (context, child) =>
            AppCanvas(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
