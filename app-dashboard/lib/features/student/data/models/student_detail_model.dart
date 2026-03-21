import '../../domain/entities/student_detail_entity.dart';

class StudentDetailModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String departmentId;
  final String departmentName;
  final DateTime joinedAt;
  final bool isActive;
  final String? avatarUrl;
  final String? address;
  final String? birthDate;
  final String? gender;
  final String? nik;
  final int totalEnrollments;
  final int completedCourses;
  final double? averageScore;

  const StudentDetailModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.departmentId,
    required this.departmentName,
    required this.joinedAt,
    required this.isActive,
    this.avatarUrl,
    this.address,
    this.birthDate,
    this.gender,
    this.nik,
    required this.totalEnrollments,
    required this.completedCourses,
    this.averageScore,
  });

  factory StudentDetailModel.fromJson(Map<String, dynamic> json) {
    return StudentDetailModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      departmentId: json['department_id']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? '',
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      avatarUrl: json['avatar_url']?.toString(),
      address: json['address']?.toString(),
      birthDate: json['birth_date']?.toString(),
      gender: json['gender']?.toString(),
      nik: json['nik']?.toString(),
      totalEnrollments: _parseInt(json['total_enrollments']),
      completedCourses: _parseInt(json['completed_courses']),
      averageScore: _parseDouble(json['average_score']),
    );
  }

  StudentDetailEntity toEntity() => StudentDetailEntity(
        id: id,
        name: name,
        email: email,
        phone: phone,
        departmentId: departmentId,
        departmentName: departmentName,
        joinedAt: joinedAt,
        isActive: isActive,
        avatarUrl: avatarUrl,
        address: address,
        birthDate: birthDate,
        gender: gender,
        nik: nik,
        totalEnrollments: totalEnrollments,
        completedCourses: completedCourses,
        averageScore: averageScore,
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
