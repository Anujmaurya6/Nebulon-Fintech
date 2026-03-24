import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class DashboardDataSource {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> fetchDashboardData() async {
    return _client.get(
      ApiConstants.records(ApiConstants.transactionsTable),
      queryParams: {'order': 'created_at.desc'},
    );
  }
}
