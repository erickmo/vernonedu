import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/student_note_entity.dart';
import '../repositories/student_detail_repository.dart';

class AddStudentNoteUseCase {
  final StudentDetailRepository _repository;

  const AddStudentNoteUseCase(this._repository);

  Future<Either<Failure, StudentNoteEntity>> call(
      String studentId, String content) {
    return _repository.addStudentNote(studentId, content);
  }
}
