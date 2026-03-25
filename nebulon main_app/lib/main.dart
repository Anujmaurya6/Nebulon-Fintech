import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'core/network/api_client.dart';
import 'screens/lock_screen.dart';
import 'screens/login_signup.dart';
import 'core/services/notification_service.dart';
import 'core/utils/action_queue.dart';
import 'core/network/sync_service.dart';

import 'core/utils/local_db_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('smart_vault_cache');
  await ActionQueue.init();
  await LocalDBManager.init();
  await NotificationService.init();

  runApp(const ProviderScope(child: SmartVaultApp()));
}

class SmartVaultApp extends ConsumerStatefulWidget {
  const SmartVaultApp({super.key});

  @override
  ConsumerState<SmartVaultApp> createState() => _SmartVaultAppState();
}

class _SmartVaultAppState extends ConsumerState<SmartVaultApp> {
  StreamSubscription<void>? _logoutSub;

  @override
  void initState() {
    super.initState();
    _logoutSub = ApiClient.onLogoutTrigger.listen((_) {
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _logoutSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Smart Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const LockScreen(child: SplashScreen()),
    );
  }
}
