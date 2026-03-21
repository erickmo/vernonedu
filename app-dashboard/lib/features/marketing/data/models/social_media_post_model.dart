import '../../domain/entities/social_media_post_entity.dart';

class SocialMediaPostModel extends SocialMediaPostEntity {
  const SocialMediaPostModel({
    required super.id,
    required super.contentType,
    required super.caption,
    required super.mediaUrl,
    required super.batchId,
    required super.batchName,
    required super.status,
    required super.postUrl,
    required super.platforms,
    required super.scheduledAt,
    required super.createdAt,
  });

  factory SocialMediaPostModel.fromJson(Map<String, dynamic> json) =>
      SocialMediaPostModel(
        id: json['id'] as String? ?? '',
        platforms: (json['platforms'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        scheduledAt: json['scheduled_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (json['scheduled_at'] as int) * 1000)
            : DateTime.now(),
        contentType: json['content_type'] as String? ?? 'info',
        caption: json['caption'] as String? ?? '',
        mediaUrl: json['media_url'] as String? ?? '',
        batchId: json['batch_id'] as String? ?? '',
        batchName: json['batch_name'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        postUrl: json['post_url'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (json['created_at'] as int) * 1000)
            : DateTime.now(),
      );

  SocialMediaPostEntity toEntity() => SocialMediaPostEntity(
        id: id,
        contentType: contentType,
        caption: caption,
        mediaUrl: mediaUrl,
        batchId: batchId,
        batchName: batchName,
        status: status,
        postUrl: postUrl,
        platforms: platforms,
        scheduledAt: scheduledAt,
        createdAt: createdAt,
      );
}
