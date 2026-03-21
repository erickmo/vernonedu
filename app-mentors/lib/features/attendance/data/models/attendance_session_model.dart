import '../../domain/entities/attendance_session_entity.dart';

class AttendanceSessionModel {
  final String id;
  final String batchId;
  final String batchCode;
  final String masterCourseName;
  final int sessionNumber;
  final String? topic;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool isOpen;
  final int totalPresent;
  final int totalAbsent;
  final int totalEnrolled;

  const AttendanceSessionModel({
    required this.id,
    required this.batchId,
    required this.batchCode,
    required this.masterCourseName,
    required this.sessionNumber,
    this.topic,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.isOpen,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalEnrolled,
  });

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) =>
      AttendanceSessionModel(
        id: json['id'] as String,
        batchId: json['batch_id'] as String,
        batchCode: json['batch_code'] as String? ?? '',
        masterCourseName: json['master_course_name'] as String? ?? '',
        sessionNumber: json['session_number'] as int? ?? 0,
        topic: json['topic'] as String?,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        endedAt: json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
        isOpen: json['is_open'] as bool? ?? false,
        totalPresent: json['total_present'] as int? ?? 0,
        totalAbsent: json['total_absent'] as int? ?? 0,
        totalEnrolled: json['total_enrolled'] as int? ?? 0,
      );

  AttendanceSessionEntity toEntity() => AttendanceSessionEntity(
        id: id,
        batchId: batchId,
        batchCode: batchCode,
        masterCourseName: masterCourseName,
        sessionNumber: sessionNumber,
        topic: topic,
        scheduledAt: scheduledAt,
        startedAt: startedAt,
        endedAt: endedAt,
        isOpen: isOpen,
        totalPresent: totalPresent,
        totalAbsent: totalAbsent,
        totalEnrolled: totalEnrolled,
      );
}
