import '../../domain/entities/delegation_entity.dart';

class DelegationModel {
  final String id;
  final String title;
  final String type;
  final String description;
  final String assignedToName;
  final String assignedByName;
  final String priority;
  final String? deadline;
  final String status;

  const DelegationModel({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.assignedToName,
    required this.assignedByName,
    required this.priority,
    this.deadline,
    required this.status,
  });

  factory DelegationModel.fromJson(Map<String, dynamic> json) {
    return DelegationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'delegate_task',
      description: json['description']?.toString() ?? '',
      assignedToName: json['assigned_to_name']?.toString() ?? '',
      assignedByName: json['assigned_by_name']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      deadline: json['deadline']?.toString(),
      status: json['status']?.toString() ?? 'pending',
    );
  }

  DelegationEntity toEntity() {
    return DelegationEntity(
      id: id,
      title: title,
      type: type,
      description: description,
      assignedToName: assignedToName,
      assignedByName: assignedByName,
      priority: priority,
      deadline: deadline,
      status: status,
    );
  }
}

class DelegationStatsModel {
  final int activeCount;
  final int pendingCount;
  final int inProgressCount;
  final int completedThisMonthCount;

  const DelegationStatsModel({
    required this.activeCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedThisMonthCount,
  });

  factory DelegationStatsModel.fromJson(Map<String, dynamic> json) {
    return DelegationStatsModel(
      activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      inProgressCount: (json['in_progress_count'] as num?)?.toInt() ?? 0,
      completedThisMonthCount:
          (json['completed_this_month_count'] as num?)?.toInt() ?? 0,
    );
  }

  DelegationStatsEntity toEntity() {
    return DelegationStatsEntity(
      activeCount: activeCount,
      pendingCount: pendingCount,
      inProgressCount: inProgressCount,
      completedThisMonthCount: completedThisMonthCount,
    );
  }
}
