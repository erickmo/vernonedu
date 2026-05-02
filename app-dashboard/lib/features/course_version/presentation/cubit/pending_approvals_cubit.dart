import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/approve_course_version_usecase.dart';
import '../../domain/usecases/get_pending_course_versions_usecase.dart';
import '../../domain/usecases/reject_course_version_usecase.dart';
import 'pending_approvals_state.dart';

// Cubit for the dept_leader pending-approvals queue page.
// Loads versions with approval_status = 'submitted' and lets the user approve/reject inline.
class PendingApprovalsCubit extends Cubit<PendingApprovalsState> {
  final GetPendingCourseVersionsUseCase getPendingUseCase;
  final ApproveCourseVersionUseCase approveUseCase;
  final RejectCourseVersionUseCase rejectUseCase;

  PendingApprovalsCubit({
    required this.getPendingUseCase,
    required this.approveUseCase,
    required this.rejectUseCase,
  }) : super(const PendingApprovalsInitial());

  Future<void> load() async {
    emit(const PendingApprovalsLoading());
    final result = await getPendingUseCase();
    result.fold(
      (failure) => emit(PendingApprovalsError(failure.message)),
      (versions) => emit(PendingApprovalsLoaded(versions)),
    );
  }

  // Approve then reload the queue. Returns true on success.
  Future<bool> approve(String versionId) async {
    final result = await approveUseCase(versionId);
    return result.fold(
      (failure) {
        emit(PendingApprovalsError(failure.message));
        return false;
      },
      (_) {
        load();
        return true;
      },
    );
  }

  // Reject with reason then reload the queue. Returns true on success.
  Future<bool> reject(String versionId, String reason) async {
    final result = await rejectUseCase(versionId, reason);
    return result.fold(
      (failure) {
        emit(PendingApprovalsError(failure.message));
        return false;
      },
      (_) {
        load();
        return true;
      },
    );
  }
}
