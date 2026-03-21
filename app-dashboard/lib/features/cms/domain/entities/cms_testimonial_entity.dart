import 'package:equatable/equatable.dart';

class CmsTestimonialEntity extends Equatable {
  final String id;
  final String studentName;
  final String courseName;
  final String quote;
  final int rating;
  final String photo;
  final bool isFeatured;
  final DateTime createdAt;

  const CmsTestimonialEntity({
    required this.id,
    required this.studentName,
    required this.courseName,
    required this.quote,
    required this.rating,
    required this.photo,
    required this.isFeatured,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
