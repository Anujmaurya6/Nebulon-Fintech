import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_data_source.dart';
import '../../../core/security/lock_service.dart';

class ProfileModel {
  final String? id;
  final String? fullName;
  final String? email;
  final String role;
  final String? avatarUrl;
  final int? age;
  final String? phone;
  final String? gmail;
  final String? address;

  const ProfileModel({
    this.id,
    this.fullName,
    this.email,
    this.role = 'Business Owner',
    this.avatarUrl,
    this.age,
    this.phone,
    this.gmail,
    this.address,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString(),
      fullName: json['full_name'] ?? json['fullName'],
      email: json['email'],
      role: json['role'] ?? 'Business Owner',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      age: int.tryParse(json['age']?.toString() ?? ''),
      phone: json['phone'],
      gmail: json['gmail'],
      address: json['address'],
    );
  }
}

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState {
  final ProfileStatus status;
  final ProfileModel? profile;
  final bool isBiometricEnabled;
  final bool isBiometricSupported;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.isBiometricEnabled = false,
    this.isBiometricSupported = true,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileModel? profile,
    bool? isBiometricEnabled,
    bool? isBiometricSupported,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricSupported: isBiometricSupported ?? this.isBiometricSupported,
      errorMessage: errorMessage,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  final ProfileDataSource _dataSource = ProfileDataSource();

  @override
  ProfileState build() => const ProfileState();

  Future<void> loadProfile() async {
    state = state.copyWith(status: ProfileStatus.loading);

    // Try to get user from auth endpoint
    final authResult = await _dataSource.fetchCurrentUser();
    if (authResult['data'] != null) {
      final data = authResult['data'] as Map<String, dynamic>;
      final email = data['email'] ?? (await _dataSource.getUserEmail()) ?? '';

      state = state.copyWith(
        status: ProfileStatus.loaded,
        profile: ProfileModel(
          id: data['id']?.toString(),
          fullName:
              data['full_name'] ??
              data['user_metadata']?['full_name'] ??
              'User',
          email: email,
          role: data['role'] ?? 'Business Owner',
        ),
      );
      return;
    }

    // Fallback: use cached email from data source
    final email = await _dataSource.getUserEmail() ?? 'user@email.com';
    state = state.copyWith(
      status: ProfileStatus.loaded,
      profile: ProfileModel(id: 'current_user', email: email, fullName: 'User'),
    );

    // Load biometric setting from secure storage & check hardware
    final lockService = ref.read(lockServiceProvider);
    final isSupported = await lockService.isBiometricAvailable();
    final isEnabled = await lockService.isBiometricEnabled();
    state = state.copyWith(
      isBiometricEnabled: isEnabled,
      isBiometricSupported: isSupported,
    );
  }

  Future<void> toggleBiometrics(bool value) async {
    final lockService = ref.read(lockServiceProvider);
    await lockService.setBiometricEnabled(value);
    state = state.copyWith(isBiometricEnabled: value);
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final currentProfile = state.profile;
    if (currentProfile?.id == null) return false;

    // Optimistic Update
    final updatedProfile = ProfileModel(
      id: currentProfile!.id,
      fullName: data['full_name'] ?? currentProfile.fullName,
      email: currentProfile.email,
      role: data['role'] ?? currentProfile.role,
      avatarUrl: data['avatar_url'] ?? currentProfile.avatarUrl,
      age: data['age'] != null
          ? int.tryParse(data['age'].toString())
          : currentProfile.age,
      phone: data['phone'] ?? currentProfile.phone,
      gmail: data['gmail'] ?? currentProfile.gmail,
      address: data['address'] ?? currentProfile.address,
    );
    state = state.copyWith(profile: updatedProfile);

    final result = await _dataSource.updateProfile(data);
    if (result['error'] != null) {
      // Rollback
      state = state.copyWith(
        profile: currentProfile,
        errorMessage: result['error'] as String?,
      );
      return false;
    }
    return true;
  }

  Future<bool> updateAvatar(String filePath) async {
    state = state.copyWith(status: ProfileStatus.loading);
    final result = await _dataSource.uploadAvatar(filePath);

    if (result['error'] != null) {
      state = state.copyWith(
        status: ProfileStatus.loaded,
        errorMessage: result['error'] as String?,
      );
      return false;
    }

    final newAvatarUrl =
        result['data']?['url'] ??
        '/storage/v1/object/public/avatars/profile_pic.jpg';
    return await updateProfile({'avatar_url': newAvatarUrl});
  }

  Future<bool> deleteAvatar() async {
    state = state.copyWith(status: ProfileStatus.loading);
    final result = await _dataSource.deleteAvatar();

    if (result['error'] != null) {
      state = state.copyWith(
        status: ProfileStatus.loaded,
        errorMessage: result['error'] as String?,
      );
      return false;
    }

    return await updateProfile({'avatar_url': null});
  }

  Future<void> syncData() async {
    state = state.copyWith(status: ProfileStatus.loading);
    // Simulate sync
    await Future.delayed(const Duration(seconds: 1));
    await loadProfile();
    state = state.copyWith(status: ProfileStatus.loaded);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
