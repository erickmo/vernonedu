import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/course/data/datasources/course_remote_datasource.dart';
import '../../features/course/data/repositories/course_repository_impl.dart';
import '../../features/course/domain/repositories/course_repository.dart';
import '../../features/course/domain/usecases/get_courses_usecase.dart';
import '../../features/course/domain/usecases/create_course_usecase.dart';
import '../../features/course/domain/usecases/update_course_usecase.dart';
import '../../features/course/domain/usecases/delete_course_usecase.dart';
import '../../features/course/domain/usecases/archive_course_usecase.dart';
import '../../features/course/presentation/cubit/course_cubit.dart';
import '../../features/course_batch/data/datasources/course_batch_remote_datasource.dart';
import '../../features/course_batch/data/repositories/course_batch_repository_impl.dart';
import '../../features/course_batch/domain/repositories/course_batch_repository.dart';
import '../../features/course_batch/domain/usecases/get_course_batches_usecase.dart';
import '../../features/course_batch/domain/usecases/create_course_batch_usecase.dart';
import '../../features/course_batch/domain/usecases/get_course_batch_detail_usecase.dart';
import '../../features/course_batch/presentation/cubit/course_batch_cubit.dart';
import '../../features/course_batch/presentation/cubit/course_batch_detail_cubit.dart';
import '../../features/enrollment/data/datasources/enrollment_remote_datasource.dart';
import '../../features/enrollment/data/repositories/enrollment_repository_impl.dart';
import '../../features/enrollment/domain/repositories/enrollment_repository.dart';
import '../../features/enrollment/domain/usecases/get_enrollments_usecase.dart';
import '../../features/enrollment/domain/usecases/get_enrollment_summary_usecase.dart';
import '../../features/enrollment/domain/usecases/enroll_student_usecase.dart';
import '../../features/enrollment/domain/usecases/update_enrollment_status_usecase.dart';
import '../../features/enrollment/domain/usecases/update_enrollment_payment_status_usecase.dart';
import '../../features/enrollment/presentation/cubit/enrollment_cubit.dart';
import '../../features/student/data/datasources/student_remote_datasource.dart';
import '../../features/student/data/repositories/student_repository_impl.dart';
import '../../features/student/domain/repositories/student_repository.dart';
import '../../features/student/domain/usecases/get_students_usecase.dart';
import '../../features/student/domain/usecases/create_student_usecase.dart';
import '../../features/student/domain/usecases/delete_student_usecase.dart';
import '../../features/student/presentation/cubit/student_cubit.dart';
import '../../features/department/data/datasources/department_remote_datasource.dart';
import '../../features/department/data/repositories/department_repository_impl.dart';
import '../../features/department/domain/repositories/department_repository.dart';
import '../../features/department/domain/usecases/get_departments_usecase.dart';
import '../../features/department/domain/usecases/create_department_usecase.dart';
import '../../features/department/domain/usecases/update_department_usecase.dart';
import '../../features/department/domain/usecases/delete_department_usecase.dart';
import '../../features/department/domain/usecases/get_department_summary_usecase.dart';
import '../../features/department/domain/usecases/get_department_batches_usecase.dart';
import '../../features/department/domain/usecases/get_department_courses_usecase.dart';
import '../../features/department/domain/usecases/get_department_students_usecase.dart';
import '../../features/department/domain/usecases/get_department_talentpool_usecase.dart';
import '../../features/department/domain/usecases/assign_batch_facilitator_usecase.dart';
import '../../features/department/presentation/cubit/department_cubit.dart';
import '../../features/department/presentation/cubit/department_dashboard_cubit.dart';
import '../../features/course_type/data/datasources/course_type_remote_datasource.dart';
import '../../features/course_type/data/repositories/course_type_repository_impl.dart';
import '../../features/course_type/domain/repositories/course_type_repository.dart';
import '../../features/course_type/domain/usecases/get_course_types_usecase.dart';
import '../../features/course_type/domain/usecases/create_course_type_usecase.dart';
import '../../features/course_type/domain/usecases/update_course_type_usecase.dart';
import '../../features/course_type/domain/usecases/toggle_course_type_usecase.dart';
import '../../features/course_type/presentation/cubit/course_type_cubit.dart';
import '../../features/course_version/data/datasources/course_version_remote_datasource.dart';
import '../../features/course_version/data/repositories/course_version_repository_impl.dart';
import '../../features/course_version/domain/repositories/course_version_repository.dart';
import '../../features/course_version/domain/usecases/get_course_versions_usecase.dart';
import '../../features/course_version/domain/usecases/create_course_version_usecase.dart';
import '../../features/course_version/domain/usecases/promote_course_version_usecase.dart';
import '../../features/course_version/domain/usecases/get_internship_config_usecase.dart';
import '../../features/course_version/domain/usecases/upsert_internship_config_usecase.dart';
import '../../features/course_version/domain/usecases/get_character_test_config_usecase.dart';
import '../../features/course_version/domain/usecases/upsert_character_test_config_usecase.dart';
import '../../features/course_version/presentation/cubit/course_version_cubit.dart';
import '../../features/course_module/data/datasources/course_module_remote_datasource.dart';
import '../../features/course_module/data/repositories/course_module_repository_impl.dart';
import '../../features/course_module/domain/repositories/course_module_repository.dart';
import '../../features/course_module/domain/usecases/get_course_modules_usecase.dart';
import '../../features/course_module/domain/usecases/create_course_module_usecase.dart';
import '../../features/course_module/domain/usecases/update_course_module_usecase.dart';
import '../../features/course_module/domain/usecases/delete_course_module_usecase.dart';
import '../../features/course_module/presentation/cubit/course_module_cubit.dart';
import '../../features/talentpool/data/datasources/talentpool_remote_datasource.dart';
import '../../features/talentpool/data/repositories/talentpool_repository_impl.dart';
import '../../features/talentpool/domain/repositories/talentpool_repository.dart';
import '../../features/talentpool/domain/usecases/get_talentpool_usecase.dart';
import '../../features/talentpool/domain/usecases/update_talentpool_status_usecase.dart';
import '../../features/talentpool/domain/usecases/get_job_openings_usecase.dart';
import '../../features/talentpool/domain/usecases/get_partner_companies_usecase.dart';
import '../../features/talentpool/presentation/cubit/talentpool_cubit.dart';
import '../../features/student/data/datasources/student_detail_remote_datasource.dart';
import '../../features/student/data/repositories/student_detail_repository_impl.dart';
import '../../features/student/domain/repositories/student_detail_repository.dart';
import '../../features/student/domain/usecases/get_student_detail_usecase.dart';
import '../../features/student/domain/usecases/get_student_enrollment_history_usecase.dart';
import '../../features/student/domain/usecases/get_student_recommendations_usecase.dart';
import '../../features/student/domain/usecases/get_student_notes_usecase.dart';
import '../../features/student/domain/usecases/add_student_note_usecase.dart';
import '../../features/student/domain/usecases/update_student_usecase.dart';
import '../../features/student/presentation/cubit/student_dashboard_cubit.dart';
import '../../features/hrm/data/datasources/sdm_remote_datasource.dart';
import '../../features/hrm/data/repositories/sdm_repository_impl.dart';
import '../../features/hrm/domain/repositories/sdm_repository.dart';
import '../../features/hrm/domain/usecases/get_sdm_list_usecase.dart';
import '../../features/hrm/domain/usecases/get_sdm_detail_usecase.dart';
import '../../features/hrm/presentation/cubit/sdm_list_cubit.dart';
import '../../features/hrm/presentation/cubit/sdm_detail_cubit.dart';

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
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );
  getIt.registerFactory(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerFactory(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerFactory(() => GetCurrentUserUseCase(getIt<AuthRepository>()));
  getIt.registerFactory(() => AuthCubit(
    loginUseCase: getIt<LoginUseCase>(),
    logoutUseCase: getIt<LogoutUseCase>(),
    getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
  ));

  // Course
  getIt.registerSingleton<CourseRemoteDataSource>(
    CourseRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<CourseRepository>(
    CourseRepositoryImpl(
      remoteDataSource: getIt<CourseRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetCoursesUseCase(getIt<CourseRepository>()));
  getIt.registerFactory(() => CreateCourseUseCase(getIt<CourseRepository>()));
  getIt.registerFactory(() => UpdateCourseUseCase(getIt<CourseRepository>()));
  getIt.registerFactory(() => DeleteCourseUseCase(getIt<CourseRepository>()));
  getIt.registerFactory(() => ArchiveCourseUseCase(getIt<CourseRepository>()));
  getIt.registerFactory(() => CourseCubit(
    getCoursesUseCase: getIt<GetCoursesUseCase>(),
    createCourseUseCase: getIt<CreateCourseUseCase>(),
    updateCourseUseCase: getIt<UpdateCourseUseCase>(),
    deleteCourseUseCase: getIt<DeleteCourseUseCase>(),
    archiveCourseUseCase: getIt<ArchiveCourseUseCase>(),
  ));

  // Course Batch
  getIt.registerSingleton<CourseBatchRemoteDataSource>(
    CourseBatchRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<CourseBatchRepository>(
    CourseBatchRepositoryImpl(
      remoteDataSource: getIt<CourseBatchRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetCourseBatchesUseCase(getIt<CourseBatchRepository>()));
  getIt.registerFactory(() => CreateCourseBatchUseCase(getIt<CourseBatchRepository>()));
  getIt.registerFactory(() => GetCourseBatchDetailUseCase(getIt<CourseBatchRepository>()));
  getIt.registerFactory(() => CourseBatchCubit(
    getCourseBatchesUseCase: getIt<GetCourseBatchesUseCase>(),
    createCourseBatchUseCase: getIt<CreateCourseBatchUseCase>(),
  ));
  getIt.registerFactory(() => CourseBatchDetailCubit(
    getCourseBatchDetailUseCase: getIt<GetCourseBatchDetailUseCase>(),
  ));

  // Enrollment
  getIt.registerSingleton<EnrollmentRemoteDataSource>(
    EnrollmentRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<EnrollmentRepository>(
    EnrollmentRepositoryImpl(
      remoteDataSource: getIt<EnrollmentRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetEnrollmentsUseCase(getIt<EnrollmentRepository>()));
  getIt.registerFactory(() => GetEnrollmentSummaryUseCase(getIt<EnrollmentRepository>()));
  getIt.registerFactory(() => EnrollStudentUseCase(getIt<EnrollmentRepository>()));
  getIt.registerFactory(() => UpdateEnrollmentStatusUseCase(getIt<EnrollmentRepository>()));
  getIt.registerFactory(() => UpdateEnrollmentPaymentStatusUseCase(getIt<EnrollmentRepository>()));
  getIt.registerFactory(() => EnrollmentCubit(
    getEnrollmentsUseCase: getIt<GetEnrollmentsUseCase>(),
    getEnrollmentSummaryUseCase: getIt<GetEnrollmentSummaryUseCase>(),
    enrollStudentUseCase: getIt<EnrollStudentUseCase>(),
    updateEnrollmentStatusUseCase: getIt<UpdateEnrollmentStatusUseCase>(),
    updateEnrollmentPaymentStatusUseCase: getIt<UpdateEnrollmentPaymentStatusUseCase>(),
  ));

  // Student
  getIt.registerSingleton<StudentRemoteDataSource>(
    StudentRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<StudentRepository>(
    StudentRepositoryImpl(
      remoteDataSource: getIt<StudentRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetStudentsUseCase(getIt<StudentRepository>()));
  getIt.registerFactory(() => CreateStudentUseCase(getIt<StudentRepository>()));
  getIt.registerFactory(() => DeleteStudentUseCase(getIt<StudentRepository>()));
  getIt.registerFactory(() => StudentCubit(
    getStudentsUseCase: getIt<GetStudentsUseCase>(),
    createStudentUseCase: getIt<CreateStudentUseCase>(),
    deleteStudentUseCase: getIt<DeleteStudentUseCase>(),
  ));

  // Department
  getIt.registerSingleton<DepartmentRemoteDataSource>(
    DepartmentRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<DepartmentRepository>(
    DepartmentRepositoryImpl(
      remoteDataSource: getIt<DepartmentRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetDepartmentsUseCase(getIt<DepartmentRepository>()));
  getIt.registerFactory(() => CreateDepartmentUseCase(getIt<DepartmentRepository>()));
  getIt.registerFactory(() => UpdateDepartmentUseCase(getIt<DepartmentRepository>()));
  getIt.registerFactory(() => DeleteDepartmentUseCase(getIt<DepartmentRepository>()));
  getIt.registerFactory(() => GetDepartmentSummaryUseCase(getIt<DepartmentRepository>()));
  getIt.registerFactory(() => GetDepartmentBatchesUseCase(getIt<DepartmentRepository>()));
  getIt.registerFactory(() => GetDepartmentCoursesUseCase(getIt<DepartmentRepository>()));
  getIt.registerFactory(() => GetDepartmentStudentsUseCase(getIt<DepartmentRepository>()));
  getIt.registerFactory(() => GetDepartmentTalentPoolUseCase(getIt<DepartmentRepository>()));
  getIt.registerFactory(() => AssignBatchFacilitatorUseCase(getIt<DepartmentRepository>()));
  getIt.registerFactory(() => DepartmentCubit(
    getDepartmentsUseCase: getIt<GetDepartmentsUseCase>(),
    createDepartmentUseCase: getIt<CreateDepartmentUseCase>(),
    updateDepartmentUseCase: getIt<UpdateDepartmentUseCase>(),
    deleteDepartmentUseCase: getIt<DeleteDepartmentUseCase>(),
  ));
  getIt.registerFactory(() => DepartmentSummaryCubit(
    getSummary: getIt<GetDepartmentSummaryUseCase>(),
  ));
  getIt.registerFactory(() => DepartmentDashboardCubit(
    getBatches: getIt<GetDepartmentBatchesUseCase>(),
    getCourses: getIt<GetDepartmentCoursesUseCase>(),
    getStudents: getIt<GetDepartmentStudentsUseCase>(),
    getTalentPool: getIt<GetDepartmentTalentPoolUseCase>(),
    assignFacilitator: getIt<AssignBatchFacilitatorUseCase>(),
  ));

  // CourseType
  getIt.registerSingleton<CourseTypeRemoteDataSource>(
    CourseTypeRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<CourseTypeRepository>(
    CourseTypeRepositoryImpl(
      remoteDataSource: getIt<CourseTypeRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetCourseTypesUseCase(getIt<CourseTypeRepository>()));
  getIt.registerFactory(() => CreateCourseTypeUseCase(getIt<CourseTypeRepository>()));
  getIt.registerFactory(() => UpdateCourseTypeUseCase(getIt<CourseTypeRepository>()));
  getIt.registerFactory(() => ToggleCourseTypeUseCase(getIt<CourseTypeRepository>()));
  getIt.registerFactory(() => CourseTypeCubit(
    getCourseTypesUseCase: getIt<GetCourseTypesUseCase>(),
    createCourseTypeUseCase: getIt<CreateCourseTypeUseCase>(),
    updateCourseTypeUseCase: getIt<UpdateCourseTypeUseCase>(),
    toggleCourseTypeUseCase: getIt<ToggleCourseTypeUseCase>(),
  ));

  // CourseVersion
  getIt.registerSingleton<CourseVersionRemoteDataSource>(
    CourseVersionRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<CourseVersionRepository>(
    CourseVersionRepositoryImpl(
      remoteDataSource: getIt<CourseVersionRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetCourseVersionsUseCase(getIt<CourseVersionRepository>()));
  getIt.registerFactory(() => CreateCourseVersionUseCase(getIt<CourseVersionRepository>()));
  getIt.registerFactory(() => PromoteCourseVersionUseCase(getIt<CourseVersionRepository>()));
  getIt.registerFactory(() => GetInternshipConfigUseCase(getIt<CourseVersionRepository>()));
  getIt.registerFactory(() => UpsertInternshipConfigUseCase(getIt<CourseVersionRepository>()));
  getIt.registerFactory(() => GetCharacterTestConfigUseCase(getIt<CourseVersionRepository>()));
  getIt.registerFactory(() => UpsertCharacterTestConfigUseCase(getIt<CourseVersionRepository>()));
  getIt.registerFactory(() => CourseVersionCubit(
    getCourseVersionsUseCase: getIt<GetCourseVersionsUseCase>(),
    createCourseVersionUseCase: getIt<CreateCourseVersionUseCase>(),
    promoteCourseVersionUseCase: getIt<PromoteCourseVersionUseCase>(),
    getInternshipConfigUseCase: getIt<GetInternshipConfigUseCase>(),
    upsertInternshipConfigUseCase: getIt<UpsertInternshipConfigUseCase>(),
    getCharacterTestConfigUseCase: getIt<GetCharacterTestConfigUseCase>(),
    upsertCharacterTestConfigUseCase: getIt<UpsertCharacterTestConfigUseCase>(),
  ));

  // CourseModule
  getIt.registerSingleton<CourseModuleRemoteDataSource>(
    CourseModuleRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<CourseModuleRepository>(
    CourseModuleRepositoryImpl(
      remoteDataSource: getIt<CourseModuleRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetCourseModulesUseCase(getIt<CourseModuleRepository>()));
  getIt.registerFactory(() => CreateCourseModuleUseCase(getIt<CourseModuleRepository>()));
  getIt.registerFactory(() => UpdateCourseModuleUseCase(getIt<CourseModuleRepository>()));
  getIt.registerFactory(() => DeleteCourseModuleUseCase(getIt<CourseModuleRepository>()));
  getIt.registerFactory(() => CourseModuleCubit(
    getCourseModulesUseCase: getIt<GetCourseModulesUseCase>(),
    createCourseModuleUseCase: getIt<CreateCourseModuleUseCase>(),
    updateCourseModuleUseCase: getIt<UpdateCourseModuleUseCase>(),
    deleteCourseModuleUseCase: getIt<DeleteCourseModuleUseCase>(),
  ));

  // TalentPool
  getIt.registerSingleton<TalentPoolRemoteDataSource>(
    TalentPoolRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<TalentPoolRepository>(
    TalentPoolRepositoryImpl(
      remoteDataSource: getIt<TalentPoolRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetTalentPoolUseCase(getIt<TalentPoolRepository>()));
  getIt.registerFactory(() => UpdateTalentPoolStatusUseCase(getIt<TalentPoolRepository>()));
  getIt.registerFactory(() => GetJobOpeningsUseCase(getIt<TalentPoolRepository>()));
  getIt.registerFactory(() => GetPartnerCompaniesUseCase(getIt<TalentPoolRepository>()));
  getIt.registerFactory(() => TalentPoolCubit(
    getTalentPoolUseCase: getIt<GetTalentPoolUseCase>(),
    updateTalentPoolStatusUseCase: getIt<UpdateTalentPoolStatusUseCase>(),
    getJobOpeningsUseCase: getIt<GetJobOpeningsUseCase>(),
    getPartnerCompaniesUseCase: getIt<GetPartnerCompaniesUseCase>(),
  ));

  // Student Detail
  getIt.registerSingleton<StudentDetailRemoteDataSource>(
    StudentDetailRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<StudentDetailRepository>(
    StudentDetailRepositoryImpl(
      remoteDataSource: getIt<StudentDetailRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(
      () => GetStudentDetailUseCase(getIt<StudentDetailRepository>()));
  getIt.registerFactory(
      () => GetStudentEnrollmentHistoryUseCase(getIt<StudentDetailRepository>()));
  getIt.registerFactory(
      () => GetStudentRecommendationsUseCase(getIt<StudentDetailRepository>()));
  getIt.registerFactory(
      () => GetStudentNotesUseCase(getIt<StudentDetailRepository>()));
  getIt.registerFactory(
      () => AddStudentNoteUseCase(getIt<StudentDetailRepository>()));
  getIt.registerFactory(
      () => UpdateStudentUseCase(getIt<StudentDetailRepository>()));
  getIt.registerFactory(() => StudentDashboardCubit(
    getStudentDetail: getIt<GetStudentDetailUseCase>(),
    getEnrollmentHistory: getIt<GetStudentEnrollmentHistoryUseCase>(),
    getRecommendations: getIt<GetStudentRecommendationsUseCase>(),
    getNotes: getIt<GetStudentNotesUseCase>(),
    addNote: getIt<AddStudentNoteUseCase>(),
    updateStudent: getIt<UpdateStudentUseCase>(),
    getTalentPool: getIt<GetTalentPoolUseCase>(),
  ));

  // SDM (HRM)
  getIt.registerSingleton<SdmRemoteDataSource>(
    SdmRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<SdmRepository>(
    SdmRepositoryImpl(
      remoteDataSource: getIt<SdmRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetSdmListUseCase(getIt<SdmRepository>()));
  getIt.registerFactory(() => GetSdmDetailUseCase(getIt<SdmRepository>()));
  getIt.registerFactory(() => SdmListCubit(
    getSdmListUseCase: getIt<GetSdmListUseCase>(),
  ));
  getIt.registerFactory(() => SdmDetailCubit(
    getSdmDetailUseCase: getIt<GetSdmDetailUseCase>(),
  ));
}
