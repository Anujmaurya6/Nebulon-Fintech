import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/model/transaction_model.dart';
import '../data/dashboard_data_source.dart';
import '../../../core/utils/cache_manager.dart';
import '../../../core/utils/action_queue.dart';

import '../../../core/utils/local_db_manager.dart';

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

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardModel? data,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() => const DashboardState();

  Future<void> loadDashboard() async {
    // We can fetch synchronously from Hive, but keeping Future for API consistency
    final transactions = LocalDBManager.getAllTransactions();

    state = state.copyWith(
      status: DashboardStatus.loaded,
      data: _computeStats(transactions),
    );
  }

  DashboardModel _computeStats(List<TransactionModel> transactions) {
    // Compute stats directly from local models (includes both PENDING and SYNCED)
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
      recentTransactions: transactions.take(10).toList(),
    );
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
