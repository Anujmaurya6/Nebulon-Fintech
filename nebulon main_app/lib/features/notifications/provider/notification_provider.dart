import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  final bool globalEnabled;
  final bool transactionsEnabled;
  final bool securityEnabled;
  final bool aiInsightsEnabled;
  final bool marketingEnabled;

  const NotificationSettings({
    this.globalEnabled = true,
    this.transactionsEnabled = true,
    this.securityEnabled = true,
    this.aiInsightsEnabled = true,
    this.marketingEnabled = false,
  });

  NotificationSettings copyWith({
    bool? globalEnabled,
    bool? transactionsEnabled,
    bool? securityEnabled,
    bool? aiInsightsEnabled,
    bool? marketingEnabled,
  }) {
    return NotificationSettings(
      globalEnabled: globalEnabled ?? this.globalEnabled,
      transactionsEnabled: transactionsEnabled ?? this.transactionsEnabled,
      securityEnabled: securityEnabled ?? this.securityEnabled,
      aiInsightsEnabled: aiInsightsEnabled ?? this.aiInsightsEnabled,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationSettings> {
  static const _prefix = 'notif_';

  @override
  NotificationSettings build() {
    _loadSettings();
    return const NotificationSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      globalEnabled: prefs.getBool('${_prefix}global') ?? true,
      transactionsEnabled: prefs.getBool('${_prefix}transactions') ?? true,
      securityEnabled: prefs.getBool('${_prefix}security') ?? true,
      aiInsightsEnabled: prefs.getBool('${_prefix}ai') ?? true,
      marketingEnabled: prefs.getBool('${_prefix}marketing') ?? false,
    );
  }

  Future<void> updateSettings({
    bool? globalEnabled,
    bool? transactionsEnabled,
    bool? securityEnabled,
    bool? aiInsightsEnabled,
    bool? marketingEnabled,
  }) async {
    state = state.copyWith(
      globalEnabled: globalEnabled,
      transactionsEnabled: transactionsEnabled,
      securityEnabled: securityEnabled,
      aiInsightsEnabled: aiInsightsEnabled,
      marketingEnabled: marketingEnabled,
    );

    final prefs = await SharedPreferences.getInstance();
    if (globalEnabled != null)
      await prefs.setBool('${_prefix}global', globalEnabled);
    if (transactionsEnabled != null)
      await prefs.setBool('${_prefix}transactions', transactionsEnabled);
    if (securityEnabled != null)
      await prefs.setBool('${_prefix}security', securityEnabled);
    if (aiInsightsEnabled != null)
      await prefs.setBool('${_prefix}ai', aiInsightsEnabled);
    if (marketingEnabled != null)
      await prefs.setBool('${_prefix}marketing', marketingEnabled);
  }

  Future<void> toggleGlobal(bool value) async {
    await updateSettings(globalEnabled: value);
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationSettings>(
      NotificationNotifier.new,
    );
