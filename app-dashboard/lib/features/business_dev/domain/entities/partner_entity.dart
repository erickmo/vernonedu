import 'package:equatable/equatable.dart';

class PartnerEntity extends Equatable {
  final String id;
  final String name;
  final String industry;
  final String groupName;
  final String status;
  final String partnerSince;
  final String contactEmail;
  final String contactPhone;
  final String contactPerson;
  final String website;
  final String address;
  final String notes;
  final String logoUrl;

  const PartnerEntity({
    required this.id,
    required this.name,
    required this.industry,
    required this.groupName,
    required this.status,
    required this.partnerSince,
    required this.contactEmail,
    required this.contactPhone,
    required this.contactPerson,
    required this.website,
    required this.address,
    required this.notes,
    required this.logoUrl,
  });

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'negotiating':
        return 'Negosiasi';
      case 'contacted':
        return 'Dihubungi';
      case 'inactive':
        return 'Tidak Aktif';
      default:
        return 'Prospek';
    }
  }

  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  List<Object?> get props => [id];
}
