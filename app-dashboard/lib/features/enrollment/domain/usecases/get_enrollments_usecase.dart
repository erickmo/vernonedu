import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/enrollment_entity.dart';
import '../repositories/enrollment_repository.dart';

class GetEnrollmentsUseCase {
  final EnrollmentRepository _repository;
  const GetEnrollmentsUseCase(this._repository);
  Future<Either<Failure, List<EnrollmentEntity>>> call({int offset = 0, int limit = 20}) =>
      _repository.getEnrollments(offset: offset, limit: limit);
}
