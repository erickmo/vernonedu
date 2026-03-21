import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ClassDocPostEntity extends Equatable {
  final String id;
  final String batchName;
  final String moduleName;
  final String status;
  final String postUrl;
  final DateTime classDate;
  final DateTime scheduledPostDate;
  final DateTime createdAt;

  const ClassDocPostEntity({
    required this.id,
    required this.batchName,
    required this.moduleName,
    required this.status,
    required this.postUrl,
    required this.classDate,
    required this.scheduledPostDate,
    required this.createdAt,
  });

  String get statusLabel => status == 'posted' ? 'Diposting' : 'Dijadwalkan';

  Color get statusColor =>
      status == 'posted' ? AppColors.success : AppColors.info;

  @override
  List<Object?> get props => [id, status];
}
