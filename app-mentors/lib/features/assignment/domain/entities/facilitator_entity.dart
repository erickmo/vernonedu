import 'package:equatable/equatable.dart';

class FacilitatorEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? departmentName;
  final int activeBatchCount;
  final String? photoUrl;

  const FacilitatorEntity({
    required this.id,
    required this.name,
    required this.email,
    this.departmentName,
    required this.activeBatchCount,
    this.photoUrl,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id];
}
