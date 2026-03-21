import '../../domain/entities/pr_schedule_entity.dart';

class PrScheduleModel extends PrScheduleEntity {
  const PrScheduleModel({
    required super.id,
    required super.title,
    required super.type,
    required super.mediaVenue,
    required super.picName,
    required super.status,
    required super.notes,
    required super.scheduledAt,
    required super.createdAt,
  });

  factory PrScheduleModel.fromJson(Map<String, dynamic> json) =>
      PrScheduleModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: json['type'] as String? ?? 'event',
        mediaVenue: json['media_venue'] as String? ?? '',
        picName: json['pic_name'] as String? ?? '',
        status: json['status'] as String? ?? 'scheduled',
        notes: json['notes'] as String? ?? '',
        scheduledAt: json['scheduled_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (json['scheduled_at'] as int) * 1000)
            : DateTime.now(),
        createdAt: json['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (json['created_at'] as int) * 1000)
            : DateTime.now(),
      );

  PrScheduleEntity toEntity() => PrScheduleEntity(
        id: id,
        title: title,
        type: type,
        mediaVenue: mediaVenue,
        picName: picName,
        status: status,
        notes: notes,
        scheduledAt: scheduledAt,
        createdAt: createdAt,
      );
}
