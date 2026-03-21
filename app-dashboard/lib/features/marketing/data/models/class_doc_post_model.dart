import '../../domain/entities/class_doc_post_entity.dart';

class ClassDocPostModel extends ClassDocPostEntity {
  const ClassDocPostModel({
    required super.id,
    required super.batchName,
    required super.moduleName,
    required super.status,
    required super.postUrl,
    required super.classDate,
    required super.scheduledPostDate,
    required super.createdAt,
  });

  factory ClassDocPostModel.fromJson(Map<String, dynamic> json) =>
      ClassDocPostModel(
        id: json['id'] as String? ?? '',
        batchName: json['batch_name'] as String? ?? '',
        moduleName: json['module_name'] as String? ?? '',
        status: json['status'] as String? ?? 'scheduled',
        postUrl: json['post_url'] as String? ?? '',
        classDate:
            DateTime.tryParse(json['class_date'] as String? ?? '') ??
                DateTime.now(),
        scheduledPostDate:
            DateTime.tryParse(json['scheduled_post_date'] as String? ?? '') ??
                DateTime.now(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  ClassDocPostEntity toEntity() => ClassDocPostEntity(
        id: id,
        batchName: batchName,
        moduleName: moduleName,
        status: status,
        postUrl: postUrl,
        classDate: classDate,
        scheduledPostDate: scheduledPostDate,
        createdAt: createdAt,
      );
}
