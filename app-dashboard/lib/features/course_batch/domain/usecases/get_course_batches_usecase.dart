import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_batch_entity.dart';
import '../repositories/course_batch_repository.dart';

class GetCourseBatchesUseCase {
  final CourseBatchRepository _repository;
  const GetCourseBatchesUseCase(this._repository);
  Future<Either<Failure, List<CourseBatchEntity>>> call({int offset = 0, int limit = 20}) =>
      _repository.getCourseBatches(offset: offset, limit: limit);
}
