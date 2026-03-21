import 'package:equatable/equatable.dart';

class CharacterTestConfigEntity extends Equatable {
  final String id;
  final String courseVersionId;
  final String testType; // MBTI | DISC | custom
  final String testProvider;
  final double passingThreshold;
  final bool talentpoolEligible;

  const CharacterTestConfigEntity({
    required this.id,
    required this.courseVersionId,
    required this.testType,
    required this.testProvider,
    required this.passingThreshold,
    required this.talentpoolEligible,
  });

  bool get isEmpty => id.isEmpty;

  String get testTypeLabel => switch (testType.toUpperCase()) {
        'DISC' => 'DISC Assessment',
        'MBTI' => 'MBTI Test',
        _ => 'Custom Test',
      };

  @override
  List<Object?> get props => [id, courseVersionId];
}
