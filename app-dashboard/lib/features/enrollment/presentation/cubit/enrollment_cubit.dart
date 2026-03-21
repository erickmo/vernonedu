import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/enroll_student_usecase.dart';
import '../../domain/usecases/get_enrollment_summary_usecase.dart';
import '../../domain/usecases/get_enrollments_usecase.dart';
import '../../domain/usecases/update_enrollment_status_usecase.dart';
import '../../domain/usecases/update_enrollment_payment_status_usecase.dart';
import 'enrollment_state.dart';

class EnrollmentCubit extends Cubit<EnrollmentState> {
  final GetEnrollmentsUseCase getEnrollmentsUseCase;
  final GetEnrollmentSummaryUseCase getEnrollmentSummaryUseCase;
  final EnrollStudentUseCase enrollStudentUseCase;
  final UpdateEnrollmentStatusUseCase updateEnrollmentStatusUseCase;
  final UpdateEnrollmentPaymentStatusUseCase updateEnrollmentPaymentStatusUseCase;

  EnrollmentCubit({
    required this.getEnrollmentsUseCase,
    required this.getEnrollmentSummaryUseCase,
    required this.enrollStudentUseCase,
    required this.updateEnrollmentStatusUseCase,
    required this.updateEnrollmentPaymentStatusUseCase,
  }) : super(const EnrollmentInitial());

  Future<void> loadEnrollments() async {
    emit(const EnrollmentLoading());
    final result = await getEnrollmentsUseCase();
    result.fold(
      (failure) => emit(EnrollmentError(failure.message)),
      (enrollments) => emit(EnrollmentLoaded(enrollments)),
    );
  }

  Future<void> loadSummary() async {
    emit(const EnrollmentSummaryLoading());
    final result = await getEnrollmentSummaryUseCase();
    result.fold(
      (failure) => emit(EnrollmentError(failure.message)),
      (summaries) => emit(EnrollmentSummaryLoaded(summaries)),
    );
  }

  /// Returns true on success, false on failure (emits EnrollmentError on failure).
  Future<bool> enrollStudent(Map<String, dynamic> data) async {
    final result = await enrollStudentUseCase(data);
    return result.fold(
      (failure) {
        emit(EnrollmentError(failure.message));
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> updateStatus(String id, String status) async {
    final result = await updateEnrollmentStatusUseCase(id, status);
    return result.fold(
      (failure) {
        emit(EnrollmentError(failure.message));
        return false;
      },
      (_) {
        loadEnrollments();
        return true;
      },
    );
  }

  Future<bool> updatePaymentStatus(String id, String paymentStatus) async {
    final result = await updateEnrollmentPaymentStatusUseCase(id, paymentStatus);
    return result.fold(
      (failure) {
        emit(EnrollmentError(failure.message));
        return false;
      },
      (_) {
        loadEnrollments();
        return true;
      },
    );
  }
}
