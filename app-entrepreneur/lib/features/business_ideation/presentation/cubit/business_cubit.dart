import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_business_usecase.dart';
import '../../domain/usecases/delete_business_usecase.dart';
import '../../domain/usecases/get_business_by_id_usecase.dart';
import '../../domain/usecases/get_businesses_usecase.dart';
import '../../domain/usecases/update_business_usecase.dart';
import 'business_state.dart';

class BusinessCubit extends Cubit<BusinessState> {
  final GetBusinessesUseCase getBusinessesUseCase;
  final GetBusinessByIdUseCase getBusinessByIdUseCase;
  final CreateBusinessUseCase createBusinessUseCase;
  final UpdateBusinessUseCase updateBusinessUseCase;
  final DeleteBusinessUseCase deleteBusinessUseCase;

  BusinessCubit({
    required this.getBusinessesUseCase,
    required this.getBusinessByIdUseCase,
    required this.createBusinessUseCase,
    required this.updateBusinessUseCase,
    required this.deleteBusinessUseCase,
  }) : super(BusinessInitial());

  Future<void> getBusinesses() async {
    emit(BusinessLoading());
    final result = await getBusinessesUseCase();
    result.fold(
      (failure) => emit(BusinessError(failure.message)),
      (businesses) => emit(BusinessLoaded(businesses)),
    );
  }

  Future<void> createBusiness({required String name}) async {
    final result = await createBusinessUseCase(name: name);
    result.fold(
      (failure) => emit(BusinessError(failure.message)),
      (_) => getBusinesses(),
    );
  }

  Future<void> getBusinessById({required String id}) async {
    emit(BusinessLoading());
    final result = await getBusinessByIdUseCase(id: id);
    result.fold(
      (failure) => emit(BusinessError(failure.message)),
      (business) => emit(BusinessDetailLoaded(business)),
    );
  }

  Future<void> updateBusiness({
    required String id,
    required String name,
  }) async {
    final result = await updateBusinessUseCase(id: id, name: name);
    result.fold(
      (failure) => emit(BusinessError(failure.message)),
      (_) => getBusinesses(),
    );
  }

  Future<void> deleteBusiness({required String id}) async {
    final result = await deleteBusinessUseCase(id: id);
    result.fold(
      (failure) => emit(BusinessError(failure.message)),
      (_) => getBusinesses(),
    );
  }
}
