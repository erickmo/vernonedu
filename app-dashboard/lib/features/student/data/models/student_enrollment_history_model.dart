import '../../domain/entities/student_enrollment_history_entity.dart';

class StudentEnrollmentHistoryModel {
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

  const StudentEnrollmentHistoryModel({
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

  factory StudentEnrollmentHistoryModel.fromJson(Map<String, dynamic> json) {
    return StudentEnrollmentHistoryModel(
      id: json['id']?.toString() ?? '',
      batchId: json['batch_id']?.toString() ?? '',
      batchCode: json['batch_code']?.toString() ?? '',
      batchName: json['batch_name']?.toString() ?? '',
      batchType: json['batch_type']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
      courseCode: json['course_code']?.toString() ?? '',
      masterCourseName: json['master_course_name']?.toString() ?? '',
      enrolledAt: json['enrolled_at'] != null
          ? DateTime.tryParse(json['enrolled_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalAttendance: _parseInt(json['total_attendance']),
      totalSessions: _parseInt(json['total_sessions']),
      finalScore: _parseDouble(json['final_score']),
      grade: json['grade']?.toString(),
      status: json['status']?.toString() ?? 'active',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
    );
  }

  StudentEnrollmentHistoryEntity toEntity() => StudentEnrollmentHistoryEntity(
        id: id,
        batchId: batchId,
        batchCode: batchCode,
        batchName: batchName,
        batchType: batchType,
        courseName: courseName,
        courseCode: courseCode,
        masterCourseName: masterCourseName,
        enrolledAt: enrolledAt,
        totalAttendance: totalAttendance,
        totalSessions: totalSessions,
        finalScore: finalScore,
        grade: grade,
        status: status,
        paymentStatus: paymentStatus,
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
