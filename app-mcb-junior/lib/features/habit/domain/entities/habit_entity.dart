import 'package:equatable/equatable.dart';

/// Frekuensi kebiasaan.
enum HabitFrequency { daily, weekdays, weekends, custom }

/// Entity kebiasaan anak.
class HabitEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final HabitFrequency frequency;
  final List<int> targetDays; // 0=Senin, 6=Minggu
  final int streakCount;
  final int longestStreak;
  final int pointsPerCheck;
  final List<DateTime> checkIns;
  final bool isCheckedToday;
  final DateTime createdAt;

  const HabitEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.frequency,
    required this.targetDays,
    required this.streakCount,
    required this.longestStreak,
    required this.pointsPerCheck,
    required this.checkIns,
    required this.isCheckedToday,
    required this.createdAt,
  });

  @override
  List<Object> get props => [
        id,
        title,
        description,
        iconEmoji,
        frequency,
        targetDays,
        streakCount,
        longestStreak,
        pointsPerCheck,
        checkIns,
        isCheckedToday,
        createdAt,
      ];
}
