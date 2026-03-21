import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/shell/presentation/pages/shell_page.dart';
import '../../features/course/presentation/pages/course_page.dart';
import '../../features/course/presentation/pages/course_dashboard_page.dart';
import '../../features/course/presentation/pages/education_page.dart';
import '../../features/course_batch/presentation/pages/course_batch_page.dart';
import '../../features/course_batch/presentation/pages/course_batch_detail_page.dart';
import '../../features/course_version/presentation/pages/course_version_page.dart';
import '../../features/course_version/presentation/pages/course_module_page.dart';
import '../../features/course_version/presentation/pages/propose_version_page.dart';
import '../../features/talentpool/presentation/pages/talentpool_page.dart';
import '../../features/enrollment/presentation/pages/enrollment_page.dart';
import '../../features/evaluation/presentation/pages/evaluation_page.dart';
import '../../features/student/presentation/pages/student_page.dart';
import '../../features/student/presentation/pages/student_dashboard_page.dart';
import '../../features/student/presentation/pages/student_form_page.dart';
import '../../features/certificate/presentation/pages/certificate_page.dart';
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/department/presentation/pages/department_page.dart';
import '../../features/department/presentation/pages/department_dashboard_page.dart';
import '../../features/finance/presentation/pages/finance_main_page.dart';
import '../../features/finance/presentation/pages/finance_stub_pages.dart';
import '../../features/hrm/presentation/pages/hrm_page.dart';
import '../../features/hrm/presentation/pages/sdm_detail_page.dart';
import '../../features/project_mgmt/presentation/pages/project_page.dart';
import '../../features/crm/presentation/pages/crm_page.dart';
import '../../features/partners/presentation/pages/partner_page.dart';
import '../../features/leads/presentation/pages/leads_page.dart';
import '../../features/locations/presentation/pages/location_page.dart';
import '../../features/notifications/presentation/pages/notification_page.dart';
import '../../features/approvals/presentation/pages/approval_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/business_dev/presentation/pages/business_development_page.dart';
import '../../features/business_dev/presentation/pages/partner_detail_page.dart';
import '../../features/business_dev/presentation/pages/bmc_page.dart';
import '../../features/business_dev/presentation/pages/branch_management_page.dart';
import '../../features/business_dev/presentation/pages/franchise_management_page.dart';
import '../../features/business_dev/presentation/pages/okr_page.dart';
import '../../features/business_dev/presentation/pages/investment_plan_page.dart';
import '../../features/business_dev/presentation/pages/projection_reports_page.dart';
import '../../features/business_dev/presentation/pages/delegation_page.dart';
import '../../features/marketing/presentation/pages/marketing_page.dart';
import '../../features/cms/presentation/pages/cms_page.dart';
import '../constants/app_constants.dart';
import '../di/injection.dart';

class AppRouter {
  AppRouter._();

