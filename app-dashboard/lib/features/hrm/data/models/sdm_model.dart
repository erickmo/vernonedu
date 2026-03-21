import '../../domain/entities/sdm_entity.dart';

// ─── Helper ───────────────────────────────────────────────────────────────────

SdmRole _roleFromString(String? v) {
  switch (v) {
    case 'course_creator':
      return SdmRole.courseCreator;
    case 'facilitator':
      return SdmRole.facilitator;
    case 'head_of_program':
      return SdmRole.headOfProgram;
    case 'coordinator':
      return SdmRole.coordinator;
    case 'admin':
      return SdmRole.admin;
    default:
      return SdmRole.other;
  }
}

SdmStatus _statusFromString(String? v) {
  switch (v) {
    case 'active':
      return SdmStatus.active;
    case 'inactive':
      return SdmStatus.inactive;
    case 'on_leave':
      return SdmStatus.onLeave;
    default:
      return SdmStatus.active;
  }
}

SdmPaymentType _paymentTypeFromString(String? v) {
  switch (v) {
    case 'honorarium':
      return SdmPaymentType.honorarium;
    case 'bonus':
      return SdmPaymentType.bonus;
    case 'reimbursement':
      return SdmPaymentType.reimbursement;
    default:
      return SdmPaymentType.other;
  }
}

SdmPaymentStatus _paymentStatusFromString(String? v) {
  switch (v) {
    case 'paid':
      return SdmPaymentStatus.paid;
    case 'pending':
      return SdmPaymentStatus.pending;
    case 'cancelled':
      return SdmPaymentStatus.cancelled;
    default:
      return SdmPaymentStatus.pending;
  }
}

SdmScheduleType _scheduleTypeFromString(String? v) {
  switch (v) {
    case 'class_session':
      return SdmScheduleType.clasSession;
    case 'meeting':
      return SdmScheduleType.meeting;
    case 'review':
      return SdmScheduleType.review;
    case 'training':
      return SdmScheduleType.training;
    default:
      return SdmScheduleType.other;
  }
}

