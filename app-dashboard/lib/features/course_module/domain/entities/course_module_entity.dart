import 'package:equatable/equatable.dart';

// Entity domain untuk CourseModule — satu versi course memiliki beberapa modul
class CourseModuleEntity extends Equatable {
  final String id;
  final String courseVersionId;
  final String moduleCode; // contoh: M1, M2, M3
  final String moduleTitle;
  final double durationHours;
  final int sequence; // urutan tampil
  final String contentDepth; // intro | standard | advanced
  final List<String> topics;
  final List<String> practicalActivities;
  final String assessmentMethod;
  final List<String> toolsRequired;
  final bool isReference;

  const CourseModuleEntity({
    required this.id,
    required this.courseVersionId,
    required this.moduleCode,
    required this.moduleTitle,
    required this.durationHours,
    required this.sequence,
    required this.contentDepth,
    required this.topics,
    required this.practicalActivities,
    required this.assessmentMethod,
    required this.toolsRequired,
    required this.isReference,
  });

  // Label contentDepth yang ditampilkan ke user
  String get contentDepthLabel => switch (contentDepth) {
        'intro' => 'Intro',
        'standard' => 'Standard',
        'advanced' => 'Advanced',
        _ => contentDepth,
      };

  @override
  List<Object?> get props => [id];
}
