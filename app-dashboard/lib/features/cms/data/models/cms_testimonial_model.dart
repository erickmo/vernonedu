import '../../domain/entities/cms_testimonial_entity.dart';

class CmsTestimonialModel extends CmsTestimonialEntity {
  const CmsTestimonialModel({
    required super.id,
    required super.studentName,
    required super.courseName,
    required super.quote,
    required super.rating,
    required super.photo,
    required super.isFeatured,
    required super.createdAt,
  });

  factory CmsTestimonialModel.fromJson(Map<String, dynamic> json) =>
      CmsTestimonialModel(
        id: json['id'] as String? ?? '',
        studentName: json['student_name'] as String? ?? '',
        courseName: json['course_name'] as String? ?? '',
        quote: json['quote'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 5,
        photo: json['photo'] as String? ?? '',
        isFeatured: json['is_featured'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  CmsTestimonialEntity toEntity() => CmsTestimonialEntity(
        id: id,
        studentName: studentName,
        courseName: courseName,
        quote: quote,
        rating: rating,
        photo: photo,
        isFeatured: isFeatured,
        createdAt: createdAt,
      );
}
