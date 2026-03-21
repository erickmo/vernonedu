import 'package:equatable/equatable.dart';

/// Status quest.
enum QuestStatus { active, completed, failed, locked }

/// Kategori quest.
enum QuestCategory {
  daily,
  academic,
  social,
  health,
  creativity,
  responsibility,
}

/// Entity misi/quest untuk anak.
class QuestEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final QuestCategory category;
  final QuestStatus status;
  final int pointsReward;
  final int xpReward;
  final int durationMinutes;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String iconEmoji;
  final List<String> steps;

  const QuestEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.pointsReward,
    required this.xpReward,
    required this.durationMinutes,
    this.dueDate,
    this.completedAt,
    required this.iconEmoji,
    required this.steps,
  });

  bool get isCompleted => status == QuestStatus.completed;
  bool get isActive => status == QuestStatus.active;
  bool get isFailed => status == QuestStatus.failed;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        status,
        pointsReward,
        xpReward,
        durationMinutes,
        dueDate,
        completedAt,
        iconEmoji,
        steps,
      ];
}
