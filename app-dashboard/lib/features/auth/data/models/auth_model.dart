import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final List<String> roles;
  final String? departmentId;
  final String? departmentName;
  final String? avatarUrl;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    this.departmentId,
    this.departmentName,
    this.avatarUrl,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        // API now returns roles: ["director", "education_leader"].
        // Backward compat: also handles legacy role: "director" (single string).
        roles: json['roles'] != null
            ? (json['roles'] as List).map((e) => e as String).toList()
            : json['role'] != null
                ? [json['role'] as String]
                : ['student'],
        departmentId: json['department_id'] as String?,
        departmentName: json['department_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  UserEntity toEntity() => UserEntity(
        id: id,
        name: name,
        email: email,
        roles: roles.map(UserRole.fromString).toList(),
        departmentId: departmentId,
        departmentName: departmentName,
        avatarUrl: avatarUrl,
        isActive: isActive,
      );
}

class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}
