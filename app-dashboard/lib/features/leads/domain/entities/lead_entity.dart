import 'package:equatable/equatable.dart';

class LeadEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String interest;
  final String source;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LeadEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.interest,
    required this.source,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusLabel => switch (status) {
        'new' => 'Baru',
        'contacted' => 'Dihubungi',
        'interested' => 'Tertarik',
        'negotiating' => 'Negosiasi',
        'enrolled' => 'Enrolled',
        'not_interested' => 'Tidak Tertarik',
        _ => status,
      };

  String get sourceLabel => switch (source) {
        'referral' => 'Referral',
        'social_media' => 'Media Sosial',
        'walk_in' => 'Walk In',
        'website' => 'Website',
        _ => 'Lainnya',
      };

  @override
  List<Object?> get props => [id];
}
