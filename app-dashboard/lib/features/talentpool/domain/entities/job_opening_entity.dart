import 'package:equatable/equatable.dart';

class JobOpeningEntity extends Equatable {
  final String id;
  final String title;
  final String companyId;
  final String companyName;
  final String location;
  final int? salaryMin;
  final int? salaryMax;
  final String jobType;
  final String description;
  final List<String> requirements;
  final DateTime postedAt;
  final DateTime? deadline;
  final bool isActive;
  final String? requiredCourseName;
  final int applicantCount;

  const JobOpeningEntity({
    required this.id,
    required this.title,
    required this.companyId,
    required this.companyName,
    required this.location,
    this.salaryMin,
    this.salaryMax,
    required this.jobType,
    required this.description,
    required this.requirements,
    required this.postedAt,
    this.deadline,
    required this.isActive,
    this.requiredCourseName,
    required this.applicantCount,
  });

  String get salaryRange {
    if (salaryMin == null && salaryMax == null) return 'Negotiable';
    String fmt(int v) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}jt';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
      return v.toString();
    }
    if (salaryMin != null && salaryMax != null) {
      return 'Rp ${fmt(salaryMin!)} – ${fmt(salaryMax!)}';
    }
    if (salaryMin != null) return 'Mulai Rp ${fmt(salaryMin!)}';
    return 'Hingga Rp ${fmt(salaryMax!)}';
  }

  String get jobTypeLabel => switch (jobType.toLowerCase()) {
        'full_time' || 'full-time' || 'fulltime' => 'Full-time',
        'part_time' || 'part-time' || 'parttime' => 'Part-time',
        'remote' => 'Remote',
        'contract' => 'Kontrak',
        'internship' => 'Magang',
        _ => jobType,
      };

  bool get isDeadlinePassed =>
      deadline != null && deadline!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [id];
}
