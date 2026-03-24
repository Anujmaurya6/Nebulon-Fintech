import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/model/transaction_model.dart';
import '../data/dashboard_data_source.dart';
import '../../../core/utils/cache_manager.dart';
import '../../../core/utils/action_queue.dart';

class DashboardModel {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final double profitMargin;
  final double expenseRatio;
  final int transactionCount;
  final List<TransactionModel> recentTransactions;

  const DashboardModel({
    this.totalIncome = 0,
    this.totalExpenses = 0,
    this.balance = 0,
    this.profitMargin = 0,
    this.expenseRatio = 0,
    this.transactionCount = 0,
    this.recentTransactions = const [],
  });
}

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState {
  final DashboardStatus status;
  final DashboardModel data;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data = const DashboardModel(),
    this.errorMessage,
  });

  DashboardState copyWith({DashboardStatus? status, DashboardModel? data, String? errorMessage}) {
    return DashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardState> {
  final DashboardDataSource _dataSource = DashboardDataSource();

  @override
  DashboardState build() => const DashboardState();

  Future<void> loadDashboard() async {
    state = state.copyWith(status: DashboardStatus.loading);

    final result = await _dataSource.fetchDashboardData();

    if (result['error'] != null) {
      final cached = CacheManager.getDashboardCache();
      if (cached != null && cached is List) {
        state = state.copyWith(
          status: DashboardStatus.loaded,
          data: _computeStats(cached),
        );
        return;
      }
      state = state.copyWith(
        status: DashboardStatus.error,
        errorMessage: result['error'] as String,
      );
      return;
    }

    final data = result['data'] as List? ?? [];
    await CacheManager.saveDashboardCache(data);

    state = state.copyWith(
      status: DashboardStatus.loaded,
      data: _computeStats(data),
    );
  }

  DashboardModel _computeStats(List<dynamic> rawTransactions) {
    // 1. Convert raw transactions to models
    List<TransactionModel> transactions = rawTransactions
        .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // 2. Aggregate with pending offline actions for "Zero-Dummy" real-time feel
    final pendingActions = ActionQueue.getAll();
    for (final action in pendingActions) {
      if (action.method == 'POST' && action.data != null) {
        transactions.add(TransactionModel.fromJson(action.data!));
      } else if (action.method == 'DELETE') {
        final id = action.endpoint.split('eq.').last;
        transactions.removeWhere((t) => t.id == id);
      }
    }

    // 3. Compute stats
    double income = 0, expenses = 0;
    for (final tx in transactions) {
      if (tx.isIncome) {
        income += tx.amount;
      } else {
        expenses += tx.amount;
      }
    }

    final total = income + expenses;
    final balance = income - expenses;
    
    return DashboardModel(
      totalIncome: income,
      totalExpenses: expenses,
      balance: balance,
      profitMargin: total > 0 ? balance / total : 0,
      expenseRatio: income > 0 ? expenses / income : 0,
      transactionCount: transactions.length,
      recentTransactions: transactions.take(5).toList(),
    );
  }
}

final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
