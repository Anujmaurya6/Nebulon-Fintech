import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_data_source.dart';
import '../model/transaction_model.dart';
import '../../../core/utils/action_queue.dart';
import '../../../core/network/connectivity_service.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/notification_service.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/local_db_manager.dart';

enum TransactionStatus { initial, loading, loaded, error }

class TransactionState {
  final TransactionStatus status;
  final List<TransactionModel> transactions;
  final String? errorMessage;

  const TransactionState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.errorMessage,
  });

  TransactionState copyWith({
    TransactionStatus? status,
    List<TransactionModel>? transactions,
    String? errorMessage,
  }) {
    return TransactionState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage,
    );
  }

  double get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpenses;

  Map<String, double> get categoryExpenses {
    final expenses = transactions.where((t) => t.isExpense);
    final map = <String, double>{};
    for (var t in expenses) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  String get topCategory {
    final catMap = categoryExpenses;
    if (catMap.isEmpty) return 'None';
    return catMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String get spendingTrend {
    final now = DateTime.now();
    final currentMonthExpenses = transactions
        .where(
          (t) =>
              t.isExpense &&
              t.createdAt != null &&
              t.createdAt!.month == now.month &&
              t.createdAt!.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;

    final lastMonthExpenses = transactions
        .where(
          (t) =>
              t.isExpense &&
              t.createdAt != null &&
              t.createdAt!.month == lastMonth &&
              t.createdAt!.year == lastMonthYear,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    if (lastMonthExpenses == 0) return 'Stable';
    if (currentMonthExpenses > lastMonthExpenses) {
      return 'Increasing';
    } else if (currentMonthExpenses < lastMonthExpenses) {
      return 'Decreasing';
    }
    return 'Stable';
  }
}

class TransactionNotifier extends Notifier<TransactionState> {
  final TransactionDataSource _dataSource = TransactionDataSource();
  final _uuid = const Uuid();

  @override
  TransactionState build() => const TransactionState();

  Future<void> loadTransactions() async {
    final transactions = LocalDBManager.getAllTransactions();
    state = state.copyWith(
      status: TransactionStatus.loaded,
      transactions: transactions,
    );
  }

  Future<void> seedDummyData() async {
    // ... skipped seed dummy ...
  }

  Future<bool> addTransaction(TransactionModel tx) async {
    final isConnected =
        ref.read(connectivityProvider) == ConnectivityStatus.isConnected;

    final txId = tx.id ?? _uuid.v4();
    
    // Always save LOCALLY FIRST as PENDING
    final pendingTx = tx.copyWith(id: txId, syncStatus: 'PENDING');
    await LocalDBManager.saveTransaction(pendingTx);
    
    // Update state to reflect local DB
    await loadTransactions();

    if (isConnected) {
      final result = await _dataSource.addTransaction(pendingTx.toJson());
      if (result['error'] == null) {
        // Success! Mark synced
        await LocalDBManager.markAsSynced(txId);
        await loadTransactions();
      } else {
        // Leave as PENDING for SyncService
      }
    } else {
      // Leave as PENDING for SyncService
    }

    NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Vault Entry Secured',
      body:
          '${toBeginningOfSentenceCase(tx.type)} of ₹${tx.amount.toInt()} added to vault.',
    );

    return true; // We always return true for local-first optimism
  }

  Future<bool> deleteTransaction(String id) async {
    final isConnected =
        ref.read(connectivityProvider) == ConnectivityStatus.isConnected;

    // Optimistic Update
    final originalList = state.transactions;
    state = state.copyWith(
      transactions: state.transactions.where((t) => t.id != id).toList(),
    );

    if (isConnected) {
      final result = await _dataSource.deleteTransaction(id);
      if (result['error'] != null) {
        // Rollback
        state = state.copyWith(transactions: originalList);
        return false;
      }
    } else {
      // Queue for sync
      final action = OfflineAction(
        id: _uuid.v4(),
        endpoint: '/rest/v1/transactions?id=eq.$id',
        method: 'DELETE',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await ActionQueue.enqueue(action);
    }

    return true;
  }
}

final transactionProvider =
    NotifierProvider<TransactionNotifier, TransactionState>(
      TransactionNotifier.new,
    );
