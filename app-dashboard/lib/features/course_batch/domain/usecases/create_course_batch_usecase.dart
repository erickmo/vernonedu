import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_batch_repository.dart';

class CreateCourseBatchUseCase {
  final CourseBatchRepository _repository;
  const CreateCourseBatchUseCase(this._repository);
  Future<Either<Failure, void>> call(Map<String, dynamic> data) =>
      _repository.createCourseBatch(data);
}
