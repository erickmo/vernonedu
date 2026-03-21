import 'package:equatable/equatable.dart';

class DepartmentStudentEntity extends Equatable {
  final String studentId;
  final String studentName;
  final String email;
  final String phone;
  final bool isActive;
  final int joinedAt;
  final int enrolledBatchCount;

  const DepartmentStudentEntity({
    required this.studentId,
    required this.studentName,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.joinedAt,
    required this.enrolledBatchCount,
  });

  String get statusLabel => isActive ? 'Aktif' : 'Alumni';

  String get initials {
    final parts = studentName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [studentId];
}
