import '../../domain/entities/attendance_record_entity.dart';

class AttendanceRecordModel {
  final String studentId;
  final String studentName;
  final String studentCode;
  final String status;
  final String? note;

  const AttendanceRecordModel({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.status,
    this.note,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordModel(
        studentId: json['student_id'] as String,
        studentName: json['student_name'] as String? ?? '',
        studentCode: json['student_code'] as String? ?? '',
        status: json['status'] as String? ?? 'absent',
        note: json['note'] as String?,
      );

  AttendanceRecordEntity toEntity() => AttendanceRecordEntity(
        studentId: studentId,
        studentName: studentName,
        studentCode: studentCode,
        status: status,
        note: note,
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'status': status,
        if (note != null) 'note': note,
      };
}
