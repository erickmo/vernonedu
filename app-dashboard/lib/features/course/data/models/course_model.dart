import '../../domain/entities/course_entity.dart';

// Model data layer untuk MasterCourse — bertanggung jawab parsing JSON dari API
class CourseModel {
  final String id;
  final String courseCode;
  final String courseName;
  final String field;
  final List<String> coreCompetencies;
  final String description;
  final String status;

  const CourseModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.field,
    required this.coreCompetencies,
    required this.description,
    required this.status,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
    id: json['id'] as String? ?? '',
    courseCode: json['course_code'] as String? ?? '',
    courseName: json['course_name'] as String? ?? '',
    field: json['field'] as String? ?? '',
    coreCompetencies: (json['core_competencies'] as List?)
        ?.map((e) => e as String)
        .toList() ?? [],
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? 'active',
  );

  // Konversi ke domain entity
  CourseEntity toEntity() => CourseEntity(
    id: id,
    courseCode: courseCode,
    courseName: courseName,
    field: field,
    coreCompetencies: coreCompetencies,
    description: description,
    status: status,
  );
}
