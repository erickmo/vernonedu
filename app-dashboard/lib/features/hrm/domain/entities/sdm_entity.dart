import 'package:equatable/equatable.dart';

/// Peran SDM di platform VernonEdu.
enum SdmRole {
  courseCreator,
  facilitator,
  headOfProgram,
  coordinator,
  admin,
  other;

  String get label {
    switch (this) {
      case SdmRole.courseCreator:
        return 'Course Creator';
      case SdmRole.facilitator:
        return 'Fasilitator';
      case SdmRole.headOfProgram:
        return 'Kepala Program';
      case SdmRole.coordinator:
        return 'Koordinator';
      case SdmRole.admin:
        return 'Admin';
      case SdmRole.other:
        return 'Lainnya';
    }
  }
}

/// Status SDM.
enum SdmStatus { active, inactive, onLeave }

/// Entitas ringkasan SDM untuk tampilan daftar.
class SdmEntity extends Equatable {
  final String id;
  final String name;
  final String? photoUrl;
  final SdmRole role;
  final String email;
  final String? phone;
  final String? department;
  final DateTime joinDate;
  final SdmStatus status;
  final double? rating;
  final int totalStudentsTaught;
  final int totalPrograms;

  const SdmEntity({
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

  @override
  List<Object?> get props => [
        id,
        name,
        photoUrl,
        role,
        email,
        phone,
        department,
        joinDate,
        status,
        rating,
        totalStudentsTaught,
        totalPrograms,
      ];
}

// ─── Nested Entities ──────────────────────────────────────────────────────────

/// Data pendidikan SDM.
class SdmEducationEntity extends Equatable {
  final String institution;
  final String degree;
  final String field;
  final int startYear;
  final int? endYear;
  final double? gpa;
  final bool isCurrent;

  const SdmEducationEntity({
    required this.institution,
    required this.degree,
    required this.field,
    required this.startYear,
    this.endYear,
    this.gpa,
    this.isCurrent = false,
  });

  @override
  List<Object?> get props =>
      [institution, degree, field, startYear, endYear, gpa, isCurrent];
}

/// Pengalaman kerja SDM.
class SdmWorkExperienceEntity extends Equatable {
  final String company;
  final String position;
  final DateTime startDate;
  final DateTime? endDate;
  final String? description;
  final bool isCurrent;

  const SdmWorkExperienceEntity({
    required this.company,
    required this.position,
    required this.startDate,
    this.endDate,
    this.description,
    this.isCurrent = false,
  });

  @override
  List<Object?> get props =>
      [company, position, startDate, endDate, description, isCurrent];
}

/// Sertifikasi SDM.
class SdmCertificationEntity extends Equatable {
  final String name;
  final String issuer;
  final DateTime issuedDate;
  final DateTime? expiryDate;
  final String? certificateNumber;

  const SdmCertificationEntity({
    required this.name,
    required this.issuer,
    required this.issuedDate,
    this.expiryDate,
    this.certificateNumber,
  });

  @override
  List<Object?> get props =>
      [name, issuer, issuedDate, expiryDate, certificateNumber];
}

/// Kemampuan bahasa SDM.
class SdmLanguageEntity extends Equatable {
  final String language;
  final String proficiency;

  const SdmLanguageEntity({
    required this.language,
    required this.proficiency,
  });

  @override
  List<Object?> get props => [language, proficiency];
}

/// CV / Resume SDM.
class SdmResumeEntity extends Equatable {
  final String? summary;
  final List<SdmEducationEntity> education;
  final List<SdmWorkExperienceEntity> workExperience;
  final List<String> skills;
  final List<SdmCertificationEntity> certifications;
  final List<SdmLanguageEntity> languages;
  final String? portfolioUrl;
  final String? linkedInUrl;
  final String? githubUrl;

  const SdmResumeEntity({
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

  @override
  List<Object?> get props => [
        summary,
        education,
        workExperience,
        skills,
        certifications,
        languages,
        portfolioUrl,
        linkedInUrl,
        githubUrl,
      ];
}

/// Keterlibatan SDM dalam program/kursus.
class SdmProgramEntity extends Equatable {
  final String programId;
  final String programName;
  final SdmRole roleInProgram;
  final String courseTypeName;
  final String? batchName;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final int? studentCount;

  const SdmProgramEntity({
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

  @override
  List<Object?> get props => [
        programId,
        programName,
        roleInProgram,
        courseTypeName,
        batchName,
        startDate,
        endDate,
        status,
        studentCount,
      ];
}

/// Riwayat kelas yang pernah diikuti / diajar SDM.
class SdmClassHistoryEntity extends Equatable {
  final String batchId;
  final String batchName;
  final String courseName;
  final SdmRole roleInClass;
  final DateTime startDate;
  final DateTime? endDate;
  final int studentCount;
  final double? completionRate;
  final double? rating;

  const SdmClassHistoryEntity({
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

  @override
  List<Object?> get props => [
        batchId,
        batchName,
        courseName,
        roleInClass,
        startDate,
        endDate,
        studentCount,
        completionRate,
        rating,
      ];
}

/// Jenis pembayaran fee SDM.
enum SdmPaymentType { honorarium, bonus, reimbursement, other }

/// Status pembayaran.
enum SdmPaymentStatus { paid, pending, cancelled }

/// Riwayat pembayaran / fee SDM.
class SdmPaymentEntity extends Equatable {
  final String id;
  final DateTime date;
  final String description;
  final String? programName;
  final double amount;
  final SdmPaymentType type;
  final SdmPaymentStatus status;
  final String? paymentMethod;

  const SdmPaymentEntity({
    required this.id,
    required this.date,
    required this.description,
    this.programName,
    required this.amount,
    required this.type,
    required this.status,
    this.paymentMethod,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        description,
        programName,
        amount,
        type,
        status,
        paymentMethod,
      ];
}

/// Catatan evaluasi SDM.
class SdmEvaluationEntity extends Equatable {
  final String id;
  final DateTime date;
  final String evaluator;
  final String category;
  final double score;
  final String notes;
  final List<String> tags;

  const SdmEvaluationEntity({
    required this.id,
    required this.date,
    required this.evaluator,
    required this.category,
    required this.score,
    required this.notes,
    required this.tags,
  });

  @override
  List<Object?> get props =>
      [id, date, evaluator, category, score, notes, tags];
}

/// Jenis jadwal.
enum SdmScheduleType { clasSession, meeting, review, training, other }

/// Status jadwal.
enum SdmScheduleStatus { upcoming, ongoing, completed, cancelled }

/// Jadwal SDM.
class SdmScheduleEntity extends Equatable {
  final String id;
  final String title;
  final SdmScheduleType type;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? location;
  final String? description;
  final String? programName;
  final SdmScheduleStatus status;

  const SdmScheduleEntity({
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

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        date,
        startTime,
        endTime,
        location,
        description,
        programName,
        status,
      ];
}

/// Dokumen SDM.
class SdmDocumentEntity extends Equatable {
  final String id;
  final String name;
  final String type;
  final DateTime uploadDate;
  final String? url;
  final String? fileSize;

  const SdmDocumentEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.uploadDate,
    this.url,
    this.fileSize,
  });

  @override
  List<Object?> get props => [id, name, type, uploadDate, url, fileSize];
}

/// Statistik kinerja SDM.
class SdmStatsEntity extends Equatable {
  final int totalPrograms;
  final int totalStudents;
  final double averageRating;
  final double completionRate;
  final double totalEarnings;
  final int yearsActive;

  const SdmStatsEntity({
    required this.totalPrograms,
    required this.totalStudents,
    required this.averageRating,
    required this.completionRate,
    required this.totalEarnings,
    required this.yearsActive,
  });

  @override
  List<Object?> get props => [
        totalPrograms,
        totalStudents,
        averageRating,
        completionRate,
        totalEarnings,
        yearsActive,
      ];
}

/// Entitas detail lengkap SDM.
class SdmDetailEntity extends Equatable {
  final String id;
  final String name;
  final String? photoUrl;
  final SdmRole role;
  final String email;
  final String? phone;
  final String? department;
  final DateTime joinDate;
  final SdmStatus status;
  final SdmResumeEntity resume;
  final List<SdmProgramEntity> programs;
  final List<SdmClassHistoryEntity> classHistory;
  final List<SdmPaymentEntity> paymentHistory;
  final List<SdmEvaluationEntity> evaluations;
  final List<SdmScheduleEntity> schedules;
  final List<SdmDocumentEntity> documents;
  final SdmStatsEntity stats;

  const SdmDetailEntity({
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

  @override
  List<Object?> get props => [
        id,
        name,
        photoUrl,
        role,
        email,
        phone,
        department,
        joinDate,
        status,
        resume,
        programs,
        classHistory,
        paymentHistory,
        evaluations,
        schedules,
        documents,
        stats,
      ];
}
