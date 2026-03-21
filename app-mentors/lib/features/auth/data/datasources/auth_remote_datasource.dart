import 'package:dio/dio.dart';

import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  });
  Future<AuthUserModel> getMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return LoginResponseModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<AuthUserModel> getMe() async {
    final res = await _dio.get('/auth/me');
    final raw = res.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return AuthUserModel.fromJson(data);
  }
}
