import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class OfflineAction {
  final String id;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? data;
  final int timestamp;

  OfflineAction({
    required this.id,
    required this.endpoint,
    required this.method,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'endpoint': endpoint,
    'method': method,
    'data': data,
    'timestamp': timestamp,
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    id: json['id'],
    endpoint: json['endpoint'],
    method: json['method'],
    data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    timestamp: json['timestamp'],
  );
}

class ActionQueue {
  static const String _boxName = 'offline_actions';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  static Future<void> enqueue(OfflineAction action) async {
    await _box.put(action.id, jsonEncode(action.toJson()));
  }

  static List<OfflineAction> getAll() {
    return _box.values
        .map((v) => OfflineAction.fromJson(jsonDecode(v)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static Future<void> remove(String id) async {
    await _box.delete(id);
  }

  static Future<void> clear() async {
    await _box.clear();
  }

  static bool get isEmpty => _box.isEmpty;
}
