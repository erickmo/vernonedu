import '../../domain/entities/job_opening_entity.dart';

class JobOpeningModel {
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

  const JobOpeningModel({
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

  factory JobOpeningModel.fromJson(Map<String, dynamic> json) {
    final reqs = json['requirements'];
    final reqList = reqs is List
        ? reqs.map((e) => e.toString()).toList()
        : <String>[];

    return JobOpeningModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      salaryMin: _parseInt(json['salary_min']),
      salaryMax: _parseInt(json['salary_max']),
      jobType: json['job_type']?.toString() ?? 'full_time',
      description: json['description']?.toString() ?? '',
      requirements: reqList,
      postedAt: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      requiredCourseName: json['required_course_name']?.toString(),
      applicantCount: _parseInt(json['applicant_count']) ?? 0,
    );
  }

  JobOpeningEntity toEntity() => JobOpeningEntity(
        id: id,
        title: title,
        companyId: companyId,
        companyName: companyName,
        location: location,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        jobType: jobType,
        description: description,
        requirements: requirements,
        postedAt: postedAt,
        deadline: deadline,
        isActive: isActive,
        requiredCourseName: requiredCourseName,
        applicantCount: applicantCount,
      );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