  static GoRouter router(AuthCubit authCubit) => GoRouter(
        initialLocation: _initialRoute(),
        debugLogDiagnostics: true,
        redirect: (context, state) {
          final authState = authCubit.state;
          final isLoggedIn = authState is AuthAuthenticated;
          final isLoginPage = state.matchedLocation == '/login';

          if (!isLoggedIn && !isLoginPage) return '/login';
          if (isLoggedIn && isLoginPage) return '/dashboard';
          return null;
        },
        refreshListenable: _AuthListenable(authCubit),
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, __) => const LoginPage(),
          ),
          ShellRoute(
            builder: (context, state, child) => BlocProvider.value(
              value: authCubit,
              child: ShellPage(child: child),
            ),
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (_, __) => NoTransitionPage(
                  child: BlocProvider.value(
                    value: authCubit,
                    child: const DashboardPage(),
                  ),
                ),
              ),
              // ── Route kurikulum (nested — direkomendasikan go_router 12.x) ──
              GoRoute(
                path: '/curriculum',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: EducationPage()),
                routes: [
                  GoRoute(
                    path: 'types/:typeId',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: CourseVersionPage(
                        typeId: state.pathParameters['typeId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'versions/:versionId',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: CourseModulePage(
                        versionId: state.pathParameters['versionId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'propose-version',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: ProposeVersionPage()),
                  ),
                  GoRoute(
                    path: ':courseId',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: CourseDashboardPage(
                        courseId: state.pathParameters['courseId']!,
                      ),
                    ),
                  ),
                ],
              ),
              // ── Route lama backward compat — CoursePage tetap tersedia ──
              GoRoute(
                path: '/course-list',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: CoursePage()),
              ),
              GoRoute(
                path: '/talentpool',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: TalentPoolPage()),
              ),

              // ── Route lama (backward compatibility) ──────────────────
              GoRoute(
                path: '/courses',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: CoursePage()),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: CourseDashboardPage(
                        courseId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/course-batches',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: CourseBatchPage()),
                routes: [
                  GoRoute(
                    path: ':batchId',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: CourseBatchDetailPage(
                        batchId: state.pathParameters['batchId']!,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/enrollments',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: EnrollmentPage()),
              ),
              GoRoute(
                path: '/evaluations',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: EvaluationPage()),
              ),
              GoRoute(
                path: '/students',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: StudentPage()),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: StudentFormPage()),
                  ),
                  GoRoute(
                    path: ':studentId',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: StudentDashboardPage(
                        studentId: state.pathParameters['studentId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        pageBuilder: (_, state) => NoTransitionPage(
                          child: StudentFormPage(
                            studentId: state.pathParameters['studentId'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/certificates',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: CertificatePage()),
              ),
              GoRoute(
                path: '/payments',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: PaymentPage()),
              ),
              GoRoute(
                path: '/departments',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: DepartmentPage()),
                routes: [
                  GoRoute(
                    path: ':departmentId',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: DepartmentDashboardPage(
                        departmentId: state.pathParameters['departmentId']!,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/accounting',
                redirect: (_, __) => '/finance',
              ),
              GoRoute(
                path: '/finance',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: FinanceMainPage()),
                routes: [
                  GoRoute(
                    path: 'transactions',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: TransactionPage()),
                    routes: [
                      GoRoute(
                        path: 'new',
                        pageBuilder: (_, __) =>
                            const NoTransitionPage(child: TransactionFormPage()),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'journal',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: JournalPage()),
                  ),
                  GoRoute(
                    path: 'coa',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: ChartOfAccountsPage()),
                  ),
                  GoRoute(
                    path: 'invoices',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: InvoicePage()),
                  ),
                  GoRoute(
                    path: 'payables',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: PayablePage()),
                  ),
                  GoRoute(
                    path: 'reports',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: ReportNavigationPage()),
                    routes: [
                      GoRoute(
                        path: 'balance-sheet',
                        pageBuilder: (_, __) =>
                            const NoTransitionPage(child: BalanceSheetPage()),
                      ),
                      GoRoute(
                        path: 'profit-loss',
                        pageBuilder: (_, __) =>
                            const NoTransitionPage(child: ProfitLossPage()),
                      ),
                      GoRoute(
                        path: 'cash-flow',
                        pageBuilder: (_, __) =>
                            const NoTransitionPage(child: CashFlowPage()),
                      ),
                      GoRoute(
                        path: 'ledger',
                        pageBuilder: (_, __) =>
                            const NoTransitionPage(child: GeneralLedgerPage()),
                      ),
                      GoRoute(
                        path: 'trial-balance',
                        pageBuilder: (_, __) =>
                            const NoTransitionPage(child: TrialBalancePage()),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'analysis',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: FinancialAnalysisPage()),
                  ),
                ],
              ),
              GoRoute(
                path: '/hrm',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: HrmPage()),
                routes: [
                  GoRoute(
                    path: ':sdmId',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: SdmDetailPage(
                        sdmId: state.pathParameters['sdmId']!,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/projects',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: ProjectPage()),
              ),
              GoRoute(
                path: '/crm',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: CrmPage()),
              ),
              GoRoute(
                path: '/partners',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: PartnerPage()),
              ),
              GoRoute(
                path: '/leads',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: LeadsPage()),
              ),
              GoRoute(
                path: '/locations',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: LocationPage()),
              ),
              GoRoute(
                path: '/business-development',
                pageBuilder: (_, __) => const NoTransitionPage(
                    child: BusinessDevelopmentPage()),
                routes: [
                  GoRoute(
                    path: 'canvas',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: BmcPage()),
                  ),
                  GoRoute(
                    path: 'branches',
                    pageBuilder: (_, __) => const NoTransitionPage(
                        child: BranchManagementPage()),
                  ),
                  GoRoute(
                    path: 'franchises',
                    pageBuilder: (_, __) => const NoTransitionPage(
                        child: FranchiseManagementPage()),
                  ),
                  GoRoute(
                    path: 'okr',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: OkrPage()),
                  ),
                  GoRoute(
                    path: 'investments',
                    pageBuilder: (_, __) => const NoTransitionPage(
                        child: InvestmentPlanPage()),
                  ),
                  GoRoute(
                    path: 'projections',
                    pageBuilder: (_, __) => const NoTransitionPage(
                        child: ProjectionReportsPage()),
                  ),
                  GoRoute(
                    path: 'delegations',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: DelegationPage()),
                  ),
                  GoRoute(
                    path: 'partners/:partnerId',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: PartnerDetailPage(
                        partnerId: state.pathParameters['partnerId']!,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/marketing',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: MarketingPage()),
              ),
              GoRoute(
                path: '/notifications',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: NotificationPage()),
              ),
              GoRoute(
                path: '/approvals',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: ApprovalPage()),
              ),
              GoRoute(
                path: '/settings',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: SettingsPage()),
              ),
              GoRoute(
                path: '/cms',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: CmsPage()),
              ),
            ],
          ),
        ],
        errorBuilder: (_, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Halaman tidak ditemukan: ${state.error}'),
              ],
            ),
          ),
        ),
      );

  static String _initialRoute() {
    final prefs = getIt<SharedPreferences>();
    final token = prefs.getString(AppConstants.accessTokenKey);
    return token != null ? '/dashboard' : '/login';
  }
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
