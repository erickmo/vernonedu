import 'package:equatable/equatable.dart';

class BatchEntity extends Equatable {
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

  const BatchEntity({
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

  double get progressPercent =>
      totalSessions > 0 ? completedSessions / totalSessions : 0.0;

  String get statusLabel => switch (status) {
        'active' => 'Aktif',
        'completed' => 'Selesai',
        'scheduled' => 'Terjadwal',
        'cancelled' => 'Dibatalkan',
        _ => status,
      };

  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [id];
}
