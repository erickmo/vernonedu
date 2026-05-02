import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bank_account_entity.dart';
import '../../domain/usecases/create_bank_account_usecase.dart';
import '../../domain/usecases/delete_bank_account_usecase.dart';
import '../../domain/usecases/list_bank_accounts_usecase.dart';
import '../../domain/usecases/update_bank_account_usecase.dart';

part 'bank_account_state.dart';

/// Cubit managing the Bank Accounts list page.
///
/// Strictly dispatches usecases and emits state — no business logic.
class BankAccountCubit extends Cubit<BankAccountState> {
  final ListBankAccountsUseCase listUseCase;
  final CreateBankAccountUseCase createUseCase;
  final UpdateBankAccountUseCase updateUseCase;
  final DeleteBankAccountUseCase deleteUseCase;

  BankAccountCubit({
    required this.listUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(const BankAccountInitial());

  Future<void> load({bool includeInactive = true}) async {
    emit(const BankAccountLoading());
    final result = await listUseCase(includeInactive: includeInactive);
    result.fold(
      (failure) => emit(BankAccountError(failure.message)),
      (items) => emit(BankAccountLoaded(items)),
    );
  }

  Future<bool> create(BankAccountEntity account) async {
    final result = await createUseCase(account);
    return result.fold(
      (failure) {
        emit(BankAccountError(failure.message));
        return false;
      },
      (_) async {
        await load();
        return true;
      },
    );
  }

  Future<bool> update(BankAccountEntity account) async {
    final result = await updateUseCase(account);
    return result.fold(
      (failure) {
        emit(BankAccountError(failure.message));
        return false;
      },
      (_) async {
        await load();
        return true;
      },
    );
  }

  Future<bool> delete(String id) async {
    final result = await deleteUseCase(id);
    return result.fold(
      (failure) {
        emit(BankAccountError(failure.message));
        return false;
      },
      (_) async {
        await load();
        return true;
      },
    );
  }
}
