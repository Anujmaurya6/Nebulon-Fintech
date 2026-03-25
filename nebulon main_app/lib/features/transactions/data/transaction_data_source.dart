import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class TransactionDataSource {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getTransactions() async {
    return _client.get(
      ApiConstants.records(ApiConstants.transactionsTable),
      queryParams: {'order': 'created_at.desc', 'limit': '50'},
    );
  }

  Future<Map<String, dynamic>> addTransaction(Map<String, dynamic> data) async {
    return _client.post(
      ApiConstants.records(ApiConstants.transactionsTable),
      data: data,
    );
  }

  Future<Map<String, dynamic>> deleteTransaction(String id) async {
    return _client.delete(
      ApiConstants.records(ApiConstants.transactionsTable),
      queryParams: {'id': 'eq.$id'},
    );
  }
}
