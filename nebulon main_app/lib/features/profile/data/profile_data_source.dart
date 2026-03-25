import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class ProfileDataSource {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> fetchCurrentUser() async {
    return _client.get(ApiConstants.currentUser);
  }

  Future<String?> getUserEmail() async {
    return _client.getUserEmail();
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return _client.patch(
      ApiConstants.records(ApiConstants.userProfilesTable),
      data: data,
    );
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    return _client.uploadFile(
      '/storage/v1/object/avatars/profile_pic.jpg',
      filePath,
    );
  }

  Future<Map<String, dynamic>> deleteAvatar() async {
    // Standard Supabase/Insforge storage delete
    return _client.delete('/storage/v1/object/avatars/profile_pic.jpg');
  }
}
