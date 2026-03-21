import 'package:equatable/equatable.dart';

class StudentNoteEntity extends Equatable {
  final String id;
  final String studentId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const StudentNoteEntity({
    required this.id,
    required this.studentId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  String get authorInitials {
    final parts = authorName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id];
}
