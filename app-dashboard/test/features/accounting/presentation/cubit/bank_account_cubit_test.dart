import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/entities/bank_account_entity.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/create_bank_account_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/delete_bank_account_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/list_bank_accounts_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/update_bank_account_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/presentation/cubit/bank_account_cubit.dart';

class _MockList extends Mock implements ListBankAccountsUseCase {}

class _MockCreate extends Mock implements CreateBankAccountUseCase {}

class _MockUpdate extends Mock implements UpdateBankAccountUseCase {}

class _MockDelete extends Mock implements DeleteBankAccountUseCase {}

const _entity = BankAccountEntity(
  id: '1',
  branchId: 'b',
  name: 'Kas',
  bankName: '',
  accountNumber: '',
  balanceCents: 0,
  currency: 'IDR',
  coaCode: '',
  isActive: true,
);

void main() {
  late _MockList listUc;
  late _MockCreate createUc;
  late _MockUpdate updateUc;
  late _MockDelete deleteUc;

  BankAccountCubit build() => BankAccountCubit(
        listUseCase: listUc,
        createUseCase: createUc,
        updateUseCase: updateUc,
        deleteUseCase: deleteUc,
      );

  setUp(() {
    listUc = _MockList();
    createUc = _MockCreate();
    updateUc = _MockUpdate();
    deleteUc = _MockDelete();
    registerFallbackValue(_entity);
  });

  blocTest<BankAccountCubit, BankAccountState>(
    'emits [Loading, Loaded] on successful load',
    build: () {
      when(() => listUc(includeInactive: any(named: 'includeInactive')))
          .thenAnswer((_) async => const Right([_entity]));
      return build();
    },
    act: (c) => c.load(),
    expect: () => [
      const BankAccountLoading(),
      const BankAccountLoaded([_entity]),
    ],
  );

  blocTest<BankAccountCubit, BankAccountState>(
    'emits [Loading, Error] on failed load',
    build: () {
      when(() => listUc(includeInactive: any(named: 'includeInactive')))
          .thenAnswer((_) async => const Left(ServerFailure('boom')));
      return build();
    },
    act: (c) => c.load(),
    expect: () => [
      const BankAccountLoading(),
      const BankAccountError('boom'),
    ],
  );
}
