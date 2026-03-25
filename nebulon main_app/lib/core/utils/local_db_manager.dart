import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/transactions/model/transaction_model.dart';
import 'package:logger/logger.dart';

class LocalDBManager {
  static const String boxName = 'transactions_local';
  static final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  static Future<void> init() async {
    await Hive.openBox<String>(boxName);
    _logger.i('Local DB initialized successfully.');
  }

  static Future<void> saveTransaction(TransactionModel tx) async {
    final box = Hive.box<String>(boxName);
    await box.put(tx.id, jsonEncode(tx.toJson()));
    _logger.d('Saved local transaction: ${tx.id} [${tx.syncStatus}]');
  }

  static Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final box = Hive.box<String>(boxName);
    final Map<String, String> entries = {
      for (var tx in transactions) 
        if (tx.id != null) tx.id!: jsonEncode(tx.toJson())
    };
    await box.putAll(entries);
  }

  static List<TransactionModel> getAllTransactions() {
    try {
      final box = Hive.box<String>(boxName);
      final list = box.values
          .map((str) => TransactionModel.fromJson(jsonDecode(str)))
          .toList();
          
      // Ensure latest transactions display first
      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.now();
        final dateB = b.createdAt ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      return list;
    } catch (e) {
      _logger.e('Failed to read from local DB: $e');
      return [];
    }
  }

  static List<TransactionModel> getPendingTransactions() {
    return getAllTransactions()
        .where((tx) => tx.syncStatus == 'PENDING')
        .toList();
  }

  static Future<void> markAsSynced(String id) async {
    final box = Hive.box<String>(boxName);
    final str = box.get(id);
    if (str != null) {
      final tx = TransactionModel.fromJson(jsonDecode(str));
      final updated = tx.copyWith(syncStatus: 'SYNCED');
      await box.put(id, jsonEncode(updated.toJson()));
      _logger.d('Transaction marked as SYNCED: $id');
    }
  }
}
