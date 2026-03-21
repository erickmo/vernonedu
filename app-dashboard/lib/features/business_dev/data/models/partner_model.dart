import '../../domain/entities/partner_entity.dart';

class PartnerModel {
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

  const PartnerModel({
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

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      industry: json['industry']?.toString() ?? '',
      groupName: json['group_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'prospect',
      partnerSince: json['partner_since']?.toString() ?? '',
      contactEmail: json['contact_email']?.toString() ?? '',
      contactPhone: json['contact_phone']?.toString() ?? '',
      contactPerson: json['contact_person']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? '',
    );
  }

  PartnerEntity toEntity() {
    return PartnerEntity(
      id: id,
      name: name,
      industry: industry,
      groupName: groupName,
      status: status,
      partnerSince: partnerSince,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactPerson: contactPerson,
      website: website,
      address: address,
      notes: notes,
      logoUrl: logoUrl,
    );
  }
}
