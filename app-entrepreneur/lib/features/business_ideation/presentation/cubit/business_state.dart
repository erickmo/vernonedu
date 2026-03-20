import '../../domain/entities/business_entity.dart';

abstract class BusinessState {}

class BusinessInitial extends BusinessState {}

class BusinessLoading extends BusinessState {}

class BusinessLoaded extends BusinessState {
  final List<BusinessEntity> businesses;

  BusinessLoaded(this.businesses);
}

class BusinessDetailLoaded extends BusinessState {
  final BusinessEntity business;

  BusinessDetailLoaded(this.business);
}

class BusinessError extends BusinessState {
  final String message;

  BusinessError(this.message);
}
