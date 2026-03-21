import '../../domain/entities/cms_faq_entity.dart';

class CmsFaqModel extends CmsFaqEntity {
  const CmsFaqModel({
    required super.id,
    required super.question,
    required super.answer,
    required super.category,
    required super.pageSlugs,
    required super.sortOrder,
    required super.createdAt,
  });

  factory CmsFaqModel.fromJson(Map<String, dynamic> json) => CmsFaqModel(
        id: json['id'] as String? ?? '',
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        category: json['category'] as String? ?? 'umum',
        pageSlugs: (json['page_slugs'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  CmsFaqEntity toEntity() => CmsFaqEntity(
        id: id,
        question: question,
        answer: answer,
        category: category,
        pageSlugs: pageSlugs,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}
