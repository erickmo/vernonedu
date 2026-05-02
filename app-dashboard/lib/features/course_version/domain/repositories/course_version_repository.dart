import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/course_version_entity.dart';
import '../entities/internship_config_entity.dart';
import '../entities/character_test_config_entity.dart';

// Kontrak repository domain untuk CourseVersion
abstract class CourseVersionRepository {
  Future<Either<Failure, List<CourseVersionEntity>>> getVersionsByType(String typeId);
  Future<Either<Failure, CourseVersionEntity>> getVersionById(String versionId);
  Future<Either<Failure, void>> createVersion(String typeId, Map<String, dynamic> data);
  Future<Either<Failure, void>> promoteVersion(String versionId, String targetStatus);
  Future<Either<Failure, InternshipConfigEntity?>> getInternshipConfig(String versionId);
  Future<Either<Failure, void>> upsertInternshipConfig(String versionId, Map<String, dynamic> data);
  Future<Either<Failure, CharacterTestConfigEntity?>> getCharacterTestConfig(String versionId);
  Future<Either<Failure, void>> upsertCharacterTestConfig(String versionId, Map<String, dynamic> data);

  // Approval workflow — dept_leader only.
  // approveCourseVersion has no body; rejectCourseVersion requires a reason.
  Future<Either<Failure, void>> approveCourseVersion(String versionId);
  Future<Either<Failure, void>> rejectCourseVersion(String versionId, String reason);

  // List versions waiting for approval (approval_status = 'submitted').
  Future<Either<Failure, List<CourseVersionEntity>>> getPendingVersions();
}
