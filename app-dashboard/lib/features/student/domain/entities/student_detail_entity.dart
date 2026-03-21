import 'package:equatable/equatable.dart';

class StudentDetailEntity extends Equatable {
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

  const StudentDetailEntity({
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

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get statusLabel => isActive ? 'Aktif' : 'Nonaktif';

  String get genderLabel => switch (gender?.toLowerCase()) {
        'male' || 'laki-laki' || 'l' => 'Laki-laki',
        'female' || 'perempuan' || 'p' => 'Perempuan',
        _ => '-',
      };

  @override
  List<Object?> get props => [id];
}
