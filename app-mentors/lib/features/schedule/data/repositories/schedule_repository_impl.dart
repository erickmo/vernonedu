import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/schedule_session_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource _remote;

  const ScheduleRepositoryImpl({required ScheduleRemoteDataSource remote})
      : _remote = remote;

  @override
  Future<Either<Failure, List<ScheduleSessionEntity>>> getMySchedule({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final fromStr =
          '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
      final toStr =
          '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
      final models = await _remote.getMySchedule(from: fromStr, to: toStr);
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(
          e.response?.data?['message'] as String? ?? e.message ?? 'Error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
