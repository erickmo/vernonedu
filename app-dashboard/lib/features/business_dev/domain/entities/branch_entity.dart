import 'package:equatable/equatable.dart';

class BranchEntity extends Equatable {
  final String id;
  final String name;
  final String city;
  final String address;
  final String partnerName;
  final bool isActive;

  const BranchEntity({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.partnerName,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id];
}
