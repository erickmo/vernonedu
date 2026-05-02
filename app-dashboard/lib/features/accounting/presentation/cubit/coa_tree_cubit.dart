import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/coa_tree_node_entity.dart';
import '../../domain/usecases/get_coa_tree_usecase.dart';

part 'coa_tree_state.dart';

/// Cubit managing the COA Tree page.
///
/// Strictly dispatches the usecase and emits state — no business logic.
class CoaTreeCubit extends Cubit<CoaTreeState> {
  final GetCoaTreeUseCase getCoaTreeUseCase;

  CoaTreeCubit({required this.getCoaTreeUseCase})
      : super(const CoaTreeInitial());

  Future<void> load() async {
    emit(const CoaTreeLoading());
    final result = await getCoaTreeUseCase();
    result.fold(
      (failure) => emit(CoaTreeError(failure.message)),
      (roots) => emit(CoaTreeLoaded(roots)),
    );
  }
}
