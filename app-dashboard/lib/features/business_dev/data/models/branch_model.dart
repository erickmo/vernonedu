import '../../domain/entities/branch_entity.dart';

class BranchModel {
  final String id;
  final String name;
  final String city;
  final String address;
  final String partnerName;
  final bool isActive;

  const BranchModel({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.partnerName,
    required this.isActive,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      partnerName: json['partner_name']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  BranchEntity toEntity() {
    return BranchEntity(
      id: id,
      name: name,
      city: city,
      address: address,
      partnerName: partnerName,
      isActive: isActive,
    );
  }
}
