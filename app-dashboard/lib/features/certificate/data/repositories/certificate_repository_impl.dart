import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/entities/certificate_template_entity.dart';
import '../../domain/repositories/certificate_repository.dart';
import '../datasources/certificate_remote_datasource.dart';

class CertificateRepositoryImpl implements CertificateRepository {
  final CertificateRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  const CertificateRepositoryImpl({
    required CertificateRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remote = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<CertificateEntity>>> getCertificates({
    String? studentId,
    String? batchId,
    String? type,
    String? status,
    int offset = 0,
    int limit = 50,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final models = await _remote.getCertificates(
        studentId: studentId,
        batchId: batchId,
        type: type,
        status: status,
        offset: offset,
        limit: limit,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.response?.data?['error'] as String? ?? e.message ?? 'Server error',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> issueCertificate({
    required Map<String, dynamic> body,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.issueCertificate(body: body);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.response?.data?['error'] as String? ?? e.message ?? 'Server error',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> revokeCertificate({
    required String id,
    required String reason,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.revokeCertificate(id: id, reason: reason);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.response?.data?['error'] as String? ?? e.message ?? 'Server error',
      ));
    }
  }

  @override
  Future<Either<Failure, List<CertificateTemplateEntity>>>
      getCertificateTemplates() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final models = await _remote.getCertificateTemplates();
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.response?.data?['error'] as String? ?? e.message ?? 'Server error',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> createCertificateTemplate({
    required Map<String, dynamic> body,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.createCertificateTemplate(body: body);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(
        e.response?.data?['error'] as String? ?? e.message ?? 'Server error',
      ));
    }
  }
}
