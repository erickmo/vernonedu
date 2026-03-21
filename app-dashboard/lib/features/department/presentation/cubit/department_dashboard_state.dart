import 'package:equatable/equatable.dart';
import '../../domain/entities/department_summary_entity.dart';
import '../../domain/entities/department_batch_entity.dart';
import '../../domain/entities/department_course_entity.dart';
import '../../domain/entities/department_student_entity.dart';
import '../../domain/entities/department_talentpool_entity.dart';

abstract class DepartmentDashboardState extends Equatable {
  const DepartmentDashboardState();
  @override
  List<Object?> get props => [];
}

class DepartmentDashboardInitial extends DepartmentDashboardState {}

class DepartmentDashboardLoading extends DepartmentDashboardState {}

class DepartmentDashboardLoaded extends DepartmentDashboardState {
  final List<DepartmentBatchEntity> batches;
  final List<DepartmentCourseEntity> courses;
  final List<DepartmentStudentEntity> students;
  final List<DepartmentTalentPoolEntity> talentPool;
  final String studentFilter;
  final bool isAssigningFacilitator;

  const DepartmentDashboardLoaded({
    required this.batches,
    required this.courses,
    required this.students,
    required this.talentPool,
    this.studentFilter = '',
    this.isAssigningFacilitator = false,
  });

  DepartmentDashboardLoaded copyWith({
    List<DepartmentBatchEntity>? batches,
    List<DepartmentCourseEntity>? courses,
    List<DepartmentStudentEntity>? students,
    List<DepartmentTalentPoolEntity>? talentPool,
    String? studentFilter,
    bool? isAssigningFacilitator,
  }) =>
      DepartmentDashboardLoaded(
        batches: batches ?? this.batches,
        courses: courses ?? this.courses,
        students: students ?? this.students,
        talentPool: talentPool ?? this.talentPool,
        studentFilter: studentFilter ?? this.studentFilter,
        isAssigningFacilitator: isAssigningFacilitator ?? this.isAssigningFacilitator,
      );

  @override
  List<Object?> get props => [batches, courses, students, talentPool, studentFilter, isAssigningFacilitator];
}

class DepartmentDashboardError extends DepartmentDashboardState {
  final String message;
  const DepartmentDashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Department list page states ────────────────────────────────────────────

abstract class DepartmentSummaryState extends Equatable {
  const DepartmentSummaryState();
  @override
  List<Object?> get props => [];
}

class DepartmentSummaryInitial extends DepartmentSummaryState {}
class DepartmentSummaryLoading extends DepartmentSummaryState {}

class DepartmentSummaryLoaded extends DepartmentSummaryState {
  final List<DepartmentSummaryEntity> summaries;
  const DepartmentSummaryLoaded(this.summaries);
  @override
  List<Object?> get props => [summaries];
}

class DepartmentSummaryError extends DepartmentSummaryState {
  final String message;
  const DepartmentSummaryError(this.message);
  @override
  List<Object?> get props => [message];
}
