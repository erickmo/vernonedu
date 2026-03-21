import 'package:equatable/equatable.dart';

// Enum bidang (field) kursus yang tersedia di sistem
enum CourseField {
  coding,
  culinary,
  barber,
  publicSpeaking,
  entrepreneurship,
  other;

  static CourseField fromString(String v) => switch (v.toLowerCase()) {
    'coding' => CourseField.coding,
    'culinary' => CourseField.culinary,
    'barber' => CourseField.barber,
    'public_speaking' || 'publicspeaking' => CourseField.publicSpeaking,
    'entrepreneurship' => CourseField.entrepreneurship,
    _ => CourseField.other,
  };

  String get label => switch (this) {
    CourseField.coding => 'Coding',
    CourseField.culinary => 'Culinary',
    CourseField.barber => 'Barber',
    CourseField.publicSpeaking => 'Public Speaking',
    CourseField.entrepreneurship => 'Entrepreneurship',
    CourseField.other => 'Lainnya',
  };
}

// Entity utama MasterCourse — merepresentasikan satu kurikulum/kursus master
class CourseEntity extends Equatable {
  final String id;
  final String courseCode;
  final String courseName;
  final String field;
  final List<String> coreCompetencies;
  final String description;
  final String status; // active | archived

  const CourseEntity({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.field,
    required this.coreCompetencies,
    required this.description,
    required this.status,
  });

  // Shorthand untuk mengecek apakah course masih aktif
  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [id];
}
