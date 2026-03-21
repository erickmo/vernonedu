import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

// Batch
import '../../features/batch/data/datasources/batch_remote_datasource.dart';
import '../../features/batch/data/repositories/batch_repository_impl.dart';
import '../../features/batch/domain/repositories/batch_repository.dart';
import '../../features/batch/domain/usecases/assign_facilitator_usecase.dart';
import '../../features/batch/domain/usecases/get_batch_detail_usecase.dart';
import '../../features/batch/domain/usecases/get_my_batches_usecase.dart';
import '../../features/batch/presentation/cubit/batch_detail_cubit.dart';
import '../../features/batch/presentation/cubit/batch_list_cubit.dart';

// Attendance
import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/get_attendance_sessions_usecase.dart';
import '../../features/attendance/domain/usecases/submit_attendance_usecase.dart';
import '../../features/attendance/presentation/cubit/attendance_cubit.dart';

// Assignment
import '../../features/assignment/data/datasources/facilitator_remote_datasource.dart';
import '../../features/assignment/data/repositories/assignment_repository_impl.dart';
import '../../features/assignment/domain/repositories/assignment_repository.dart';
import '../../features/assignment/domain/usecases/get_facilitators_usecase.dart';
import '../../features/assignment/presentation/cubit/assignment_cubit.dart';

// Schedule
import '../../features/schedule/data/datasources/schedule_remote_datasource.dart';
import '../../features/schedule/data/repositories/schedule_repository_impl.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../features/schedule/domain/usecases/get_my_schedule_usecase.dart';
import '../../features/schedule/presentation/cubit/schedule_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<Connectivity>(Connectivity());

  // Core
  getIt.registerSingleton<NetworkInfo>(NetworkInfoImpl(getIt<Connectivity>()));
  getIt.registerSingleton<ApiClient>(ApiClient(getIt<SharedPreferences>()));

  // Auth
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remote: getIt<AuthRemoteDataSource>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );
  getIt.registerFactory(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerFactory(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerFactory(
      () => GetCurrentUserUseCase(getIt<AuthRepository>()));
  getIt.registerFactory(() => AuthCubit(
        loginUseCase: getIt<LoginUseCase>(),
        logoutUseCase: getIt<LogoutUseCase>(),
        getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      ));

  // Batch
  getIt.registerSingleton<BatchRemoteDataSource>(
    BatchRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<BatchRepository>(
    BatchRepositoryImpl(remote: getIt<BatchRemoteDataSource>()),
  );
  getIt.registerFactory(
      () => GetMyBatchesUseCase(getIt<BatchRepository>()));
  getIt.registerFactory(
      () => GetBatchDetailUseCase(getIt<BatchRepository>()));
  getIt.registerFactory(
      () => AssignFacilitatorUseCase(getIt<BatchRepository>()));
  getIt.registerFactory(() => BatchListCubit(
        getMyBatchesUseCase: getIt<GetMyBatchesUseCase>(),
      ));
  getIt.registerFactory(() => BatchDetailCubit(
        getBatchDetailUseCase: getIt<GetBatchDetailUseCase>(),
        assignFacilitatorUseCase: getIt<AssignFacilitatorUseCase>(),
      ));

  // Attendance
  getIt.registerSingleton<AttendanceRemoteDataSource>(
    AttendanceRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<AttendanceRepository>(
    AttendanceRepositoryImpl(remote: getIt<AttendanceRemoteDataSource>()),
  );
  getIt.registerFactory(
      () => GetAttendanceSessionsUseCase(getIt<AttendanceRepository>()));
  getIt.registerFactory(
      () => SubmitAttendanceUseCase(getIt<AttendanceRepository>()));
  getIt.registerFactory(() => AttendanceCubit(
        getSessionsUseCase: getIt<GetAttendanceSessionsUseCase>(),
        submitUseCase: getIt<SubmitAttendanceUseCase>(),
      ));

  // Assignment
  getIt.registerSingleton<FacilitatorRemoteDataSource>(
    FacilitatorRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<AssignmentRepository>(
    AssignmentRepositoryImpl(remote: getIt<FacilitatorRemoteDataSource>()),
  );
  getIt.registerFactory(
      () => GetFacilitatorsUseCase(getIt<AssignmentRepository>()));
  getIt.registerFactory(() => AssignmentCubit(
        getFacilitatorsUseCase: getIt<GetFacilitatorsUseCase>(),
      ));

  // Schedule
  getIt.registerSingleton<ScheduleRemoteDataSource>(
    ScheduleRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<ScheduleRepository>(
    ScheduleRepositoryImpl(remote: getIt<ScheduleRemoteDataSource>()),
  );
  getIt.registerFactory(
      () => GetMyScheduleUseCase(getIt<ScheduleRepository>()));
  getIt.registerFactory(() => ScheduleCubit(
        getMyScheduleUseCase: getIt<GetMyScheduleUseCase>(),
      ));
}
