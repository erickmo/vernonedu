import 'package:equatable/equatable.dart';

class DepartmentCourseEntity extends Equatable {
  final String courseId;
  final String courseName;
  final String description;
  final bool isActive;
  final int batchCount;

  const DepartmentCourseEntity({
    required this.courseId,
    required this.courseName,
    required this.description,
    required this.isActive,
    required this.batchCount,
  });

  @override
  List<Object?> get props => [courseId];
}
