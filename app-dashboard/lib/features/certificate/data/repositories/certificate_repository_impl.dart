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
  }) =>
      _guard(() async {
        final models = await _remote.getCertificates(
          studentId: studentId,
          batchId: batchId,
          type: type,
          status: status,
          offset: offset,
          limit: limit,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, void>> issueCertificate({
    required Map<String, dynamic> body,
  }) =>
      _guard(() async {
        await _remote.issueCertificate(body: body);
      });

  @override
  Future<Either<Failure, void>> issueParticipantSingle({
    required String batchId,
    required String studentId,
    required String courseId,
    String? templateId,
    String? verificationBaseUrl,
  }) =>
      _guard(() async {
        await _remote.issueParticipantSingle(
          batchId: batchId,
          studentId: studentId,
          courseId: courseId,
          templateId: templateId,
          verificationBaseUrl: verificationBaseUrl,
        );
      });

  @override
  Future<Either<Failure, int>> issueParticipantBulk({
    required String batchId,
    required List<String> studentIds,
    required String courseId,
    String? templateId,
    String? verificationBaseUrl,
  }) =>
      _guard(() async {
        var ok = 0;
        for (final sid in studentIds) {
          await _remote.issueParticipantSingle(
            batchId: batchId,
            studentId: sid,
            courseId: courseId,
            templateId: templateId,
            verificationBaseUrl: verificationBaseUrl,
          );
          ok++;
        }
        return ok;
      });

  @override
  Future<Either<Failure, void>> issueCompetency({
    required String studentId,
    required String courseId,
    String? batchId,
    String? templateId,
    required bool testPassed,
    String? verificationBaseUrl,
  }) =>
      _guard(() async {
        await _remote.issueCompetency(
          studentId: studentId,
          courseId: courseId,
          batchId: batchId,
          templateId: templateId,
          testPassed: testPassed,
          verificationBaseUrl: verificationBaseUrl,
        );
      });

  @override
  Future<Either<Failure, List<CertificateEntity>>> listByStudent(
    String studentId,
  ) =>
      _guard(() async {
        final models = await _remote.listByStudent(studentId);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<CertificateEntity>>> listByBatch(
    String batchId,
  ) =>
      _guard(() async {
        final models = await _remote.listByBatch(batchId);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, void>> revokeCertificate({
    required String id,
    required String reason,
  }) =>
      _guard(() async {
        await _remote.revokeCertificate(id: id, reason: reason);
      });

  @override
  Future<Either<Failure, List<CertificateTemplateEntity>>>
      getCertificateTemplates() => _guard(() async {
        final models = await _remote.getCertificateTemplates();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, void>> createCertificateTemplate({
    required Map<String, dynamic> body,
  }) =>
      _guard(() async {
        await _remote.createCertificateTemplate(body: body);
      });

  /// Wraps a remote call with offline check + DioException → ServerFailure.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() op) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await op();
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e)));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return e.message ?? 'Server error';
  }
}
