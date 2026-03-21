import 'package:equatable/equatable.dart';

class RecommendedCourseEntity extends Equatable {
  final String masterCourseId;
  final String courseName;
  final String courseCode;
  final String field;
  final String reason;
  final bool hasActiveBatch;

  const RecommendedCourseEntity({
    required this.masterCourseId,
    required this.courseName,
    required this.courseCode,
    required this.field,
    required this.reason,
    required this.hasActiveBatch,
  });

  @override
  List<Object?> get props => [masterCourseId];
}
