class UserModel {
  final String? id;
  final String email;
  final String? fullName;
  final String? role;
  final String? avatarUrl;
  final String? token;

  const UserModel({
    this.id,
    required this.email,
    this.fullName,
    this.role,
    this.avatarUrl,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['user_metadata']?['full_name'],
      role: json['role'] ?? 'Business Owner',
      avatarUrl: json['avatar_url'],
      token: json['access_token'] ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'avatar_url': avatarUrl,
      };
}
