import '../../domain/entities/partner_company_entity.dart';

class PartnerCompanyModel {
  final String id;
  final String name;
  final String industry;
  final String location;
  final String? website;
  final String? contactEmail;
  final String? contactPhone;
  final String? description;
  final String? logoUrl;
  final DateTime partnerSince;
  final bool isActive;
  final int totalHired;
  final int activeJobCount;

  const PartnerCompanyModel({
    required this.id,
    required this.name,
    required this.industry,
    required this.location,
    this.website,
    this.contactEmail,
    this.contactPhone,
    this.description,
    this.logoUrl,
    required this.partnerSince,
    required this.isActive,
    required this.totalHired,
    required this.activeJobCount,
  });

  factory PartnerCompanyModel.fromJson(Map<String, dynamic> json) {
    return PartnerCompanyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      industry: json['industry']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      website: json['website']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      description: json['description']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      partnerSince: json['partner_since'] != null
          ? DateTime.tryParse(json['partner_since'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      totalHired: _parseInt(json['total_hired']),
      activeJobCount: _parseInt(json['active_job_count']),
    );
  }

  PartnerCompanyEntity toEntity() => PartnerCompanyEntity(
        id: id,
        name: name,
        industry: industry,
        location: location,
        website: website,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        description: description,
        logoUrl: logoUrl,
        partnerSince: partnerSince,
        isActive: isActive,
        totalHired: totalHired,
        activeJobCount: activeJobCount,
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
