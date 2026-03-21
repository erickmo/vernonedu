import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/student_entity.dart';
import '../repositories/student_repository.dart';

class GetStudentsUseCase {
  final StudentRepository _repository;
  const GetStudentsUseCase(this._repository);
  Future<Either<Failure, List<StudentEntity>>> call({int offset = 0, int limit = 20}) =>
      _repository.getStudents(offset: offset, limit: limit);
}
