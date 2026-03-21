import 'package:equatable/equatable.dart';

class StudentEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String departmentId;
  final DateTime joinedAt;
  final bool isActive;
  final int activeBatchCount;
  final int completedCourseCount;
  // status: 'aktif' | 'tidak_aktif' | 'lulus'
  final String status;

  const StudentEntity({
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

  String get statusLabel => switch (status) {
        'aktif' => 'Aktif',
        'lulus' => 'Lulus',
        _ => 'Tidak Aktif',
      };

  @override
  List<Object?> get props => [id];
}
