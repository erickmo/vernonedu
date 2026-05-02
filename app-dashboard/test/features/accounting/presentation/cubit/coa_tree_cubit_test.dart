import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/entities/coa_tree_node_entity.dart';
import 'package:vernonedu_dashboard/features/accounting/domain/usecases/get_coa_tree_usecase.dart';
import 'package:vernonedu_dashboard/features/accounting/presentation/cubit/coa_tree_cubit.dart';

class _MockGetCoaTree extends Mock implements GetCoaTreeUseCase {}

const _root = CoaTreeNodeEntity(
  id: '1',
  code: '1',
  name: 'Aset',
  accountType: 'asset',
  parentCode: '',
  isActive: true,
);

void main() {
  late _MockGetCoaTree getUc;

  CoaTreeCubit build() => CoaTreeCubit(getCoaTreeUseCase: getUc);

  setUp(() {
    getUc = _MockGetCoaTree();
  });

  blocTest<CoaTreeCubit, CoaTreeState>(
    'emits [Loading, Loaded] on successful load',
    build: () {
      when(() => getUc()).thenAnswer((_) async => const Right([_root]));
      return build();
    },
    act: (c) => c.load(),
    expect: () => [
      const CoaTreeLoading(),
      const CoaTreeLoaded([_root]),
    ],
  );

  blocTest<CoaTreeCubit, CoaTreeState>(
    'emits [Loading, Error] on failed load',
    build: () {
      when(() => getUc())
          .thenAnswer((_) async => const Left(ServerFailure('boom')));
      return build();
    },
    act: (c) => c.load(),
    expect: () => [
      const CoaTreeLoading(),
      const CoaTreeError('boom'),
    ],
  );
}
