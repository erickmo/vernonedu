import '../../domain/entities/character_test_config_entity.dart';

class CharacterTestConfigModel {
  final String id;
  final String courseVersionId;
  final String testType;
  final String testProvider;
  final double passingThreshold;
  final bool talentpoolEligible;
  final int createdAt;
  final int updatedAt;

  const CharacterTestConfigModel({
    required this.id,
    required this.courseVersionId,
    required this.testType,
    required this.testProvider,
    required this.passingThreshold,
    required this.talentpoolEligible,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CharacterTestConfigModel.fromJson(Map<String, dynamic> json) {
    return CharacterTestConfigModel(
      id: json['id'] as String? ?? '',
      courseVersionId: json['course_version_id'] as String? ?? '',
      testType: json['test_type'] as String? ?? 'DISC',
      testProvider: json['test_provider'] as String? ?? '',
      passingThreshold: (json['passing_threshold'] as num?)?.toDouble() ?? 70.0,
      talentpoolEligible: json['talentpool_eligible'] as bool? ?? true,
      createdAt: json['created_at'] as int? ?? 0,
      updatedAt: json['updated_at'] as int? ?? 0,
    );
  }

  CharacterTestConfigEntity toEntity() => CharacterTestConfigEntity(
        id: id,
        courseVersionId: courseVersionId,
        testType: testType,
        testProvider: testProvider,
        passingThreshold: passingThreshold,
        talentpoolEligible: talentpoolEligible,
      );
}
