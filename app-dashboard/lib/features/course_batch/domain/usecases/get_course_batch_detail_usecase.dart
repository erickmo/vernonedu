import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_batch_detail_entity.dart';
import '../repositories/course_batch_repository.dart';

class GetCourseBatchDetailUseCase {
  final CourseBatchRepository repository;
  const GetCourseBatchDetailUseCase(this.repository);

  Future<Either<Failure, CourseBatchDetailEntity>> call(String batchId) {
    return repository.getCourseBatchDetail(batchId);
  }
}
