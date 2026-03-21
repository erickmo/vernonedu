import 'package:equatable/equatable.dart';

/// Entity anak yang sedang login.
class ChildEntity extends Equatable {
  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final int totalPoints;
  final int streakDays;
  final DateTime createdAt;

  const ChildEntity({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.totalPoints,
    required this.streakDays,
    required this.createdAt,
  });

  /// Progress XP ke level berikutnya (0.0 - 1.0).
  double get xpProgress =>
      xpToNextLevel > 0 ? (currentXp / xpToNextLevel).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object> get props => [
        id,
        name,
        username,
        avatarUrl,
        level,
        currentXp,
        xpToNextLevel,
        totalPoints,
        streakDays,
        createdAt,
      ];
}
