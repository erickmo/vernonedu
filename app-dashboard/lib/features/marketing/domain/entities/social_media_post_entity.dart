import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SocialMediaPostEntity extends Equatable {
  final String id;
  final String contentType;
  final String caption;
  final String mediaUrl;
  final String batchId;
  final String batchName;
  final String status;
  final String postUrl;
  final List<String> platforms;
  final DateTime scheduledAt;
  final DateTime createdAt;

  const SocialMediaPostEntity({
    required this.id,
    required this.contentType,
    required this.caption,
    required this.mediaUrl,
    required this.batchId,
    required this.batchName,
    required this.status,
    required this.postUrl,
    required this.platforms,
    required this.scheduledAt,
    required this.createdAt,
  });

  String get statusLabel => switch (status) {
        'scheduled' => 'Dijadwalkan',
        'posted' => 'Diposting',
        _ => 'Draft',
      };

  String get contentTypeLabel => switch (contentType) {
        'promo' => 'Promosi Course',
        'dokumentasi' => 'Dokumentasi Kelas',
        'event' => 'Event',
        _ => 'Info Umum',
      };

  Color get statusColor => switch (status) {
        'scheduled' => AppColors.info,
        'posted' => AppColors.success,
        _ => AppColors.textSecondary,
      };

  String get platformsDisplay => platforms.join(', ');

  @override
  List<Object?> get props => [id, status, platforms, scheduledAt];
}
