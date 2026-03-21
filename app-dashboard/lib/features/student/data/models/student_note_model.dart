import '../../domain/entities/student_note_entity.dart';

class StudentNoteModel {
  final String id;
  final String studentId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const StudentNoteModel({
    required this.id,
    required this.studentId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory StudentNoteModel.fromJson(Map<String, dynamic> json) {
    return StudentNoteModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  StudentNoteEntity toEntity() => StudentNoteEntity(
        id: id,
        studentId: studentId,
        authorId: authorId,
        authorName: authorName,
        content: content,
        createdAt: createdAt,
      );
}
