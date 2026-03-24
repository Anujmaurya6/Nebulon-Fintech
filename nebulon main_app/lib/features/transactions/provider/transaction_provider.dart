import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_data_source.dart';
import '../model/transaction_model.dart';
import '../../../core/utils/action_queue.dart';
import '../../../core/network/connectivity_service.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/notification_service.dart';
import 'package:intl/intl.dart';


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

  double get totalIncome =>
      transactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses =>
      transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpenses;
}

class TransactionNotifier extends Notifier<TransactionState> {
  final TransactionDataSource _dataSource = TransactionDataSource();
  final _uuid = const Uuid();

  @override
  TransactionState build() => const TransactionState();

  Future<void> loadTransactions() async {
    state = state.copyWith(status: TransactionStatus.loading);
    final result = await _dataSource.getTransactions();

    if (result['error'] != null) {
      state = state.copyWith(
        status: TransactionStatus.error,
        errorMessage: result['error'] as String,
      );
      return;
    }

    final List<dynamic> data = result['data'] as List? ?? [];
    final transactions = data.map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e))).toList();
    
    state = state.copyWith(
      status: TransactionStatus.loaded,
      transactions: transactions,
    );
  }

  Future<bool> addTransaction(TransactionModel tx) async {
    final isConnected = ref.read(connectivityProvider) == ConnectivityStatus.isConnected;
    
    // Optimistic Update
    final optimisticTx = tx.id == null ? tx.copyWith(id: _uuid.v4()) : tx;
    state = state.copyWith(transactions: [optimisticTx, ...state.transactions]);

    if (isConnected) {
      final result = await _dataSource.addTransaction(tx.toJson());
      if (result['error'] != null) {
        // Rollback on error
        await loadTransactions();
        return false;
      }
    } else {
      // Queue for sync
      final action = OfflineAction(
        id: _uuid.v4(),
        endpoint: '/rest/v1/transactions',
        method: 'POST',
        data: tx.toJson(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
    
    NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Vault Entry Secured',
      body: '${toBeginningOfSentenceCase(tx.type)} of ₹${tx.amount.toInt()} added to vault.',
    );
    
    return true;
  }


  Future<bool> deleteTransaction(String id) async {
    final isConnected = ref.read(connectivityProvider) == ConnectivityStatus.isConnected;
    
    // Optimistic Update
    final originalList = state.transactions;
    state = state.copyWith(transactions: state.transactions.where((t) => t.id != id).toList());

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
    NotifierProvider<TransactionNotifier, TransactionState>(TransactionNotifier.new);
