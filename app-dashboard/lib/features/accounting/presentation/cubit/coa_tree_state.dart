part of 'coa_tree_cubit.dart';

abstract class CoaTreeState extends Equatable {
  const CoaTreeState();

  @override
  List<Object?> get props => [];
}

class CoaTreeInitial extends CoaTreeState {
  const CoaTreeInitial();
}

class CoaTreeLoading extends CoaTreeState {
  const CoaTreeLoading();
}

class CoaTreeLoaded extends CoaTreeState {
  final List<CoaTreeNodeEntity> roots;
  const CoaTreeLoaded(this.roots);

  @override
  List<Object?> get props => [roots];
}

class CoaTreeError extends CoaTreeState {
  final String message;
  const CoaTreeError(this.message);

  @override
  List<Object?> get props => [message];
}
