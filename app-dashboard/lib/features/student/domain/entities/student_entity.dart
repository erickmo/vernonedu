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
  });

  @override
  List<Object?> get props => [id];
}
