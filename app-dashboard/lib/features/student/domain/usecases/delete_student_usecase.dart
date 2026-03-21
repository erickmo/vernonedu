import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/student_repository.dart';

class DeleteStudentUseCase {
  final StudentRepository _repository;
  const DeleteStudentUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteStudent(id);
}
