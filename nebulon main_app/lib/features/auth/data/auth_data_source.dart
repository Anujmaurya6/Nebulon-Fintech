import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AuthDataSource {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> signUp(String email, String password) async {
    return _client.post(
      ApiConstants.signUp,
      data: {'email': email, 'password': password},
    );
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    return _client.post(
      ApiConstants.signIn,
      data: {'email': email, 'password': password},
    );
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return _client.get(ApiConstants.currentUser);
  }

  Future<Map<String, dynamic>> signOut() async {
    return _client.post(ApiConstants.signOut);
  }

  Future<void> saveToken(String token) => _client.saveToken(token);
  Future<void> saveUserEmail(String email) => _client.saveUserEmail(email);
  Future<void> clearToken() => _client.clearToken();
  Future<bool> hasToken() => _client.hasToken();
}
