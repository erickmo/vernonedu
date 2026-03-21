import 'package:equatable/equatable.dart';

class DelegationEntity extends Equatable {
  final String id;
  final String title;
  final String type;
  final String description;
  final String assignedToName;
  final String assignedByName;
  final String priority;
  final String? deadline;
  final String status;

  const DelegationEntity({
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

  String get typeLabel {
    switch (type) {
      case 'request_course':
        return 'Request Course';
      case 'request_project':
        return 'Request Project';
      default:
        return 'Delegate Task';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'accepted':
        return 'Diterima';
      case 'in_progress':
        return 'Dikerjakan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [id];
}

class DelegationStatsEntity extends Equatable {
  final int activeCount;
  final int pendingCount;
  final int inProgressCount;
  final int completedThisMonthCount;

  const DelegationStatsEntity({
    required this.activeCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedThisMonthCount,
  });

  @override
  List<Object?> get props => [activeCount];
}
