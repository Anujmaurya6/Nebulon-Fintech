import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AiDataSource {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getChatCompletion(
    List<Map<String, String>> messages,
  ) async {
    return _client.post(
      ApiConstants.aiChat,
      data: {'model': 'openai/gpt-4o-mini', 'messages': messages},
    );
  }

  Future<Map<String, dynamic>> fetchHistory() async {
    return _client.get(
      '${ApiConstants.records(ApiConstants.aiHistoryTable)}?order=timestamp.asc',
    );
  }

  Future<Map<String, dynamic>> saveMessage(String content, bool isUser) async {
    return _client.post(
      ApiConstants.records(ApiConstants.aiHistoryTable),
      data: {'content': content, 'is_user': isUser},
    );
  }
}
