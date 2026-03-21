import '../../domain/entities/department_summary_entity.dart';

class DepartmentSummaryModel {
  final String id;
  final String name;
  final String description;
  final int courseCount;
  final int batchUpcoming;
  final int batchOngoing;
  final int batchCompleted;
  final int paidEnrollmentCount;

  const DepartmentSummaryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.courseCount,
    required this.batchUpcoming,
    required this.batchOngoing,
    required this.batchCompleted,
    required this.paidEnrollmentCount,
  });

  factory DepartmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return DepartmentSummaryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      courseCount: json['course_count'] as int? ?? 0,
      batchUpcoming: json['batch_upcoming'] as int? ?? 0,
      batchOngoing: json['batch_ongoing'] as int? ?? 0,
      batchCompleted: json['batch_completed'] as int? ?? 0,
      paidEnrollmentCount: json['paid_enrollment_count'] as int? ?? 0,
    );
  }

  DepartmentSummaryEntity toEntity() => DepartmentSummaryEntity(
        id: id,
        name: name,
        description: description,
        courseCount: courseCount,
        batchUpcoming: batchUpcoming,
        batchOngoing: batchOngoing,
        batchCompleted: batchCompleted,
        paidEnrollmentCount: paidEnrollmentCount,
      );
}
