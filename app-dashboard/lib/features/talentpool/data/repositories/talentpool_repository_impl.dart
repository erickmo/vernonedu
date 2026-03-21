import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/talentpool_entity.dart';
import '../../domain/entities/job_opening_entity.dart';
import '../../domain/entities/partner_company_entity.dart';
import '../../domain/repositories/talentpool_repository.dart';
import '../datasources/talentpool_remote_datasource.dart';

// Implementasi repository TalentPool — menangani DioException sesuai pola existing
class TalentPoolRepositoryImpl implements TalentPoolRepository {
  final TalentPoolRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const TalentPoolRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TalentPoolEntity>>> getTalentPool({
    int offset = 0,
    int limit = 20,
    String status = '',
    String masterCourseId = '',
    String participantId = '',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getTalentPool(
        offset: offset,
        limit: limit,
        status: status,
        masterCourseId: masterCourseId,
        participantId: participantId,
      );
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat talent pool'));
    }
  }

  @override
  Future<Either<Failure, TalentPoolEntity>> getTalentPoolById(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getTalentPoolById(id);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat detail talent pool'));
    }
  }

  @override
  Future<Either<Failure, void>> updateStatus(
      String id, String status, Map<String, dynamic>? placement) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateStatus(id, status, placement);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal mengupdate status talent pool'));
    }
  }

  @override
  Future<Either<Failure, List<JobOpeningEntity>>> getJobOpenings() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getJobOpenings();
      return Right(result.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat lowongan pekerjaan'));
    }
  }

  @override
  Future<Either<Failure, List<PartnerCompanyEntity>>> getPartnerCompanies() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getPartnerCompanies();
      return Right(result.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Gagal memuat perusahaan rekanan'));
    }
  }
}
