import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../../screens/dashboard_screen.dart';
import '../utils/error_handler.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final BuildContext context;

  DeepLinkService(this.context);

  void init() {
    // Check initial link if app was closed
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLink(uri);
    });

    // Listen to incoming links while app is open
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) async {
    // Debug log for troubleshooting
    print('DEEP LINK RECEIVED: $uri');

    // Handle both mobile (myapp://) and web (https://...)
    final isAuthCallback =
        (uri.scheme == 'myapp' &&
            uri.host == 'auth' &&
            uri.path == '/callback') ||
        (uri.scheme == 'https' || uri.scheme == 'http');

    if (isAuthCallback) {
      // Check for token in query parameters (Supabase/GoTrue style)
      // Note: Some providers use fragments (#), AppLinks should handle both if configured
      String? token =
          uri.queryParameters['token'] ?? uri.queryParameters['access_token'];

      if (token != null && token.isNotEmpty) {
        final apiClient = ApiClient();
        await apiClient.saveToken(token);

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
