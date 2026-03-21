import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/student_note_entity.dart';
import '../repositories/student_detail_repository.dart';

class GetStudentNotesUseCase {
  final StudentDetailRepository _repository;

  const GetStudentNotesUseCase(this._repository);

  Future<Either<Failure, List<StudentNoteEntity>>> call(String studentId) {
    return _repository.getStudentNotes(studentId);
  }
}
