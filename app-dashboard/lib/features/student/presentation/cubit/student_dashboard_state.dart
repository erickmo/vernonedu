import 'package:equatable/equatable.dart';

import '../../domain/entities/student_detail_entity.dart';
import '../../domain/entities/student_enrollment_history_entity.dart';
import '../../domain/entities/student_note_entity.dart';
import '../../domain/entities/recommended_course_entity.dart';
import '../../domain/entities/student_crm_log_entity.dart';
import '../../../talentpool/domain/entities/talentpool_entity.dart';

abstract class StudentDashboardState extends Equatable {
  const StudentDashboardState();

  @override
  List<Object?> get props => [];
}

class StudentDashboardInitial extends StudentDashboardState {
  const StudentDashboardInitial();
}

class StudentDashboardLoading extends StudentDashboardState {
  const StudentDashboardLoading();
}

class StudentDashboardLoaded extends StudentDashboardState {
  final StudentDetailEntity student;
  final List<StudentEnrollmentHistoryEntity> enrollmentHistory;
  final List<RecommendedCourseEntity> recommendations;
  final TalentPoolEntity? talentPool;
  final List<StudentNoteEntity> notes;
  final List<StudentCrmLogEntity> crmLogs;
  final bool isAddingNote;
  final bool isUpdating;
  final bool isAddingCrmLog;

  const StudentDashboardLoaded({
    required this.student,
    required this.enrollmentHistory,
    required this.recommendations,
    this.talentPool,
    required this.notes,
    this.crmLogs = const [],
    this.isAddingNote = false,
    this.isUpdating = false,
    this.isAddingCrmLog = false,
  });

  StudentDashboardLoaded copyWith({
    StudentDetailEntity? student,
    List<StudentEnrollmentHistoryEntity>? enrollmentHistory,
    List<RecommendedCourseEntity>? recommendations,
    TalentPoolEntity? talentPool,
    bool clearTalentPool = false,
    List<StudentNoteEntity>? notes,
    List<StudentCrmLogEntity>? crmLogs,
    bool? isAddingNote,
    bool? isUpdating,
    bool? isAddingCrmLog,
  }) {
    return StudentDashboardLoaded(
      student: student ?? this.student,
      enrollmentHistory: enrollmentHistory ?? this.enrollmentHistory,
      recommendations: recommendations ?? this.recommendations,
      talentPool: clearTalentPool ? null : (talentPool ?? this.talentPool),
      notes: notes ?? this.notes,
      crmLogs: crmLogs ?? this.crmLogs,
      isAddingNote: isAddingNote ?? this.isAddingNote,
      isUpdating: isUpdating ?? this.isUpdating,
      isAddingCrmLog: isAddingCrmLog ?? this.isAddingCrmLog,
    );
  }

  @override
  List<Object?> get props => [
        student,
        enrollmentHistory,
        recommendations,
        talentPool,
        notes,
        crmLogs,
        isAddingNote,
        isUpdating,
        isAddingCrmLog,
      ];
}

class StudentDashboardError extends StudentDashboardState {
  final String message;
  const StudentDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
