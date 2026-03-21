import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_batch_detail_entity.dart';
import '../entities/course_batch_entity.dart';

abstract class CourseBatchRepository {
  Future<Either<Failure, List<CourseBatchEntity>>> getCourseBatches({int offset = 0, int limit = 20});
  Future<Either<Failure, CourseBatchDetailEntity>> getCourseBatchDetail(String batchId);
  Future<Either<Failure, void>> createCourseBatch(Map<String, dynamic> data);
}
