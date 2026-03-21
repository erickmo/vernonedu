import 'package:equatable/equatable.dart';

class ScheduleSessionEntity extends Equatable {
  final String id;
  final String batchId;
  final String batchCode;
  final String masterCourseName;
  final int sessionNumber;
  final String? topic;
  final DateTime scheduledAt;
  final String? location;
  final bool hasStarted;

  const ScheduleSessionEntity({
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

  String get displayTitle => topic ?? 'Sesi $sessionNumber';

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  bool get isPast => scheduledAt.isBefore(DateTime.now());

  @override
  List<Object?> get props => [id];
}
