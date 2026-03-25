import '../data/transaction_data_source.dart';
import '../../../core/utils/cache_manager.dart';
import '../model/transaction_model.dart';

class TransactionRepository {
  final TransactionDataSource _dataSource = TransactionDataSource();

  Future<({List<TransactionModel> transactions, String? error})>
  getTransactions() async {
    final result = await _dataSource.getTransactions();

    if (result['error'] != null) {
      // Try cache
      final cached = CacheManager.getTransactionsCache();
      if (cached != null && cached is List) {
        return (
          transactions: cached
              .map<TransactionModel>(
                (e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(),
          error: null,
        );
      }
      return (
        transactions: <TransactionModel>[],
        error: result['error'] as String,
      );
    }

    final data = result['data'];
    final list = (data is List ? data : [])
        .map<TransactionModel>(
          (e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();

    // Cache for offline
    await CacheManager.saveTransactionsCache(data);

    return (transactions: list, error: null);
  }

  Future<({TransactionModel? transaction, String? error})> addTransaction(
    TransactionModel tx,
  ) async {
    final result = await _dataSource.addTransaction(tx.toJson());

    if (result['error'] != null)
      return (transaction: null, error: result['error'] as String);

    final data = result['data'];
    if (data is List && data.isNotEmpty) {
      return (
        transaction: TransactionModel.fromJson(
          Map<String, dynamic>.from(data.first),
        ),
        error: null,
      );
    }
    return (transaction: null, error: null);
  }

  Future<String?> deleteTransaction(String id) async {
    final result = await _dataSource.deleteTransaction(id);
    return result['error'] as String?;
  }
}
