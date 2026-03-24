import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/api_constants.dart';

class CacheManager {
  static const String _boxName = 'nebulon_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  /// Save data to cache
  static Future<void> saveData(String key, dynamic data) async {
    final jsonString = jsonEncode(data);
    await _box.put(key, jsonString);
    await _box.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached data
  static dynamic getData(String key) {
    final jsonString = _box.get(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString);
  }

  /// Check if cache is still valid (within maxAge)
  static bool isCacheValid(String key, {Duration maxAge = const Duration(minutes: 5)}) {
    final timestamp = _box.get('${key}_timestamp');
    if (timestamp == null) return false;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) < maxAge;
  }

  /// Get cached dashboard data
  static dynamic getDashboardCache() => getData(ApiConstants.dashboardCacheKey);
  static Future<void> saveDashboardCache(dynamic data) =>
      saveData(ApiConstants.dashboardCacheKey, data);

  /// Get cached transactions
  static dynamic getTransactionsCache() => getData(ApiConstants.transactionsCacheKey);
  static Future<void> saveTransactionsCache(dynamic data) =>
      saveData(ApiConstants.transactionsCacheKey, data);

  /// Clear all cache
  static Future<void> clearAll() async {
    await _box.clear();
  }
}
