import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/mou_entity.dart';
import '../../domain/entities/partnership_log_entity.dart';
import 'mou_model.dart';
import 'partnership_log_model.dart';

class PartnerDetailModel {
  final String id;
  final String name;
  final String industry;
  final String address;
  final String contactPerson;
  final String contactEmail;
  final String contactPhone;
  final String website;
  final String logoUrl;
  final String groupName;
  final String status;
  final String partnerSince;
  final String notes;
  final List<MouModel> mous;
  final List<PartnershipLogModel> logs;

  const PartnerDetailModel({
    required this.id,
    required this.name,
    required this.industry,
    required this.address,
    required this.contactPerson,
    required this.contactEmail,
    required this.contactPhone,
    required this.website,
    required this.logoUrl,
    required this.groupName,
    required this.status,
    required this.partnerSince,
    required this.notes,
    required this.mous,
    required this.logs,
  });

  factory PartnerDetailModel.fromJson(Map<String, dynamic> json) {
    final mouList = json['mous'] as List? ?? [];
    final logList = json['logs'] as List? ?? [];
    return PartnerDetailModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      industry: json['industry']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      contactPerson: json['contact_person']?.toString() ?? '',
      contactEmail: json['contact_email']?.toString() ?? '',
      contactPhone: json['contact_phone']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? '',
      groupName: json['group_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'prospect',
      partnerSince: json['partner_since']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      mous: mouList
          .map((e) => MouModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      logs: logList
          .map((e) => PartnershipLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  PartnerEntity toPartnerEntity() {
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

  List<MouEntity> toMouEntities() =>
      mous.map((m) => m.toEntity()).toList();

  List<PartnershipLogEntity> toLogEntities() =>
      logs.map((l) => l.toEntity()).toList();
}
