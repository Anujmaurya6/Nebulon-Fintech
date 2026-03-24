import '../data/auth_data_source.dart';
import '../model/user_model.dart';

class AuthRepository {
  final AuthDataSource _dataSource = AuthDataSource();

  Future<({UserModel? user, String? error})> signUp(String email, String password) async {
    final result = await _dataSource.signUp(email, password);
    if (result['error'] != null) return (user: null, error: result['error'] as String);

    return signIn(email, password);
  }

  Future<({UserModel? user, String? error})> signIn(String email, String password) async {
    final result = await _dataSource.signIn(email, password);
    if (result['error'] != null) return (user: null, error: result['error'] as String);

    final data = result['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data);
    
    if (user.token != null) {
      await _dataSource.saveToken(user.token!);
      await _dataSource.saveUserEmail(email);
    }

    return (user: user, error: null);
  }

  Future<UserModel?> getCurrentUser() async {
    final result = await _dataSource.getCurrentUser();
    if (result['error'] != null || result['data'] == null) return null;
    return UserModel.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    await _dataSource.signOut();
    await _dataSource.clearToken();
  }

  Future<bool> isLoggedIn() => _dataSource.hasToken();
}
