import '../../domain/entities/talentpool_entity.dart';

// Model data layer untuk TalentPool — bertanggung jawab parsing JSON dari API
class TalentPoolModel {
  final String id;
  final String participantId;
  final String participantName;
  final String participantEmail;
  final String masterCourseId;
  final String courseName;
  final double? testScore;
  final String talentpoolStatus;
  final DateTime joinedAt;
  final Map<String, dynamic> characterTestResult;
  final List<Map<String, dynamic>> placementHistory;

  const TalentPoolModel({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantEmail,
    required this.masterCourseId,
    required this.courseName,
    this.testScore,
    required this.talentpoolStatus,
    required this.joinedAt,
    required this.characterTestResult,
    required this.placementHistory,
  });

  factory TalentPoolModel.fromJson(Map<String, dynamic> json) {
    // Parse characterTestResult
    final rawTest = json['character_test_result'];
    final testResult = rawTest is Map
        ? Map<String, dynamic>.from(rawTest)
        : <String, dynamic>{};

    // Parse placementHistory
    final rawHistory = json['placement_history'];
    final history = rawHistory is List
        ? rawHistory
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    return TalentPoolModel(
      id: json['id'] as String? ?? '',
      participantId: json['participant_id'] as String? ?? '',
      participantName: json['participant_name'] as String? ?? '',
      participantEmail: json['participant_email'] as String? ?? '',
      masterCourseId: json['master_course_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      testScore: (json['test_score'] as num?)?.toDouble(),
      talentpoolStatus: json['talentpool_status'] as String? ?? 'active',
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ?? DateTime.now(),
      characterTestResult: testResult,
      placementHistory: history,
    );
  }

  // Konversi ke domain entity
  TalentPoolEntity toEntity() => TalentPoolEntity(
        id: id,
        participantId: participantId,
        participantName: participantName,
        participantEmail: participantEmail,
        masterCourseId: masterCourseId,
        courseName: courseName,
        testScore: testScore,
        talentpoolStatus: talentpoolStatus,
        joinedAt: joinedAt,
        characterTestResult: characterTestResult,
        placementHistory: placementHistory,
      );
}
