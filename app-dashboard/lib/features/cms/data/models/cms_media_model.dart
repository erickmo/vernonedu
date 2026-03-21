import '../../domain/entities/cms_media_entity.dart';

class CmsMediaModel extends CmsMediaEntity {
  const CmsMediaModel({
    required super.id,
    required super.name,
    required super.url,
    required super.type,
    required super.size,
    required super.uploadedAt,
  });

  factory CmsMediaModel.fromJson(Map<String, dynamic> json) => CmsMediaModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        type: json['type'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        uploadedAt: json['uploaded_at'] != null
            ? DateTime.tryParse(json['uploaded_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  CmsMediaEntity toEntity() => CmsMediaEntity(
        id: id,
        name: name,
        url: url,
        type: type,
        size: size,
        uploadedAt: uploadedAt,
      );
}
