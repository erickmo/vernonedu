import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/course_repository.dart';

// Use case untuk mengarsipkan MasterCourse (ubah status ke 'archived')
class ArchiveCourseUseCase {
  final CourseRepository repository;
  ArchiveCourseUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.archiveCourse(id);
}
