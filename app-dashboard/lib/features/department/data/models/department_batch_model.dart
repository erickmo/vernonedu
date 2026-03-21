import '../../domain/entities/department_batch_entity.dart';

class DepartmentBatchModel {
  final String batchId;
  final String batchName;
  final String startDate;
  final String endDate;
  final int maxParticipants;
  final bool isActive;
  final String courseName;
  final String facilitatorId;
  final String facilitatorName;
  final int enrollmentCount;

  const DepartmentBatchModel({
    required this.batchId,
    required this.batchName,
    required this.startDate,
    required this.endDate,
    required this.maxParticipants,
    required this.isActive,
    required this.courseName,
    required this.facilitatorId,
    required this.facilitatorName,
    required this.enrollmentCount,
  });

  factory DepartmentBatchModel.fromJson(Map<String, dynamic> json) {
    return DepartmentBatchModel(
      batchId: json['batch_id'] as String? ?? '',
      batchName: json['batch_name'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      maxParticipants: json['max_participants'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? false,
      courseName: json['course_name'] as String? ?? '',
      facilitatorId: json['facilitator_id'] as String? ?? '',
      facilitatorName: json['facilitator_name'] as String? ?? '',
      enrollmentCount: json['enrollment_count'] as int? ?? 0,
    );
  }

  DepartmentBatchEntity toEntity() => DepartmentBatchEntity(
        batchId: batchId,
        batchName: batchName,
        startDate: startDate,
        endDate: endDate,
        maxParticipants: maxParticipants,
        isActive: isActive,
        courseName: courseName,
        facilitatorId: facilitatorId,
        facilitatorName: facilitatorName,
        enrollmentCount: enrollmentCount,
      );
}
