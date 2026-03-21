import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SharedPreferences prefs;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.prefs,
  });

  @override
  bool get isLoggedIn =>
      prefs.getString(AppConstants.accessTokenKey) != null;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.login(email: email, password: password);
      await prefs.setString(AppConstants.accessTokenKey, result.accessToken);
      await prefs.setString(AppConstants.refreshTokenKey, result.refreshToken);
      await prefs.setString(AppConstants.userRolesKey, result.user.roles.join(','));
      return Right(result.user.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.userRolesKey);
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getMe();
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) return const NetworkFailure();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) return const TimeoutFailure();
    final status = e.response?.statusCode;
    if (status == 401) return const UnauthorizedFailure();
    if (status == 403) return const ForbiddenFailure();
    final msg = e.response?.data is Map
        ? (e.response!.data as Map)['error']?.toString() ?? 'Terjadi kesalahan'
        : 'Terjadi kesalahan pada server';
    return ServerFailure(msg, statusCode: status);
  }
}
