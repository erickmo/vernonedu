import 'package:equatable/equatable.dart';

class DepartmentTalentPoolEntity extends Equatable {
  final String id;
  final String participantId;
  final String participantName;
  final String participantEmail;
  final String status;
  final int joinedAt;
  final double? testScore;

  const DepartmentTalentPoolEntity({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantEmail,
    required this.status,
    required this.joinedAt,
    this.testScore,
  });

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'placed':
        return 'Ditempatkan';
      case 'inactive':
        return 'Nonaktif';
      default:
        return status;
    }
  }

  String get initials {
    final parts = participantName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [id];
}
