import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/department_entity.dart';
import '../entities/department_summary_entity.dart';
import '../entities/department_batch_entity.dart';
import '../entities/department_course_entity.dart';
import '../entities/department_student_entity.dart';
import '../entities/department_talentpool_entity.dart';

abstract class DepartmentRepository {
  Future<Either<Failure, List<DepartmentEntity>>> getDepartments({int offset = 0, int limit = 100});
  Future<Either<Failure, void>> createDepartment(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateDepartment(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteDepartment(String id);

  // Dashboard endpoints
  Future<Either<Failure, List<DepartmentSummaryEntity>>> getDepartmentSummaries();
  Future<Either<Failure, List<DepartmentBatchEntity>>> getDepartmentBatches(String departmentId);
  Future<Either<Failure, List<DepartmentCourseEntity>>> getDepartmentCourses(String departmentId);
  Future<Either<Failure, List<DepartmentStudentEntity>>> getDepartmentStudents(String departmentId, {String status = ''});
  Future<Either<Failure, List<DepartmentTalentPoolEntity>>> getDepartmentTalentPool(String departmentId);
  Future<Either<Failure, void>> assignBatchFacilitator(String batchId, String facilitatorId);
}
