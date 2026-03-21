import '../../domain/entities/student_entity.dart';

class StudentModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String departmentId;
  final DateTime joinedAt;
  final bool isActive;
  final int activeBatchCount;
  final int completedCourseCount;
  final String status;

  const StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.departmentId,
    required this.joinedAt,
    required this.isActive,
    this.activeBatchCount = 0,
    this.completedCourseCount = 0,
    String? status,
  }) : status = status ?? (isActive ? 'aktif' : 'tidak_aktif');

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final isActive = json['is_active'] as bool? ?? true;
    final statusRaw = json['status'] as String?;
    final status = statusRaw ?? (isActive ? 'aktif' : 'tidak_aktif');
    return StudentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      departmentId: json['department_id'] as String? ?? '',
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isActive: isActive,
      activeBatchCount: json['active_batch_count'] as int? ?? 0,
      completedCourseCount: json['completed_course_count'] as int? ?? 0,
      status: status,
    );
  }

  StudentEntity toEntity() => StudentEntity(
        id: id,
        name: name,
        email: email,
        phone: phone,
        departmentId: departmentId,
        joinedAt: joinedAt,
        isActive: isActive,
        activeBatchCount: activeBatchCount,
        completedCourseCount: completedCourseCount,
        status: status,
      );
}