SdmScheduleStatus _scheduleStatusFromString(String? v) {
  switch (v) {
    case 'upcoming':
      return SdmScheduleStatus.upcoming;
    case 'ongoing':
      return SdmScheduleStatus.ongoing;
    case 'completed':
      return SdmScheduleStatus.completed;
    case 'cancelled':
      return SdmScheduleStatus.cancelled;
    default:
      return SdmScheduleStatus.upcoming;
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class SdmEducationModel {
  final String institution;
  final String degree;
  final String field;
  final int startYear;
  final int? endYear;
  final double? gpa;
  final bool isCurrent;

  const SdmEducationModel({
    required this.institution,
    required this.degree,
    required this.field,
    required this.startYear,
    this.endYear,
    this.gpa,
    this.isCurrent = false,
  });

  factory SdmEducationModel.fromJson(Map<String, dynamic> json) =>
      SdmEducationModel(
        institution: json['institution'] as String? ?? '',
        degree: json['degree'] as String? ?? '',
        field: json['field'] as String? ?? '',
        startYear: json['start_year'] as int? ?? 0,
        endYear: json['end_year'] as int?,
        gpa: (json['gpa'] as num?)?.toDouble(),
        isCurrent: json['is_current'] as bool? ?? false,
      );

  SdmEducationEntity toEntity() => SdmEducationEntity(
        institution: institution,
        degree: degree,
        field: field,
        startYear: startYear,
        endYear: endYear,
        gpa: gpa,
        isCurrent: isCurrent,
      );
}

class SdmWorkExperienceModel {
  final String company;
  final String position;
  final DateTime startDate;
  final DateTime? endDate;
  final String? description;
  final bool isCurrent;

  const SdmWorkExperienceModel({
    required this.company,
    required this.position,
    required this.startDate,
    this.endDate,
    this.description,
    this.isCurrent = false,
  });

  factory SdmWorkExperienceModel.fromJson(Map<String, dynamic> json) =>
      SdmWorkExperienceModel(
        company: json['company'] as String? ?? '',
        position: json['position'] as String? ?? '',
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        description: json['description'] as String?,
        isCurrent: json['is_current'] as bool? ?? false,
      );

  SdmWorkExperienceEntity toEntity() => SdmWorkExperienceEntity(
        company: company,
        position: position,
        startDate: startDate,
        endDate: endDate,
        description: description,
        isCurrent: isCurrent,
      );
}

class SdmCertificationModel {
  final String name;
  final String issuer;
  final DateTime issuedDate;
  final DateTime? expiryDate;
  final String? certificateNumber;

  const SdmCertificationModel({
    required this.name,
    required this.issuer,
    required this.issuedDate,
    this.expiryDate,
    this.certificateNumber,
  });

  factory SdmCertificationModel.fromJson(Map<String, dynamic> json) =>
      SdmCertificationModel(
        name: json['name'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        issuedDate: DateTime.parse(json['issued_date'] as String),
        expiryDate: json['expiry_date'] != null
            ? DateTime.parse(json['expiry_date'] as String)
            : null,
        certificateNumber: json['certificate_number'] as String?,
      );

  SdmCertificationEntity toEntity() => SdmCertificationEntity(
        name: name,
        issuer: issuer,
        issuedDate: issuedDate,
        expiryDate: expiryDate,
        certificateNumber: certificateNumber,
      );
}

class SdmResumeModel {
  final String? summary;
  final List<SdmEducationModel> education;
  final List<SdmWorkExperienceModel> workExperience;
  final List<String> skills;
  final List<SdmCertificationModel> certifications;
  final List<Map<String, String>> languages;
  final String? portfolioUrl;
  final String? linkedInUrl;
  final String? githubUrl;

  const SdmResumeModel({
    this.summary,
    required this.education,
    required this.workExperience,
    required this.skills,
    required this.certifications,
    required this.languages,
    this.portfolioUrl,
    this.linkedInUrl,
    this.githubUrl,
  });

  factory SdmResumeModel.fromJson(Map<String, dynamic> json) => SdmResumeModel(
        summary: json['summary'] as String?,
        education: (json['education'] as List<dynamic>? ?? [])
            .map((e) =>
                SdmEducationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        workExperience: (json['work_experience'] as List<dynamic>? ?? [])
            .map((e) =>
                SdmWorkExperienceModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: (json['skills'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        certifications: (json['certifications'] as List<dynamic>? ?? [])
            .map((e) =>
                SdmCertificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        languages: (json['languages'] as List<dynamic>? ?? [])
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
        portfolioUrl: json['portfolio_url'] as String?,
        linkedInUrl: json['linkedin_url'] as String?,
        githubUrl: json['github_url'] as String?,
      );

  SdmResumeEntity toEntity() => SdmResumeEntity(
        summary: summary,
        education: education.map((e) => e.toEntity()).toList(),
        workExperience: workExperience.map((e) => e.toEntity()).toList(),
        skills: skills,
        certifications: certifications.map((e) => e.toEntity()).toList(),
        languages: languages
            .map((e) => SdmLanguageEntity(
                  language: e['language'] ?? '',
                  proficiency: e['proficiency'] ?? '',
                ))
            .toList(),
        portfolioUrl: portfolioUrl,
        linkedInUrl: linkedInUrl,
        githubUrl: githubUrl,
      );
}

class SdmModel {
  final String id;
  final String name;
  final String? photoUrl;
  final String role;
  final String email;
  final String? phone;
  final String? department;
  final DateTime joinDate;
  final String status;
  final double? rating;
  final int totalStudentsTaught;
  final int totalPrograms;

  const SdmModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.role,
    required this.email,
    this.phone,
    this.department,
    required this.joinDate,
    required this.status,
    this.rating,
    required this.totalStudentsTaught,
    required this.totalPrograms,
  });

  factory SdmModel.fromJson(Map<String, dynamic> json) => SdmModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
        role: json['role'] as String? ?? 'other',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        department: json['department'] as String?,
        joinDate: DateTime.parse(json['join_date'] as String),
        status: json['status'] as String? ?? 'active',
        rating: (json['rating'] as num?)?.toDouble(),
        totalStudentsTaught: json['total_students_taught'] as int? ?? 0,
        totalPrograms: json['total_programs'] as int? ?? 0,
      );

  SdmEntity toEntity() => SdmEntity(
        id: id,
        name: name,
        photoUrl: photoUrl,
        role: _roleFromString(role),
        email: email,
        phone: phone,
        department: department,
        joinDate: joinDate,
        status: _statusFromString(status),
        rating: rating,
        totalStudentsTaught: totalStudentsTaught,
        totalPrograms: totalPrograms,
      );
}

class SdmProgramModel {
  final String programId;
  final String programName;
  final String roleInProgram;
  final String courseTypeName;
  final String? batchName;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final int? studentCount;

  const SdmProgramModel({
    required this.programId,
    required this.programName,
    required this.roleInProgram,
    required this.courseTypeName,
    this.batchName,
    required this.startDate,
    this.endDate,
    required this.status,
    this.studentCount,
  });

  factory SdmProgramModel.fromJson(Map<String, dynamic> json) =>
      SdmProgramModel(
        programId: json['program_id'] as String? ?? '',
        programName: json['program_name'] as String? ?? '',
        roleInProgram: json['role_in_program'] as String? ?? 'other',
        courseTypeName: json['course_type_name'] as String? ?? '',
        batchName: json['batch_name'] as String?,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        status: json['status'] as String? ?? 'active',
        studentCount: json['student_count'] as int?,
      );

  SdmProgramEntity toEntity() => SdmProgramEntity(
        programId: programId,
        programName: programName,
        roleInProgram: _roleFromString(roleInProgram),
        courseTypeName: courseTypeName,
        batchName: batchName,
        startDate: startDate,
        endDate: endDate,
        status: status,
        studentCount: studentCount,
      );
}

class SdmClassHistoryModel {
  final String batchId;
  final String batchName;
  final String courseName;
  final String roleInClass;
  final DateTime startDate;
  final DateTime? endDate;
  final int studentCount;
  final double? completionRate;
  final double? rating;

  const SdmClassHistoryModel({
    required this.batchId,
    required this.batchName,
    required this.courseName,
    required this.roleInClass,
    required this.startDate,
    this.endDate,
    required this.studentCount,
    this.completionRate,
    this.rating,
  });

  factory SdmClassHistoryModel.fromJson(Map<String, dynamic> json) =>
      SdmClassHistoryModel(
        batchId: json['batch_id'] as String? ?? '',
        batchName: json['batch_name'] as String? ?? '',
        courseName: json['course_name'] as String? ?? '',
        roleInClass: json['role_in_class'] as String? ?? 'other',
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        studentCount: json['student_count'] as int? ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble(),
        rating: (json['rating'] as num?)?.toDouble(),
      );

  SdmClassHistoryEntity toEntity() => SdmClassHistoryEntity(
        batchId: batchId,
        batchName: batchName,
        courseName: courseName,
        roleInClass: _roleFromString(roleInClass),
        startDate: startDate,
        endDate: endDate,
        studentCount: studentCount,
        completionRate: completionRate,
        rating: rating,
      );
}

class SdmPaymentModel {
  final String id;
  final DateTime date;
  final String description;
  final String? programName;
  final double amount;
  final String type;
  final String status;
  final String? paymentMethod;

  const SdmPaymentModel({
    required this.id,
    required this.date,
    required this.description,
    this.programName,
    required this.amount,
    required this.type,
    required this.status,
    this.paymentMethod,
  });

  factory SdmPaymentModel.fromJson(Map<String, dynamic> json) =>
      SdmPaymentModel(
        id: json['id'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String? ?? '',
        programName: json['program_name'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        type: json['type'] as String? ?? 'other',
        status: json['status'] as String? ?? 'pending',
        paymentMethod: json['payment_method'] as String?,
      );

  SdmPaymentEntity toEntity() => SdmPaymentEntity(
        id: id,
        date: date,
        description: description,
        programName: programName,
        amount: amount,
        type: _paymentTypeFromString(type),
        status: _paymentStatusFromString(status),
        paymentMethod: paymentMethod,
      );
}

class SdmEvaluationModel {
  final String id;
  final DateTime date;
  final String evaluator;
  final String category;
  final double score;
  final String notes;
  final List<String> tags;

  const SdmEvaluationModel({
    required this.id,
    required this.date,
    required this.evaluator,
    required this.category,
    required this.score,
    required this.notes,
    required this.tags,
  });

  factory SdmEvaluationModel.fromJson(Map<String, dynamic> json) =>
      SdmEvaluationModel(
        id: json['id'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        evaluator: json['evaluator'] as String? ?? '',
        category: json['category'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );

  SdmEvaluationEntity toEntity() => SdmEvaluationEntity(
        id: id,
        date: date,
        evaluator: evaluator,
        category: category,
        score: score,
        notes: notes,
        tags: tags,
      );
}

class SdmScheduleModel {
  final String id;
  final String title;
  final String type;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? location;
  final String? description;
  final String? programName;
  final String status;

  const SdmScheduleModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.location,
    this.description,
    this.programName,
    required this.status,
  });

  factory SdmScheduleModel.fromJson(Map<String, dynamic> json) =>
      SdmScheduleModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: json['type'] as String? ?? 'other',
        date: DateTime.parse(json['date'] as String),
        startTime: json['start_time'] as String? ?? '00:00',
        endTime: json['end_time'] as String? ?? '00:00',
        location: json['location'] as String?,
        description: json['description'] as String?,
        programName: json['program_name'] as String?,
        status: json['status'] as String? ?? 'upcoming',
      );

  SdmScheduleEntity toEntity() => SdmScheduleEntity(
        id: id,
        title: title,
        type: _scheduleTypeFromString(type),
        date: date,
        startTime: startTime,
        endTime: endTime,
        location: location,
        description: description,
        programName: programName,
        status: _scheduleStatusFromString(status),
      );
}

class SdmDocumentModel {
  final String id;
  final String name;
  final String type;
  final DateTime uploadDate;
  final String? url;
  final String? fileSize;

  const SdmDocumentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.uploadDate,
    this.url,
    this.fileSize,
  });

  factory SdmDocumentModel.fromJson(Map<String, dynamic> json) =>
      SdmDocumentModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'other',
        uploadDate: DateTime.parse(json['upload_date'] as String),
        url: json['url'] as String?,
        fileSize: json['file_size'] as String?,
      );

  SdmDocumentEntity toEntity() => SdmDocumentEntity(
        id: id,
        name: name,
        type: type,
        uploadDate: uploadDate,
        url: url,
        fileSize: fileSize,
      );
}

class SdmDetailModel {
  final String id;
  final String name;
  final String? photoUrl;
  final String role;
  final String email;
  final String? phone;
  final String? department;
  final DateTime joinDate;
  final String status;
  final SdmResumeModel resume;
  final List<SdmProgramModel> programs;
  final List<SdmClassHistoryModel> classHistory;
  final List<SdmPaymentModel> paymentHistory;
  final List<SdmEvaluationModel> evaluations;
  final List<SdmScheduleModel> schedules;
  final List<SdmDocumentModel> documents;
  final Map<String, dynamic> stats;

  const SdmDetailModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.role,
    required this.email,
    this.phone,
    this.department,
    required this.joinDate,
    required this.status,
    required this.resume,
    required this.programs,
    required this.classHistory,
    required this.paymentHistory,
    required this.evaluations,
    required this.schedules,
    required this.documents,
    required this.stats,
  });

  factory SdmDetailModel.fromJson(Map<String, dynamic> json) => SdmDetailModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
        role: json['role'] as String? ?? 'other',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        department: json['department'] as String?,
        joinDate: DateTime.parse(json['join_date'] as String),
        status: json['status'] as String? ?? 'active',
        resume: SdmResumeModel.fromJson(
            json['resume'] as Map<String, dynamic>? ?? {}),
        programs: (json['programs'] as List<dynamic>? ?? [])
            .map((e) => SdmProgramModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        classHistory: (json['class_history'] as List<dynamic>? ?? [])
            .map(
                (e) => SdmClassHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        paymentHistory: (json['payment_history'] as List<dynamic>? ?? [])
            .map((e) => SdmPaymentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        evaluations: (json['evaluations'] as List<dynamic>? ?? [])
            .map(
                (e) => SdmEvaluationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        schedules: (json['schedules'] as List<dynamic>? ?? [])
            .map((e) => SdmScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        documents: (json['documents'] as List<dynamic>? ?? [])
            .map((e) => SdmDocumentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        stats: json['stats'] as Map<String, dynamic>? ?? {},
      );

  SdmDetailEntity toEntity() => SdmDetailEntity(
        id: id,
        name: name,
        photoUrl: photoUrl,
        role: _roleFromString(role),
        email: email,
        phone: phone,
        department: department,
        joinDate: joinDate,
        status: _statusFromString(status),
        resume: resume.toEntity(),
        programs: programs.map((e) => e.toEntity()).toList(),
        classHistory: classHistory.map((e) => e.toEntity()).toList(),
        paymentHistory: paymentHistory.map((e) => e.toEntity()).toList(),
        evaluations: evaluations.map((e) => e.toEntity()).toList(),
        schedules: schedules.map((e) => e.toEntity()).toList(),
        documents: documents.map((e) => e.toEntity()).toList(),
        stats: SdmStatsEntity(
          totalPrograms: stats['total_programs'] as int? ?? 0,
          totalStudents: stats['total_students'] as int? ?? 0,
          averageRating: (stats['average_rating'] as num?)?.toDouble() ?? 0,
          completionRate: (stats['completion_rate'] as num?)?.toDouble() ?? 0,
          totalEarnings: (stats['total_earnings'] as num?)?.toDouble() ?? 0,
          yearsActive: stats['years_active'] as int? ?? 0,
        ),
      );
}
