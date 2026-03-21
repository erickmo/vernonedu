import 'package:equatable/equatable.dart';

class AuthUserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? departmentId;
  final String? departmentName;
  final String? photoUrl;

  const AuthUserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
    this.departmentName,
    this.photoUrl,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get roleLabel => switch (role) {
        'course_owner' => 'Course Owner',
        'facilitator' => 'Fasilitator',
        'mentor' => 'Mentor',
        'director' => 'Direktur',
        'dept_leader' => 'Kepala Departemen',
        _ => role,
      };

  bool get isCourseOwner => role == 'course_owner' || role == 'director' || role == 'dept_leader';
  bool get canAssignFacilitator => isCourseOwner;
  bool get canTakeAttendance => role == 'facilitator' || role == 'mentor' || isCourseOwner;

  @override
  List<Object?> get props => [id, email, role];
}
