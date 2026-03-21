import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/facilitator_entity.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../datasources/facilitator_remote_datasource.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  final FacilitatorRemoteDataSource _remote;

  const AssignmentRepositoryImpl({required FacilitatorRemoteDataSource remote})
      : _remote = remote;

  @override
  Future<Either<Failure, List<FacilitatorEntity>>> getFacilitators() async {
    try {
      final models = await _remote.getFacilitators();
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Gagal memuat fasilitator';
      return Left(ServerFailure(msg, statusCode: e.response?.statusCode));
    } catch (_) {
      return const Left(ServerFailure('Gagal memuat fasilitator'));
    }
  }
}
