import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/batch_detail_entity.dart';
import '../../domain/entities/batch_entity.dart';
import '../../domain/repositories/batch_repository.dart';
import '../datasources/batch_remote_datasource.dart';

class BatchRepositoryImpl implements BatchRepository {
  final BatchRemoteDataSource _remote;

  const BatchRepositoryImpl({required BatchRemoteDataSource remote})
      : _remote = remote;

  @override
  Future<Either<Failure, List<BatchEntity>>> getMyBatches() async {
    try {
      final models = await _remote.getMyBatches();
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Gagal memuat kelas';
      return Left(ServerFailure(msg, statusCode: e.response?.statusCode));
    } catch (_) {
      return const Left(ServerFailure('Gagal memuat kelas'));
    }
  }

  @override
  Future<Either<Failure, BatchDetailEntity>> getBatchDetail(
      String batchId) async {
    try {
      final model = await _remote.getBatchDetail(batchId);
      return Right(model.toEntity());
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Gagal memuat detail kelas';
      return Left(ServerFailure(msg, statusCode: e.response?.statusCode));
    } catch (_) {
      return const Left(ServerFailure('Gagal memuat detail kelas'));
    }
  }

  @override
  Future<Either<Failure, void>> assignFacilitator(
      String batchId, String facilitatorId) async {
    try {
      await _remote.assignFacilitator(batchId, facilitatorId);
      return const Right(null);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Gagal menugaskan fasilitator';
      return Left(ServerFailure(msg, statusCode: e.response?.statusCode));
    } catch (_) {
      return const Left(ServerFailure('Gagal menugaskan fasilitator'));
    }
  }
}
