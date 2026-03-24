import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'package:nebulon_main_app/core/network/api_client.dart';
import 'screens/lock_screen.dart';
import 'screens/login_signup.dart';
import 'core/services/notification_service.dart';
import 'core/utils/action_queue.dart';
import 'core/network/sync_service.dart';




final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('nebulon_cache');
  await ActionQueue.init();
  await NotificationService.init();


  runApp(
    const ProviderScope(
      child: NebulonApp(),
    ),
  );
}

class NebulonApp extends ConsumerStatefulWidget {
  const NebulonApp({super.key});

  @override
  ConsumerState<NebulonApp> createState() => _NebulonAppState();
}

class _NebulonAppState extends ConsumerState<NebulonApp> {
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
    // Initialize SyncService globally
    ref.read(syncServiceProvider);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Nebulon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LockScreen(child: SplashScreen()),
    );

  }
}
