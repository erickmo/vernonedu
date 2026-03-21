import '../../domain/entities/batch_entity.dart';

class BatchModel {
  final String id;
  final String code;
  final String masterCourseName;
  final String? courseTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? facilitatorId;
  final String? facilitatorName;
  final int totalEnrolled;
  final int totalSessions;
  final int completedSessions;
  final String? location;

  const BatchModel({
    required this.id,
    required this.code,
    required this.masterCourseName,
    this.courseTypeName,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.facilitatorId,
    this.facilitatorName,
    required this.totalEnrolled,
    required this.totalSessions,
    required this.completedSessions,
    this.location,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) => BatchModel(
        id: json['id'] as String,
        code: json['code'] as String,
        masterCourseName: (json['master_course_name'] ?? json['course_name'] ?? '') as String,
        courseTypeName: json['course_type_name'] as String?,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        status: json['status'] as String? ?? 'active',
        facilitatorId: json['facilitator_id'] as String?,
        facilitatorName: json['facilitator_name'] as String?,
        totalEnrolled: json['total_enrolled'] as int? ?? 0,
        totalSessions: json['total_sessions'] as int? ?? 0,
        completedSessions: json['completed_sessions'] as int? ?? 0,
        location: json['location'] as String?,
      );

  BatchEntity toEntity() => BatchEntity(
        id: id,
        code: code,
        masterCourseName: masterCourseName,
        courseTypeName: courseTypeName,
        startDate: startDate,
        endDate: endDate,
        status: status,
        facilitatorId: facilitatorId,
        facilitatorName: facilitatorName,
        totalEnrolled: totalEnrolled,
        totalSessions: totalSessions,
        completedSessions: completedSessions,
        location: location,
      );
}
