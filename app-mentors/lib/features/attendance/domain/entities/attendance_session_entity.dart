import 'package:equatable/equatable.dart';

class AttendanceSessionEntity extends Equatable {
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

  const AttendanceSessionEntity({
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

  String get attendanceSummary => '$totalPresent/$totalEnrolled hadir';

  bool get hasStarted => startedAt != null;

  @override
  List<Object?> get props => [id];
}
