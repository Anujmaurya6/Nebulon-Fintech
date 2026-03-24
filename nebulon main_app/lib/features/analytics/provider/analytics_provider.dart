import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_data_source.dart';

class AnalyticsModel {
  final Map<String, double> categoryBreakdown;
  final Map<String, double> incomeTrend;
  final Map<String, double> expenseTrend;
  final int totalTransactions;
  final double totalIncome;
  final double totalExpense;
  final double savingsRate;

  const AnalyticsModel({
    this.categoryBreakdown = const {},
    this.incomeTrend = const {},
    this.expenseTrend = const {},
    this.totalTransactions = 0,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.savingsRate = 0,
  });
}

enum AnalyticsStatus { initial, loading, loaded, error }

class AnalyticsState {
  final AnalyticsStatus status;
  final AnalyticsModel data;
  final String? errorMessage;

  const AnalyticsState({
    this.status = AnalyticsStatus.initial,
    this.data = const AnalyticsModel(),
    this.errorMessage,
  });

  AnalyticsState copyWith({AnalyticsStatus? status, AnalyticsModel? data, String? errorMessage}) {
    return AnalyticsState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

class AnalyticsNotifier extends Notifier<AnalyticsState> {
  final AnalyticsDataSource _dataSource = AnalyticsDataSource();

  @override
  AnalyticsState build() => const AnalyticsState();

  Future<void> loadAnalytics() async {
    state = state.copyWith(status: AnalyticsStatus.loading);

    final result = await _dataSource.fetchTransactionsForAnalytics();

    if (result['error'] != null) {
      state = state.copyWith(status: AnalyticsStatus.error, errorMessage: result['error'] as String);
      return;
    }

    final transactions = result['data'] as List? ?? [];
    final Map<String, double> categories = {};
    final Map<String, double> incomeTrend = {};
    final Map<String, double> expenseTrend = {};
    double totalIncome = 0;
    double totalExpense = 0;

    for (final tx in transactions) {
      final amount = (tx['amount'] ?? 0).toDouble();

      final type = tx['type']?.toString().toLowerCase() ?? 'expense';
      final category = tx['category']?.toString() ?? 'Other';
      final dateStr = tx['date']?.toString() ?? tx['created_at']?.toString() ?? '';
      
      // Format month as YYYY-MM for trend
      final month = dateStr.length >= 7 ? dateStr.substring(0, 7) : 'Unknown';

      if (type == 'income') {
        totalIncome += amount;
        incomeTrend[month] = (incomeTrend[month] ?? 0) + amount;
      } else {
        totalExpense += amount;
        expenseTrend[month] = (expenseTrend[month] ?? 0) + amount;
        categories[category] = (categories[category] ?? 0) + amount;
      }
    }

    final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0.0;

    state = state.copyWith(
      status: AnalyticsStatus.loaded,
      data: AnalyticsModel(
        categoryBreakdown: categories,
        incomeTrend: incomeTrend,
        expenseTrend: expenseTrend,
        totalTransactions: transactions.length,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        savingsRate: savingsRate.clamp(0, 100),
      ),
    );
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsState>(AnalyticsNotifier.new);
