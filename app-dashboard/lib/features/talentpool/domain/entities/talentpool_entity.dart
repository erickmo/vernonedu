import 'package:equatable/equatable.dart';

// Entity domain untuk TalentPool — peserta yang masuk talent pool VernonEdu
class TalentPoolEntity extends Equatable {
  final String id;
  final String participantId;
  final String participantName;
  final String participantEmail;
  final String masterCourseId;

  // Nama course yang di-denormalize dari master course
  final String courseName;

  final double? testScore;

  // Status: active | placed | inactive
  final String talentpoolStatus;

  final DateTime joinedAt;

  // Hasil character test — fleksibel sesuai format API
  final Map<String, dynamic> characterTestResult;

  // Riwayat penempatan kerja
  final List<Map<String, dynamic>> placementHistory;

  const TalentPoolEntity({
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

  bool get isActive => talentpoolStatus == 'active';
  bool get isPlaced => talentpoolStatus == 'placed';
  bool get isInactive => talentpoolStatus == 'inactive';

  // Label status yang ditampilkan ke user
  String get statusLabel => switch (talentpoolStatus) {
        'active' => 'Aktif',
        'placed' => 'Ditempatkan',
        'inactive' => 'Nonaktif',
        _ => talentpoolStatus,
      };

  @override
  List<Object?> get props => [id];
}
