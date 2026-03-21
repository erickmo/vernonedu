import '../../domain/entities/okr_entity.dart';

class OkrKeyResultModel {
  final String id;
  final String title;
  final int progress;

  const OkrKeyResultModel({
    required this.id,
    required this.title,
    required this.progress,
  });

  factory OkrKeyResultModel.fromJson(Map<String, dynamic> json) {
    return OkrKeyResultModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
    );
  }

  OkrKeyResultEntity toEntity() {
    return OkrKeyResultEntity(id: id, title: title, progress: progress);
  }
}

class OkrObjectiveModel {
  final String id;
  final String title;
  final String ownerName;
  final String period;
  final String level;
  final String status;
  final int progress;
  final List<OkrKeyResultModel> keyResults;

  const OkrObjectiveModel({
    required this.id,
    required this.title,
    required this.ownerName,
    required this.period,
    required this.level,
    required this.status,
    required this.progress,
    required this.keyResults,
  });

  factory OkrObjectiveModel.fromJson(Map<String, dynamic> json) {
    final krList = json['key_results'] as List? ?? [];
    return OkrObjectiveModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      ownerName: json['owner_name']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
      level: json['level']?.toString() ?? 'company',
      status: json['status']?.toString() ?? 'on_track',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      keyResults: krList
          .map((e) => OkrKeyResultModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  OkrObjectiveEntity toEntity() {
    return OkrObjectiveEntity(
      id: id,
      title: title,
      ownerName: ownerName,
      period: period,
      level: level,
      status: status,
      progress: progress,
      keyResults: keyResults.map((kr) => kr.toEntity()).toList(),
    );
  }
}
