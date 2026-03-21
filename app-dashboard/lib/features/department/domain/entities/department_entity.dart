import 'package:equatable/equatable.dart';

class DepartmentEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final bool isActive;

  const DepartmentEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id];
}
