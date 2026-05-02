import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/entities/coa_tree_node_entity.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/get_coa_tree_usecase.dart';

class _MockRepo extends Mock implements AccountingRepository {}

void main() {
  test('GetCoaTreeUseCase delegates to repository', () async {
    final repo = _MockRepo();
    const node = CoaTreeNodeEntity(
      id: '1',
      code: '1',
      name: 'Aset',
      accountType: 'asset',
      parentCode: '',
      isActive: true,
    );
    when(() => repo.getCoaTree())
        .thenAnswer((_) async => const Right([node]));

    final result = await GetCoaTreeUseCase(repo)();

    expect(result.isRight(), true);
    verify(() => repo.getCoaTree()).called(1);
  });
}
