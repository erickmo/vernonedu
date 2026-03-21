import 'package:equatable/equatable.dart';

class OkrObjectiveEntity extends Equatable {
  final String id;
  final String title;
  final String ownerName;
  final String period;
  final String level;
  final String status;
  final int progress;
  final List<OkrKeyResultEntity> keyResults;

  const OkrObjectiveEntity({
    required this.id,
    required this.title,
    required this.ownerName,
    required this.period,
    required this.level,
    required this.status,
    required this.progress,
    required this.keyResults,
  });

  String get statusLabel {
    switch (status) {
      case 'on_track':
        return 'On Track';
      case 'at_risk':
        return 'At Risk';
      case 'behind':
        return 'Behind';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [id];
}

class OkrKeyResultEntity extends Equatable {
  final String id;
  final String title;
  final int progress;

  const OkrKeyResultEntity({
    required this.id,
    required this.title,
    required this.progress,
  });

  @override
  List<Object?> get props => [id];
}
