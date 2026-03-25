import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AnalyticsDataSource {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> fetchTransactionsForAnalytics() async {
    return _client.get(ApiConstants.records(ApiConstants.transactionsTable));
  }
}
