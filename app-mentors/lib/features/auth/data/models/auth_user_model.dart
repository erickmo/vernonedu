import '../../domain/entities/auth_user_entity.dart';

class AuthUserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? departmentId;
  final String? departmentName;
  final String? photoUrl;

  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
    this.departmentName,
    this.photoUrl,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        departmentId: json['department_id'] as String?,
        departmentName: json['department_name'] as String?,
        photoUrl: json['photo_url'] as String?,
      );

  AuthUserEntity toEntity() => AuthUserEntity(
        id: id,
        name: name,
        email: email,
        role: role,
        departmentId: departmentId,
        departmentName: departmentName,
        photoUrl: photoUrl,
      );
}

class LoginResponseModel {
  final String token;
  final AuthUserModel user;

  const LoginResponseModel({required this.token, required this.user});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return LoginResponseModel(
      token: data['token'] as String,
      user: AuthUserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
