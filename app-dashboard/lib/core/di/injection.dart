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
import '../../features/student/domain/usecases/get_student_crm_logs_usecase.dart';
import '../../features/student/domain/usecases/add_student_crm_log_usecase.dart';
import '../../features/student/presentation/cubit/student_dashboard_cubit.dart';
import '../../features/student/presentation/cubit/student_form_cubit.dart';
import '../../features/hrm/data/datasources/sdm_remote_datasource.dart';
import '../../features/hrm/data/repositories/sdm_repository_impl.dart';
import '../../features/hrm/domain/repositories/sdm_repository.dart';
import '../../features/hrm/domain/usecases/get_sdm_list_usecase.dart';
import '../../features/hrm/domain/usecases/get_sdm_detail_usecase.dart';
import '../../features/hrm/presentation/cubit/sdm_list_cubit.dart';
import '../../features/hrm/presentation/cubit/sdm_detail_cubit.dart';
import '../../features/business_dev/data/datasources/biz_dev_remote_datasource.dart';
import '../../features/business_dev/data/datasources/partner_detail_remote_datasource.dart';
import '../../features/business_dev/data/repositories/biz_dev_repository_impl.dart';
import '../../features/business_dev/data/repositories/partner_detail_repository_impl.dart';
import '../../features/business_dev/domain/repositories/biz_dev_repository.dart';
import '../../features/business_dev/domain/repositories/partner_detail_repository.dart';
import '../../features/business_dev/domain/usecases/get_partners_usecase.dart';
import '../../features/business_dev/domain/usecases/get_branches_usecase.dart';
import '../../features/business_dev/domain/usecases/get_okr_usecase.dart';
import '../../features/business_dev/domain/usecases/get_investments_usecase.dart';
import '../../features/business_dev/domain/usecases/get_delegations_usecase.dart';
import '../../features/business_dev/domain/usecases/get_partner_detail_usecase.dart';
import '../../features/business_dev/domain/usecases/add_mou_usecase.dart';
import '../../features/business_dev/presentation/cubit/biz_dev_cubit.dart';
import '../../features/business_dev/presentation/cubit/partner_detail_cubit.dart';
import '../../features/leads/data/datasources/lead_remote_datasource.dart';
import '../../features/leads/data/repositories/lead_repository_impl.dart';
import '../../features/leads/domain/repositories/lead_repository.dart';
import '../../features/leads/domain/usecases/get_leads_usecase.dart';
import '../../features/leads/domain/usecases/create_lead_usecase.dart';
import '../../features/leads/domain/usecases/update_lead_usecase.dart';
import '../../features/leads/domain/usecases/delete_lead_usecase.dart';
import '../../features/leads/domain/usecases/get_crm_logs_usecase.dart';
import '../../features/leads/domain/usecases/add_crm_log_usecase.dart';
import '../../features/leads/domain/usecases/convert_lead_usecase.dart';
import '../../features/leads/presentation/cubit/lead_cubit.dart';
import '../../features/certificate/data/datasources/certificate_remote_datasource.dart';
import '../../features/certificate/data/repositories/certificate_repository_impl.dart';
import '../../features/certificate/domain/repositories/certificate_repository.dart';
import '../../features/certificate/domain/usecases/get_certificates_usecase.dart';
import '../../features/certificate/domain/usecases/issue_certificate_usecase.dart';
import '../../features/certificate/domain/usecases/revoke_certificate_usecase.dart';
import '../../features/certificate/domain/usecases/get_certificate_templates_usecase.dart';
import '../../features/certificate/domain/usecases/create_certificate_template_usecase.dart';
import '../../features/certificate/presentation/cubit/certificate_cubit.dart';
import '../../features/accounting/data/datasources/accounting_remote_datasource.dart';
import '../../features/accounting/data/repositories/accounting_repository_impl.dart';
import '../../features/accounting/domain/repositories/accounting_repository.dart';
import '../../features/accounting/domain/usecases/get_accounting_stats_usecase.dart';
import '../../features/accounting/domain/usecases/get_transactions_usecase.dart';
import '../../features/accounting/domain/usecases/create_transaction_usecase.dart';
import '../../features/accounting/domain/usecases/get_invoices_usecase.dart';
import '../../features/accounting/domain/usecases/update_invoice_status_usecase.dart';
import '../../features/accounting/domain/usecases/get_coa_usecase.dart';
import '../../features/accounting/domain/usecases/get_budget_vs_actual_usecase.dart';
import '../../features/accounting/presentation/cubit/accounting_cubit.dart';
import '../../features/finance/presentation/cubit/finance_dashboard_cubit.dart';
import '../../features/finance_reports/data/datasources/finance_reports_remote_datasource.dart';
import '../../features/finance_reports/data/repositories/finance_reports_repository_impl.dart';
import '../../features/finance_reports/domain/repositories/finance_reports_repository.dart';
import '../../features/finance_reports/domain/usecases/get_balance_sheet_usecase.dart';
import '../../features/finance_reports/domain/usecases/get_cash_flow_usecase.dart';
import '../../features/finance_reports/domain/usecases/get_ledger_usecase.dart';
import '../../features/finance_reports/domain/usecases/get_profit_loss_usecase.dart';
import '../../features/finance_reports/domain/usecases/get_trial_balance_usecase.dart';
import '../../features/finance_reports/presentation/cubit/balance_sheet_cubit.dart';
import '../../features/finance_reports/presentation/cubit/cash_flow_cubit.dart';
import '../../features/finance_reports/presentation/cubit/ledger_cubit.dart';
import '../../features/finance_reports/presentation/cubit/profit_loss_cubit.dart';
import '../../features/finance_reports/presentation/cubit/trial_balance_cubit.dart';
import '../../features/marketing/data/datasources/marketing_remote_datasource.dart';
import '../../features/marketing/data/repositories/marketing_repository_impl.dart';
import '../../features/marketing/domain/repositories/marketing_repository.dart';
import '../../features/marketing/domain/usecases/get_marketing_stats_usecase.dart';
import '../../features/marketing/domain/usecases/get_posts_usecase.dart';
import '../../features/marketing/domain/usecases/create_post_usecase.dart';
import '../../features/marketing/domain/usecases/update_post_usecase.dart';
import '../../features/marketing/domain/usecases/submit_post_url_usecase.dart';
import '../../features/marketing/domain/usecases/delete_post_usecase.dart';
import '../../features/marketing/domain/usecases/get_class_docs_usecase.dart';
import '../../features/marketing/domain/usecases/get_pr_usecase.dart';
import '../../features/marketing/domain/usecases/create_pr_usecase.dart';
import '../../features/marketing/domain/usecases/update_pr_usecase.dart';
import '../../features/marketing/domain/usecases/delete_pr_usecase.dart';
import '../../features/marketing/domain/usecases/get_referral_partners_usecase.dart';
import '../../features/marketing/domain/usecases/create_referral_partner_usecase.dart';
import '../../features/marketing/domain/usecases/update_referral_partner_usecase.dart';
import '../../features/marketing/domain/usecases/get_referrals_usecase.dart';
import '../../features/marketing/presentation/cubit/marketing_cubit.dart';
import '../../features/finance_invoices/data/datasources/invoice_remote_datasource.dart';
import '../../features/finance_invoices/data/repositories/invoice_repository_impl.dart';
import '../../features/finance_invoices/domain/repositories/invoice_repository.dart';
import '../../features/finance_invoices/domain/usecases/get_invoice_stats_usecase.dart';
import '../../features/finance_invoices/domain/usecases/get_invoice_list_usecase.dart';
import '../../features/finance_invoices/domain/usecases/get_invoice_detail_usecase.dart';
import '../../features/finance_invoices/domain/usecases/mark_invoice_paid_usecase.dart';
import '../../features/finance_invoices/domain/usecases/resend_invoice_usecase.dart';
import '../../features/finance_invoices/domain/usecases/cancel_invoice_usecase.dart';
import '../../features/finance_invoices/domain/usecases/create_manual_invoice_usecase.dart';
import '../../features/finance_invoices/presentation/cubit/invoice_cubit.dart';
import '../../features/payable/data/datasources/payable_remote_datasource.dart';
import '../../features/payable/data/repositories/payable_repository_impl.dart';
import '../../features/payable/domain/repositories/payable_repository.dart';
import '../../features/payable/domain/usecases/get_payable_stats_usecase.dart';
import '../../features/payable/domain/usecases/get_payables_usecase.dart';
import '../../features/payable/domain/usecases/mark_payable_paid_usecase.dart';
import '../../features/payable/presentation/cubit/payable_cubit.dart';
import '../../features/finance_analysis/data/datasources/finance_analysis_remote_datasource.dart';
import '../../features/finance_analysis/data/repositories/finance_analysis_repository_impl.dart';
import '../../features/finance_analysis/domain/repositories/finance_analysis_repository.dart';
import '../../features/finance_analysis/domain/usecases/get_financial_ratios_usecase.dart';
import '../../features/finance_analysis/domain/usecases/get_revenue_analysis_usecase.dart';
import '../../features/finance_analysis/domain/usecases/get_cost_analysis_usecase.dart';
import '../../features/finance_analysis/domain/usecases/get_batch_profit_analysis_usecase.dart';
import '../../features/finance_analysis/domain/usecases/get_cash_forecast_usecase.dart';
import '../../features/finance_analysis/domain/usecases/get_finance_alerts_usecase.dart';
import '../../features/finance_analysis/domain/usecases/get_finance_suggestions_usecase.dart';
import '../../features/finance_analysis/presentation/cubit/finance_analysis_cubit.dart';
import '../../features/cms/data/datasources/cms_remote_datasource.dart';
import '../../features/cms/data/repositories/cms_repository_impl.dart';
import '../../features/cms/domain/repositories/cms_repository.dart';
import '../../features/cms/domain/usecases/get_cms_pages_usecase.dart';
import '../../features/cms/domain/usecases/update_cms_page_usecase.dart';
import '../../features/cms/domain/usecases/get_cms_articles_usecase.dart';
import '../../features/cms/domain/usecases/create_cms_article_usecase.dart';
import '../../features/cms/domain/usecases/update_cms_article_usecase.dart';
import '../../features/cms/domain/usecases/delete_cms_article_usecase.dart';
import '../../features/cms/domain/usecases/get_cms_testimonials_usecase.dart';
import '../../features/cms/domain/usecases/create_cms_testimonial_usecase.dart';
import '../../features/cms/domain/usecases/update_cms_testimonial_usecase.dart';
import '../../features/cms/domain/usecases/delete_cms_testimonial_usecase.dart';
import '../../features/cms/domain/usecases/get_cms_faq_usecase.dart';
import '../../features/cms/domain/usecases/create_cms_faq_usecase.dart';
import '../../features/cms/domain/usecases/update_cms_faq_usecase.dart';
import '../../features/cms/domain/usecases/delete_cms_faq_usecase.dart';
import '../../features/cms/domain/usecases/get_cms_media_usecase.dart';
import '../../features/cms/domain/usecases/delete_cms_media_usecase.dart';
import '../../features/cms/presentation/cubit/cms_cubit.dart';

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
  getIt.registerFactory(
      () => GetStudentCrmLogsUseCase(getIt<StudentDetailRepository>()));
  getIt.registerFactory(
      () => AddStudentCrmLogUseCase(getIt<StudentDetailRepository>()));
  getIt.registerFactory(() => StudentDashboardCubit(
    getStudentDetail: getIt<GetStudentDetailUseCase>(),
    getEnrollmentHistory: getIt<GetStudentEnrollmentHistoryUseCase>(),
    getRecommendations: getIt<GetStudentRecommendationsUseCase>(),
    getNotes: getIt<GetStudentNotesUseCase>(),
    addNote: getIt<AddStudentNoteUseCase>(),
    updateStudent: getIt<UpdateStudentUseCase>(),
    getTalentPool: getIt<GetTalentPoolUseCase>(),
    getCrmLogs: getIt<GetStudentCrmLogsUseCase>(),
    addCrmLog: getIt<AddStudentCrmLogUseCase>(),
  ));
  getIt.registerFactory(() => StudentFormCubit(
    getDepartments: getIt<GetDepartmentsUseCase>(),
    getStudentDetail: getIt<GetStudentDetailUseCase>(),
    createStudent: getIt<CreateStudentUseCase>(),
    updateStudent: getIt<UpdateStudentUseCase>(),
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

  // Business Development
  getIt.registerSingleton<BizDevRemoteDataSource>(
    BizDevRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<PartnerDetailRemoteDataSource>(
    PartnerDetailRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<BizDevRepository>(
    BizDevRepositoryImpl(
      remoteDataSource: getIt<BizDevRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerSingleton<PartnerDetailRepository>(
    PartnerDetailRepositoryImpl(
      remoteDataSource: getIt<PartnerDetailRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetPartnersUseCase(getIt<BizDevRepository>()));
  getIt.registerFactory(() => GetBranchesUseCase(getIt<BizDevRepository>()));
  getIt.registerFactory(() => GetOkrUseCase(getIt<BizDevRepository>()));
  getIt.registerFactory(() => GetInvestmentsUseCase(getIt<BizDevRepository>()));
  getIt.registerFactory(() => GetDelegationsUseCase(getIt<BizDevRepository>()));
  getIt.registerFactory(
      () => GetPartnerDetailUseCase(getIt<PartnerDetailRepository>()));
  getIt.registerFactory(
      () => AddMouUseCase(getIt<PartnerDetailRepository>()));
  getIt.registerFactory(() => BizDevCubit(
    getPartners: getIt<GetPartnersUseCase>(),
    getBranches: getIt<GetBranchesUseCase>(),
    getOkr: getIt<GetOkrUseCase>(),
    getInvestments: getIt<GetInvestmentsUseCase>(),
    getDelegations: getIt<GetDelegationsUseCase>(),
  ));
  getIt.registerFactory(() => PartnerDetailCubit(
    getPartnerDetail: getIt<GetPartnerDetailUseCase>(),
    addMou: getIt<AddMouUseCase>(),
  ));

  // Leads
  getIt.registerSingleton<LeadRemoteDataSource>(
    LeadRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<LeadRepository>(
    LeadRepositoryImpl(
      remoteDataSource: getIt<LeadRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetLeadsUseCase(getIt<LeadRepository>()));
  getIt.registerFactory(() => CreateLeadUseCase(getIt<LeadRepository>()));
  getIt.registerFactory(() => UpdateLeadUseCase(getIt<LeadRepository>()));
  getIt.registerFactory(() => DeleteLeadUseCase(getIt<LeadRepository>()));
  getIt.registerFactory(() => GetCrmLogsUseCase(getIt<LeadRepository>()));
  getIt.registerFactory(() => AddCrmLogUseCase(getIt<LeadRepository>()));
  getIt.registerFactory(() => ConvertLeadUseCase(getIt<LeadRepository>()));
  getIt.registerFactory(() => LeadCubit(
    getLeadsUseCase: getIt<GetLeadsUseCase>(),
    createLeadUseCase: getIt<CreateLeadUseCase>(),
    updateLeadUseCase: getIt<UpdateLeadUseCase>(),
    deleteLeadUseCase: getIt<DeleteLeadUseCase>(),
    getCrmLogsUseCase: getIt<GetCrmLogsUseCase>(),
    addCrmLogUseCase: getIt<AddCrmLogUseCase>(),
    convertLeadUseCase: getIt<ConvertLeadUseCase>(),
  ));

  // Certificate
  getIt.registerSingleton<CertificateRemoteDataSource>(
    CertificateRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<CertificateRepository>(
    CertificateRepositoryImpl(
      remoteDataSource: getIt<CertificateRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetCertificatesUseCase(getIt<CertificateRepository>()));
  getIt.registerFactory(() => IssueCertificateUseCase(getIt<CertificateRepository>()));
  getIt.registerFactory(() => RevokeCertificateUseCase(getIt<CertificateRepository>()));
  getIt.registerFactory(() => GetCertificateTemplatesUseCase(getIt<CertificateRepository>()));
  getIt.registerFactory(() => CreateCertificateTemplateUseCase(getIt<CertificateRepository>()));
  getIt.registerFactory(() => CertificateCubit(
    getCertificatesUseCase: getIt<GetCertificatesUseCase>(),
    getTemplatesUseCase: getIt<GetCertificateTemplatesUseCase>(),
    issueCertificateUseCase: getIt<IssueCertificateUseCase>(),
    revokeCertificateUseCase: getIt<RevokeCertificateUseCase>(),
    createTemplateUseCase: getIt<CreateCertificateTemplateUseCase>(),
  ));

  // Accounting
  getIt.registerSingleton<AccountingRemoteDataSource>(
    AccountingRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<AccountingRepository>(
    AccountingRepositoryImpl(
      remoteDataSource: getIt<AccountingRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetAccountingStatsUseCase(getIt<AccountingRepository>()));
  getIt.registerFactory(() => GetTransactionsUseCase(getIt<AccountingRepository>()));
  getIt.registerFactory(() => CreateTransactionUseCase(getIt<AccountingRepository>()));
  getIt.registerFactory(() => GetInvoicesUseCase(getIt<AccountingRepository>()));
  getIt.registerFactory(() => UpdateInvoiceStatusUseCase(getIt<AccountingRepository>()));
  getIt.registerFactory(() => GetCoaUseCase(getIt<AccountingRepository>()));
  getIt.registerFactory(() => GetBudgetVsActualUseCase(getIt<AccountingRepository>()));
  getIt.registerFactory(() => AccountingCubit(
    getStatsUseCase: getIt<GetAccountingStatsUseCase>(),
    getTransactionsUseCase: getIt<GetTransactionsUseCase>(),
    createTransactionUseCase: getIt<CreateTransactionUseCase>(),
    getInvoicesUseCase: getIt<GetInvoicesUseCase>(),
    updateInvoiceStatusUseCase: getIt<UpdateInvoiceStatusUseCase>(),
    getCoaUseCase: getIt<GetCoaUseCase>(),
    getBudgetVsActualUseCase: getIt<GetBudgetVsActualUseCase>(),
  ));
  // Marketing
  getIt.registerSingleton<MarketingRemoteDataSource>(
    MarketingRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<MarketingRepository>(
    MarketingRepositoryImpl(
      remoteDataSource: getIt<MarketingRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetMarketingStatsUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => GetPostsUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => CreatePostUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => UpdatePostUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => SubmitPostUrlUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => DeletePostUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => GetClassDocsUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => GetPrUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => CreatePrUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => UpdatePrUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => DeletePrUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => GetReferralPartnersUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => CreateReferralPartnerUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => UpdateReferralPartnerUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => GetReferralsUseCase(getIt<MarketingRepository>()));
  getIt.registerFactory(() => MarketingCubit(
    getStatsUseCase: getIt<GetMarketingStatsUseCase>(),
    getPostsUseCase: getIt<GetPostsUseCase>(),
    createPostUseCase: getIt<CreatePostUseCase>(),
    updatePostUseCase: getIt<UpdatePostUseCase>(),
    submitPostUrlUseCase: getIt<SubmitPostUrlUseCase>(),
    deletePostUseCase: getIt<DeletePostUseCase>(),
    getClassDocsUseCase: getIt<GetClassDocsUseCase>(),
    getPrUseCase: getIt<GetPrUseCase>(),
    createPrUseCase: getIt<CreatePrUseCase>(),
    updatePrUseCase: getIt<UpdatePrUseCase>(),
    deletePrUseCase: getIt<DeletePrUseCase>(),
    getReferralPartnersUseCase: getIt<GetReferralPartnersUseCase>(),
    createReferralPartnerUseCase: getIt<CreateReferralPartnerUseCase>(),
    updateReferralPartnerUseCase: getIt<UpdateReferralPartnerUseCase>(),
    getReferralsUseCase: getIt<GetReferralsUseCase>(),
  ));

  getIt.registerFactory(() => FinanceDashboardCubit(
    getStatsUseCase: getIt<GetAccountingStatsUseCase>(),
    getTransactionsUseCase: getIt<GetTransactionsUseCase>(),
    getInvoicesUseCase: getIt<GetInvoicesUseCase>(),
    getBudgetVsActualUseCase: getIt<GetBudgetVsActualUseCase>(),
    createTransactionUseCase: getIt<CreateTransactionUseCase>(),
    updateInvoiceStatusUseCase: getIt<UpdateInvoiceStatusUseCase>(),
  ));

  // Finance Reports
  getIt.registerSingleton<FinanceReportsRemoteDataSource>(
    FinanceReportsRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<FinanceReportsRepository>(
    FinanceReportsRepositoryImpl(
      remoteDataSource: getIt<FinanceReportsRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetBalanceSheetUseCase(getIt<FinanceReportsRepository>()));
  getIt.registerFactory(() => GetProfitLossUseCase(getIt<FinanceReportsRepository>()));
  getIt.registerFactory(() => GetCashFlowUseCase(getIt<FinanceReportsRepository>()));
  getIt.registerFactory(() => GetLedgerUseCase(getIt<FinanceReportsRepository>()));
  getIt.registerFactory(() => GetTrialBalanceUseCase(getIt<FinanceReportsRepository>()));
  getIt.registerFactory(() => BalanceSheetCubit(getIt<GetBalanceSheetUseCase>()));
  getIt.registerFactory(() => ProfitLossCubit(getIt<GetProfitLossUseCase>()));
  getIt.registerFactory(() => CashFlowCubit(getIt<GetCashFlowUseCase>()));
  getIt.registerFactory(() => LedgerCubit(getIt<GetLedgerUseCase>()));
  getIt.registerFactory(() => TrialBalanceCubit(getIt<GetTrialBalanceUseCase>()));

  // Finance Invoices
  getIt.registerSingleton<InvoiceRemoteDataSource>(
    InvoiceRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<InvoiceRepository>(
    InvoiceRepositoryImpl(
      remoteDataSource: getIt<InvoiceRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetInvoiceStatsUseCase(getIt<InvoiceRepository>()));
  getIt.registerFactory(() => GetInvoiceListUseCase(getIt<InvoiceRepository>()));
  getIt.registerFactory(() => GetInvoiceDetailUseCase(getIt<InvoiceRepository>()));
  getIt.registerFactory(() => MarkInvoicePaidUseCase(getIt<InvoiceRepository>()));
  getIt.registerFactory(() => ResendInvoiceUseCase(getIt<InvoiceRepository>()));
  getIt.registerFactory(() => CancelInvoiceUseCase(getIt<InvoiceRepository>()));
  getIt.registerFactory(
      () => CreateManualInvoiceUseCase(getIt<InvoiceRepository>()));
  getIt.registerFactory(() => InvoiceCubit(
        getStats: getIt<GetInvoiceStatsUseCase>(),
        getInvoices: getIt<GetInvoiceListUseCase>(),
        getDetail: getIt<GetInvoiceDetailUseCase>(),
        markPaid: getIt<MarkInvoicePaidUseCase>(),
        resend: getIt<ResendInvoiceUseCase>(),
        cancel: getIt<CancelInvoiceUseCase>(),
        createManual: getIt<CreateManualInvoiceUseCase>(),
      ));

  // Payable
  getIt.registerSingleton<PayableRemoteDataSource>(
    PayableRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<PayableRepository>(
    PayableRepositoryImpl(
      remoteDataSource: getIt<PayableRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetPayableStatsUseCase(getIt<PayableRepository>()));
  getIt.registerFactory(() => GetPayablesUseCase(getIt<PayableRepository>()));
  getIt.registerFactory(() => MarkPayablePaidUseCase(getIt<PayableRepository>()));
  getIt.registerFactory(() => PayableCubit(
        getPayableStatsUseCase: getIt<GetPayableStatsUseCase>(),
        getPayablesUseCase: getIt<GetPayablesUseCase>(),
        markPayablePaidUseCase: getIt<MarkPayablePaidUseCase>(),
      ));

  // Finance Analysis
  getIt.registerSingleton<FinanceAnalysisRemoteDataSource>(
    FinanceAnalysisRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<FinanceAnalysisRepository>(
    FinanceAnalysisRepositoryImpl(
      remoteDataSource: getIt<FinanceAnalysisRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetFinancialRatiosUseCase(getIt<FinanceAnalysisRepository>()));
  getIt.registerFactory(() => GetRevenueAnalysisUseCase(getIt<FinanceAnalysisRepository>()));
  getIt.registerFactory(() => GetCostAnalysisUseCase(getIt<FinanceAnalysisRepository>()));
  getIt.registerFactory(() => GetBatchProfitAnalysisUseCase(getIt<FinanceAnalysisRepository>()));
  getIt.registerFactory(() => GetCashForecastUseCase(getIt<FinanceAnalysisRepository>()));
  getIt.registerFactory(() => GetFinanceAlertsUseCase(getIt<FinanceAnalysisRepository>()));
  getIt.registerFactory(() => GetFinanceSuggestionsUseCase(getIt<FinanceAnalysisRepository>()));
  getIt.registerFactory(() => FinanceAnalysisCubit(
    getRatios: getIt<GetFinancialRatiosUseCase>(),
    getRevenue: getIt<GetRevenueAnalysisUseCase>(),
    getCosts: getIt<GetCostAnalysisUseCase>(),
    getBatchProfit: getIt<GetBatchProfitAnalysisUseCase>(),
    getCashForecast: getIt<GetCashForecastUseCase>(),
    getAlerts: getIt<GetFinanceAlertsUseCase>(),
    getSuggestions: getIt<GetFinanceSuggestionsUseCase>(),
  ));

  // CMS
  getIt.registerSingleton<CmsRemoteDataSource>(
    CmsRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerSingleton<CmsRepository>(
    CmsRepositoryImpl(
      remoteDataSource: getIt<CmsRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );
  getIt.registerFactory(() => GetCmsPagesUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => UpdateCmsPageUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => GetCmsArticlesUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => CreateCmsArticleUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => UpdateCmsArticleUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => DeleteCmsArticleUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => GetCmsTestimonialsUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => CreateCmsTestimonialUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => UpdateCmsTestimonialUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => DeleteCmsTestimonialUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => GetCmsFaqUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => CreateCmsFaqUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => UpdateCmsFaqUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => DeleteCmsFaqUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => GetCmsMediaUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => DeleteCmsMediaUseCase(getIt<CmsRepository>()));
  getIt.registerFactory(() => CmsCubit(
    getPages: getIt<GetCmsPagesUseCase>(),
    updatePage: getIt<UpdateCmsPageUseCase>(),
    getArticles: getIt<GetCmsArticlesUseCase>(),
    createArticle: getIt<CreateCmsArticleUseCase>(),
    updateArticle: getIt<UpdateCmsArticleUseCase>(),
    deleteArticle: getIt<DeleteCmsArticleUseCase>(),
    getTestimonials: getIt<GetCmsTestimonialsUseCase>(),
    createTestimonial: getIt<CreateCmsTestimonialUseCase>(),
    updateTestimonial: getIt<UpdateCmsTestimonialUseCase>(),
    deleteTestimonial: getIt<DeleteCmsTestimonialUseCase>(),
    getFaq: getIt<GetCmsFaqUseCase>(),
    createFaq: getIt<CreateCmsFaqUseCase>(),
    updateFaq: getIt<UpdateCmsFaqUseCase>(),
    deleteFaq: getIt<DeleteCmsFaqUseCase>(),
    getMedia: getIt<GetCmsMediaUseCase>(),
    deleteMedia: getIt<DeleteCmsMediaUseCase>(),
  ));
}
