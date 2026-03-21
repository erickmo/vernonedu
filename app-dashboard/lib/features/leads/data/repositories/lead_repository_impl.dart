import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/entities/crm_log_entity.dart';
import '../../domain/repositories/lead_repository.dart';
import '../datasources/lead_remote_datasource.dart';

class LeadRepositoryImpl implements LeadRepository {
  final LeadRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const LeadRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  String _extractError(DioException e, String fallback) {
    final msg = e.response?.data is Map
        ? (e.response!.data as Map)['error']?.toString() ?? e.message
        : e.message;
    return msg ?? fallback;
  }

  @override
  Future<Either<Failure, List<LeadEntity>>> getLeads({
    int offset = 0,
    int limit = 50,
    String? status,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getLeads(
        offset: offset,
        limit: limit,
        status: status,
      );
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat leads')));
    }
  }

  @override
  Future<Either<Failure, LeadEntity>> getLeadById(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getLeadById(id);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat lead')));
    }
  }

  @override
  Future<Either<Failure, LeadEntity>> createLead(Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.createLead(data);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal membuat lead')));
    }
  }

  @override
  Future<Either<Failure, LeadEntity>> updateLead(
      String id, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.updateLead(id, data);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal mengubah lead')));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLead(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deleteLead(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menghapus lead')));
    }
  }

  @override
  Future<Either<Failure, List<CrmLogEntity>>> getCrmLogs(String leadId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getCrmLogs(leadId);
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat log CRM')));
    }
  }

  @override
  Future<Either<Failure, void>> addCrmLog(
      String leadId, Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.addCrmLog(leadId, data);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menambah log CRM')));
    }
  }

  @override
  Future<Either<Failure, void>> convertToStudent(String leadId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.convertToStudent(leadId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal mengkonversi lead')));
    }
  }
}
