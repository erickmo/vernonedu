import '../../domain/entities/schedule_session_entity.dart';

class ScheduleSessionModel {
  final String id;
  final String batchId;
  final String batchCode;
  final String masterCourseName;
  final int sessionNumber;
  final String? topic;
  final DateTime scheduledAt;
  final String? location;
  final bool hasStarted;

  const ScheduleSessionModel({
    required this.id,
    required this.batchId,
    required this.batchCode,
    required this.masterCourseName,
    required this.sessionNumber,
    this.topic,
    required this.scheduledAt,
    this.location,
    required this.hasStarted,
  });

  factory ScheduleSessionModel.fromJson(Map<String, dynamic> json) {
    return ScheduleSessionModel(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      batchCode: json['batch_code'] as String? ?? '',
      masterCourseName: json['master_course_name'] as String? ?? '',
      sessionNumber: json['session_number'] as int,
      topic: json['topic'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      location: json['location'] as String?,
      hasStarted: json['has_started'] as bool? ?? false,
    );
  }

  ScheduleSessionEntity toEntity() => ScheduleSessionEntity(
        id: id,
        batchId: batchId,
        batchCode: batchCode,
        masterCourseName: masterCourseName,
        sessionNumber: sessionNumber,
        topic: topic,
        scheduledAt: scheduledAt,
        location: location,
        hasStarted: hasStarted,
      );
}
