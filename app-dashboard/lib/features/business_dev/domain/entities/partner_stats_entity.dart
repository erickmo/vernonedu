import 'package:equatable/equatable.dart';

class PartnerStatsEntity extends Equatable {
  final int activeCount;
  final int expiringCount;
  final int negotiatingCount;
  final int uncontactedCount;

  const PartnerStatsEntity({
    required this.activeCount,
    required this.expiringCount,
    required this.negotiatingCount,
    required this.uncontactedCount,
  });

  @override
  List<Object?> get props => [
        activeCount,
        expiringCount,
        negotiatingCount,
        uncontactedCount,
      ];
}
