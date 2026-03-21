import 'package:equatable/equatable.dart';

class AttendanceRecordEntity extends Equatable {
  final String studentId;
  final String studentName;
  final String studentCode;
  final String status; // present | absent | late | excused
  final String? note;

  const AttendanceRecordEntity({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.status,
    this.note,
  });

  String get initials {
    final parts = studentName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';
  }

  AttendanceRecordEntity copyWith({String? status, String? note}) =>
      AttendanceRecordEntity(
        studentId: studentId,
        studentName: studentName,
        studentCode: studentCode,
        status: status ?? this.status,
        note: note ?? this.note,
      );

  @override
  List<Object?> get props => [studentId, status];
}
