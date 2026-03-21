import 'package:equatable/equatable.dart';

class DepartmentBatchEntity extends Equatable {
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

  const DepartmentBatchEntity({
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

  String get batchStatus {
    final now = DateTime.now();
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      if (now.isBefore(start)) return 'upcoming';
      if (now.isAfter(end)) return 'completed';
      return 'ongoing';
    } catch (_) {
      return 'unknown';
    }
  }

  double get fillRate => maxParticipants > 0 ? enrollmentCount / maxParticipants : 0;

  @override
  List<Object?> get props => [batchId];
}
