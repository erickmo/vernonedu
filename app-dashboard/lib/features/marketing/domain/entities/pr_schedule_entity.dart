import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PrScheduleEntity extends Equatable {
  final String id;
  final String title;
  final String type;
  final String mediaVenue;
  final String picName;
  final String status;
  final String notes;
  final DateTime scheduledAt;
  final DateTime createdAt;

  const PrScheduleEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.mediaVenue,
    required this.picName,
    required this.status,
    required this.notes,
    required this.scheduledAt,
    required this.createdAt,
  });

  String get typeLabel => switch (type) {
        'press_release' => 'Press Release',
        'event' => 'Event',
        'sponsorship' => 'Sponsorship',
        'interview' => 'Interview',
        _ => 'Lainnya',
      };

  String get statusLabel => switch (status) {
        'scheduled' => 'Dijadwalkan',
        'active' => 'Berjalan',
        _ => 'Selesai',
      };

  Color get statusColor => switch (status) {
        'scheduled' => AppColors.info,
        'active' => AppColors.warning,
        _ => AppColors.success,
      };

  @override
  List<Object?> get props => [id, status, type];
}
