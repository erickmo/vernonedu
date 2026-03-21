import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SharedPreferences _prefs;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SharedPreferences prefs,
  }) : _remote = remote,
       _prefs = prefs;

  @override
  Future<Either<Failure, AuthUserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remote.login(email: email, password: password);
      await _prefs.setString(AppConstants.accessTokenKey, response.token);
      return Right(response.user.toEntity());
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Login gagal';
      return Left(ServerFailure(msg, statusCode: e.response?.statusCode));
    } catch (_) {
      return const Left(ServerFailure('Login gagal'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    await _prefs.remove(AppConstants.accessTokenKey);
    return const Right(null);
  }

  @override
  Future<Either<Failure, AuthUserEntity>> getCurrentUser() async {
    try {
      final model = await _remote.getMe();
      return Right(model.toEntity());
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Gagal memuat profil';
      return Left(ServerFailure(msg, statusCode: e.response?.statusCode));
    } catch (_) {
      return const Left(ServerFailure('Gagal memuat profil'));
    }
  }
}
