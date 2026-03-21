import 'package:equatable/equatable.dart';

class PartnerCompanyEntity extends Equatable {
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

  const PartnerCompanyEntity({
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

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id];
}
