import 'package:equatable/equatable.dart';

class ReferralEntity extends Equatable {
  final String id;
  final String partnerName;
  final String status;
  final double commission;
  final DateTime createdAt;

  const ReferralEntity({
    required this.id,
    required this.partnerName,
    required this.status,
    required this.commission,
    required this.createdAt,
  });

  String get statusLabel => switch (status) {
        'pending' => 'Pending',
        'enrolled' => 'Enrolled',
        _ => 'Dibayar',
      };

  @override
  List<Object?> get props => [id, status];
}
