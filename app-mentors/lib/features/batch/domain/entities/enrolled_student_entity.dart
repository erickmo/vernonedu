import 'package:equatable/equatable.dart';

class EnrolledStudentEntity extends Equatable {
  final String enrollmentId;
  final String studentId;
  final String studentName;
  final String studentCode;
  final String? email;
  final String status;
  final double? attendanceRate;
  final double? finalScore;

  const EnrolledStudentEntity({
    required this.enrollmentId,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    this.email,
    required this.status,
    this.attendanceRate,
    this.finalScore,
  });

  String get initials {
    final parts = studentName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [enrollmentId];
}
