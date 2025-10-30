import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/background_task_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await NotificationService.initialize();
  await BackgroundTaskService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale locale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?._setLocale(locale);
  }

  // ✅ Thêm lại method này cho đổi ngôn ngữ
  static void setLocaleGlobal(Locale locale) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
      state?._setLocale(locale);
    }
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale? _locale;

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAlertsOnStartup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAlertsOnStartup();
    }
  }

  Future<void> _checkAlertsOnStartup() async {
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) return;

      final alerts = await ApiService.getProcrastinationAlerts();

      if (alerts.isEmpty) {
        debugPrint('✅ Không có alerts mới');
        return;
      }

      debugPrint('🔔 Tìm thấy ${alerts.length} alerts');

      for (final alert in alerts) {
        final habitName = alert['habit']?['ten_thoi_quen'] ?? 'Thói quen';
        final message = alert['message'] ?? 'Bạn có thông báo trì hoãn';
        final severity = alert['severity'] ?? 'info';

        String emoji = '📌';
        if (severity == 'critical') {
          emoji = '🔥';
        } else if (severity == 'warning') {
          emoji = '⚠️';
        } else if (severity == 'info') {
          emoji = '💡';
        }

        await NotificationService.showNotification(
          title: '$emoji $habitName',
          body: message,
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking alerts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit App',
      navigatorKey: navigatorKey,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales, // ✅ Sửa lại
      localizationsDelegates: const [
        AppLocalizations.delegate, // ✅ Thêm lại
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: FutureBuilder<String?>(
        future: ApiService.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final token = snapshot.data;
          return (token != null && token.isNotEmpty)
              ? const MainScreen()
              : const LoginScreen();
        },
      ),
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/main': (ctx) => const MainScreen(),
      },
    );
  }
}
