import 'package:equatable/equatable.dart';

class StudentEnrollmentHistoryEntity extends Equatable {
  final String id;
  final String batchId;
  final String batchCode;
  final String batchName;
  final String batchType;
  final String courseName;
  final String courseCode;
  final String masterCourseName;
  final DateTime enrolledAt;
  final int totalAttendance;
  final int totalSessions;
  final double? finalScore;
  final String? grade;
  final String status;
  final String paymentStatus;

  const StudentEnrollmentHistoryEntity({
    required this.id,
    required this.batchId,
    required this.batchCode,
    required this.batchName,
    required this.batchType,
    required this.courseName,
    required this.courseCode,
    required this.masterCourseName,
    required this.enrolledAt,
    required this.totalAttendance,
    required this.totalSessions,
    this.finalScore,
    this.grade,
    required this.status,
    required this.paymentStatus,
  });

  double get attendanceRate =>
      totalSessions > 0 ? totalAttendance / totalSessions : 0.0;

  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'active';
  bool get isDropped => status == 'dropped';

  String get statusLabel => switch (status) {
        'completed' => 'Selesai',
        'active' => 'Berjalan',
        'dropped' => 'Dropout',
        _ => status,
      };

  String get paymentLabel => switch (paymentStatus) {
        'paid' => 'Lunas',
        'pending' => 'Pending',
        'failed' => 'Gagal',
        _ => paymentStatus,
      };

  @override
  List<Object?> get props => [id];
}
