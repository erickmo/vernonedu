import 'package:equatable/equatable.dart';

enum UserRole {
  director,
  educationLeader,
  deptLeader,
  courseOwner,
  facilitator,
  operationLeader,
  operationAdmin,
  customerService,
  marketing,
  accountingLeader,
  accountingStaff,
  student,
  partner;

  static UserRole fromString(String value) => switch (value.toLowerCase()) {
        'director' ||
        'superadministrator' ||
        'superadmin' ||
        'admin' =>
          UserRole.director,
        'education_leader' || 'educationleader' => UserRole.educationLeader,
        'dept_leader' || 'deptleader' => UserRole.deptLeader,
        'course_owner' || 'courseowner' => UserRole.courseOwner,
        'facilitator' => UserRole.facilitator,
        'operation_leader' || 'operationleader' => UserRole.operationLeader,
        'operation_admin' || 'operationadmin' => UserRole.operationAdmin,
        'customer_service' || 'customerservice' || 'cs' =>
          UserRole.customerService,
        'marketing' => UserRole.marketing,
        'accounting_leader' || 'accountingleader' => UserRole.accountingLeader,
        'accounting_staff' || 'accountingstaff' => UserRole.accountingStaff,
        'student' => UserRole.student,
        'partner' => UserRole.partner,
        _ => UserRole.student,
      };

  String get label => switch (this) {
        UserRole.director => 'Direktur',
        UserRole.educationLeader => 'Education Leader',
        UserRole.deptLeader => 'Kepala Departemen',
        UserRole.courseOwner => 'Course Owner',
        UserRole.facilitator => 'Fasilitator',
        UserRole.operationLeader => 'Operation Leader',
        UserRole.operationAdmin => 'Operation Administrator',
        UserRole.customerService => 'Customer Service',
        UserRole.marketing => 'Marketing',
        UserRole.accountingLeader => 'Accounting Leader',
        UserRole.accountingStaff => 'Accounting Staff',
        UserRole.student => 'Siswa',
        UserRole.partner => 'Partner',
      };

  bool get canAccessAdmin =>
      this != UserRole.student && this != UserRole.partner;

  // Education domain: curriculum, course, batch
  bool get canManageCourse =>
      this == UserRole.director ||
      this == UserRole.educationLeader ||
      this == UserRole.deptLeader ||
      this == UserRole.courseOwner;

  // Student & enrollment management
  bool get canManageStudent =>
      this == UserRole.director ||
      this == UserRole.educationLeader ||
      this == UserRole.deptLeader ||
      this == UserRole.courseOwner ||
      this == UserRole.customerService ||
      this == UserRole.operationLeader ||
      this == UserRole.operationAdmin;

  // Accounting & financial reports
  bool get canViewAccounting =>
      this == UserRole.director ||
      this == UserRole.accountingLeader ||
      this == UserRole.accountingStaff;

  // HRM / SDM
  bool get canViewHrm =>
      this == UserRole.director ||
      this == UserRole.educationLeader ||
      this == UserRole.deptLeader ||
      this == UserRole.operationLeader;

  // CRM & customer management
  bool get canViewCrm =>
      this == UserRole.director ||
      this == UserRole.customerService ||
      this == UserRole.marketing;

  // Operation team: batch scheduling, location, leads
  bool get isOperationTeam =>
      this == UserRole.operationLeader ||
      this == UserRole.operationAdmin ||
      this == UserRole.customerService ||
      this == UserRole.marketing;

  // Location & room management
  bool get canManageLocation =>
      this == UserRole.director ||
      this == UserRole.operationLeader ||
      this == UserRole.operationAdmin;

  // TalentPool access
  bool get canViewTalentPool =>
      this == UserRole.director ||
      this == UserRole.educationLeader ||
      this == UserRole.deptLeader ||
      this == UserRole.courseOwner;

  // Business Development (Director only)
  bool get canViewBusinessDev => this == UserRole.director;

  // Approvals — all staff have a queue relevant to their role
  bool get hasApprovals => canAccessAdmin;
}

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final List<UserRole> roles;
  final String? departmentId;
  final String? departmentName;
  final String? avatarUrl;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    this.departmentId,
    this.departmentName,
    this.avatarUrl,
    this.isActive = true,
  });

  // Returns the first role as the primary role, falls back to student.
  UserRole get primaryRole => roles.isNotEmpty ? roles.first : UserRole.student;

  // Check if user has a specific role.
  bool hasRole(UserRole r) => roles.contains(r);

  // Check if user has any of the given roles.
  bool hasAnyRole(List<UserRole> rs) => rs.any(roles.contains);

  // Comma-separated labels for all roles; shows 'Siswa' when empty.
  String get rolesLabel => roles.isEmpty
      ? 'Siswa'
      : roles.map((r) => r.label).join(', ');

  // Permission getters — union across all assigned roles.
  bool get canAccessAdmin => roles.any((r) => r.canAccessAdmin);
  bool get canManageCourse => roles.any((r) => r.canManageCourse);
  bool get canManageStudent => roles.any((r) => r.canManageStudent);
  bool get canViewAccounting => roles.any((r) => r.canViewAccounting);
  bool get canViewHrm => roles.any((r) => r.canViewHrm);
  bool get canViewCrm => roles.any((r) => r.canViewCrm);
  bool get isOperationTeam => roles.any((r) => r.isOperationTeam);
  bool get canManageLocation => roles.any((r) => r.canManageLocation);
  bool get canViewTalentPool => roles.any((r) => r.canViewTalentPool);
  bool get canViewBusinessDev => roles.any((r) => r.canViewBusinessDev);
  bool get hasApprovals => roles.any((r) => r.hasApprovals);

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, email, roles];
}
