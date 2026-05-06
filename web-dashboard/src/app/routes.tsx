import { createBrowserRouter } from 'react-router-dom'
import { lazy, Suspense } from 'react'
import { AppShell } from '@/layouts/AppShell/AppShell'
import { appConfig } from '@/config/app.config'
import {
  RootRedirect,
  AuthRoute,
  GuestRoute,
  RoleRoute,
  SuperuserRoute,
  GroupRoute,
  CompanyRoute,
} from './ProtectedRoute'

// ─── Lazy-loaded pages ────────────────────────────────────────────────────────

const LoginPage          = lazy(() => import('@/pages/Login/LoginPage'))
const DashboardPage      = lazy(() => import('@/pages/Dashboard/DashboardPage'))
const ChooseCompanyPage  = lazy(() => import('@/pages/ChooseCompany/ChooseCompanyPage'))
const NotFoundPage       = lazy(() => import('@/pages/errors/NotFoundPage'))
const ForbiddenPage      = lazy(() => import('@/pages/errors/ForbiddenPage'))

// Course
const CourseListPage           = lazy(() => import('@/pages/Course/CourseListPage'))
const CourseFormPage           = lazy(() => import('@/pages/Course/CourseFormPage'))
const CourseVersionPage        = lazy(() => import('@/pages/Course/CourseVersionPage'))
const VersionFormPage          = lazy(() => import('@/pages/Course/VersionFormPage'))
const CourseModulePage         = lazy(() => import('@/pages/Course/CourseModulePage'))
const InternshipConfigPage     = lazy(() => import('@/pages/Course/InternshipConfigPage'))
const CharacterTestConfigPage  = lazy(() => import('@/pages/Course/CharacterTestConfigPage'))
const CourseApprovalsPage      = lazy(() => import('@/pages/Course/CourseApprovalsPage'))
const CourseDashboardPage      = lazy(() => import('@/pages/Course/CourseDashboardPage'))
const StrukturPage             = lazy(() => import('@/pages/Course/StrukturPage'))

// Course Batches
const CourseBatchListPage   = lazy(() => import('@/pages/CourseBatch/CourseBatchListPage'))
const BatchFormPage         = lazy(() => import('@/pages/CourseBatch/BatchFormPage'))
const CourseBatchDetailPage = lazy(() => import('@/pages/CourseBatch/CourseBatchDetailPage'))

// Enrollment
const EnrollmentListPage   = lazy(() => import('@/pages/Enrollment/EnrollmentListPage'))
const EnrollmentFormPage   = lazy(() => import('@/pages/Enrollment/EnrollmentFormPage'))
const EnrollmentDetailPage = lazy(() => import('@/pages/Enrollment/EnrollmentDetailPage'))

// Students
const StudentListPage     = lazy(() => import('@/pages/Students/StudentListPage'))
const StudentFormPage     = lazy(() => import('@/pages/Students/StudentFormPage'))
const StudentDashboardPage = lazy(() => import('@/pages/Students/StudentDashboardPage'))

// Talent Pool
const TalentPoolPage                  = lazy(() => import('@/pages/TalentPool/TalentPoolPage'))
const TalentPoolPlacedPage            = lazy(() => import('@/pages/TalentPool/TalentPoolPlacedPage'))
const TalentPoolLowonganPage          = lazy(() => import('@/pages/TalentPool/TalentPoolLowonganPage'))
const TalentPoolLowonganDetailPage    = lazy(() => import('@/pages/TalentPool/TalentPoolLowonganDetailPage'))
const TalentPoolLowonganFormPage      = lazy(() => import('@/pages/TalentPool/TalentPoolLowonganFormPage'))

// Certificates
const CertificateListPage            = lazy(() => import('@/pages/Certificates/CertificateListPage'))
const IssueParticipantPage           = lazy(() => import('@/pages/Certificates/IssueParticipantPage'))
const IssueCompetencyPage            = lazy(() => import('@/pages/Certificates/IssueCompetencyPage'))
const CertificateTemplateListPage    = lazy(() => import('@/pages/Certificates/CertificateTemplateListPage'))
const CertificateTemplateEditorPage  = lazy(() => import('@/pages/Certificates/CertificateTemplateEditorPage'))

// Departments
const DepartmentListPage     = lazy(() => import('@/pages/Departments/DepartmentListPage'))
const DepartmentFormPage     = lazy(() => import('@/pages/Departments/DepartmentFormPage'))
const DepartmentDashboardPage = lazy(() => import('@/pages/Departments/DepartmentDashboardPage'))

// Finance
const FinanceMainPage       = lazy(() => import('@/pages/Finance/FinanceMainPage'))
const TransactionListPage   = lazy(() => import('@/pages/Finance/TransactionListPage'))
const TransactionFormPage   = lazy(() => import('@/pages/Finance/TransactionFormPage'))
const JournalPage           = lazy(() => import('@/pages/Finance/JournalPage'))
const ChartOfAccountsPage   = lazy(() => import('@/pages/Finance/ChartOfAccountsPage'))
const CoaFormPage           = lazy(() => import('@/pages/Finance/CoaFormPage'))
const BankAccountsPage      = lazy(() => import('@/pages/Finance/BankAccountsPage'))
const InvoiceListPage       = lazy(() => import('@/pages/Finance/InvoiceListPage'))
const ManualInvoiceFormPage = lazy(() => import('@/pages/Finance/ManualInvoiceFormPage'))
const InvoiceDetailPage     = lazy(() => import('@/pages/Finance/InvoiceDetailPage'))
const PayableListPage       = lazy(() => import('@/pages/Finance/PayableListPage'))
const PayableDetailPage     = lazy(() => import('@/pages/Finance/PayableDetailPage'))
const PayableFormPage       = lazy(() => import('@/pages/Finance/PayableFormPage'))
const BankAccountFormPage   = lazy(() => import('@/pages/Finance/BankAccountFormPage'))
const ReportNavigationPage  = lazy(() => import('@/pages/Finance/ReportNavigationPage'))
const BalanceSheetPage      = lazy(() => import('@/pages/Finance/BalanceSheetPage'))
const ProfitLossPage        = lazy(() => import('@/pages/Finance/ProfitLossPage'))
const CashFlowPage          = lazy(() => import('@/pages/Finance/CashFlowPage'))
const GeneralLedgerPage     = lazy(() => import('@/pages/Finance/GeneralLedgerPage'))
const TrialBalancePage      = lazy(() => import('@/pages/Finance/TrialBalancePage'))
const FinancialAnalysisPage = lazy(() => import('@/pages/Finance/FinancialAnalysisPage'))

// HRM
const HrmListPage            = lazy(() => import('@/pages/Hrm/HrmListPage'))
const SdmDetailPage          = lazy(() => import('@/pages/Hrm/SdmDetailPage'))
const EmployeeFormPage       = lazy(() => import('@/pages/Hrm/EmployeeFormPage'))
const AttendancePage         = lazy(() => import('@/pages/Hrm/AttendancePage'))
const AttendanceDetailPage   = lazy(() => import('@/pages/Hrm/AttendanceDetailPage'))
const AttendanceFormPage     = lazy(() => import('@/pages/Hrm/AttendanceFormPage'))
const LeaveRequestsPage      = lazy(() => import('@/pages/Hrm/LeaveRequestsPage'))
const LeaveDetailPage        = lazy(() => import('@/pages/Hrm/LeaveDetailPage'))
const LeaveRequestFormPage   = lazy(() => import('@/pages/Hrm/LeaveRequestFormPage'))
const PayrollPeriodsPage     = lazy(() => import('@/pages/Hrm/PayrollPeriodsPage'))
const PayrollPeriodFormPage  = lazy(() => import('@/pages/Hrm/PayrollPeriodFormPage'))
const PayrollDetailPage      = lazy(() => import('@/pages/Hrm/PayrollDetailPage'))

// Leads
const LeadListPage   = lazy(() => import('@/pages/Leads/LeadListPage'))
const LeadFormPage   = lazy(() => import('@/pages/Leads/LeadFormPage'))
const LeadDetailPage = lazy(() => import('@/pages/Leads/LeadDetailPage'))

// Operations
const LocationListPage   = lazy(() => import('@/pages/Operations/LocationListPage'))
const LocationDetailPage = lazy(() => import('@/pages/Operations/LocationDetailPage'))
const LocationFormPage   = lazy(() => import('@/pages/Operations/LocationFormPage'))
const PaymentListPage  = lazy(() => import('@/pages/Operations/PaymentListPage'))

// Marketing
const MarketingPage      = lazy(() => import('@/pages/Marketing/MarketingPage'))
const SocialPostListPage = lazy(() => import('@/pages/Marketing/SocialPostListPage'))
const SocialPostFormPage = lazy(() => import('@/pages/Marketing/SocialPostFormPage'))
const PrContentListPage  = lazy(() => import('@/pages/Marketing/PrContentListPage'))
const PrContentFormPage  = lazy(() => import('@/pages/Marketing/PrContentFormPage'))
const ReferralListPage   = lazy(() => import('@/pages/Marketing/ReferralListPage'))
const ReferralFormPage   = lazy(() => import('@/pages/Marketing/ReferralFormPage'))

// CRM
const CrmPage = lazy(() => import('@/pages/Crm/CrmPage'))

// Partners
const PartnerListPage   = lazy(() => import('@/pages/Partners/PartnerListPage'))
const PartnerFormPage   = lazy(() => import('@/pages/Partners/PartnerFormPage'))

// Business Development
const BusinessDevPage        = lazy(() => import('@/pages/BusinessDev/BusinessDevPage'))
const BmcPage                = lazy(() => import('@/pages/BusinessDev/BmcPage'))
const BranchManagementPage   = lazy(() => import('@/pages/BusinessDev/BranchManagementPage'))
const FranchiseManagementPage = lazy(() => import('@/pages/BusinessDev/FranchiseManagementPage'))
const OkrPage                = lazy(() => import('@/pages/BusinessDev/OkrPage'))
const InvestmentPlanPage     = lazy(() => import('@/pages/BusinessDev/InvestmentPlanPage'))
const ProjectionReportsPage  = lazy(() => import('@/pages/BusinessDev/ProjectionReportsPage'))
const DelegationPage         = lazy(() => import('@/pages/BusinessDev/DelegationPage'))
const PartnerDetailPage      = lazy(() => import('@/pages/BusinessDev/PartnerDetailPage'))

// Franchisee
const FranchiseeListPage   = lazy(() => import('@/pages/Franchisee/FranchiseeListPage'))
const FranchiseeFormPage   = lazy(() => import('@/pages/Franchisee/FranchiseeFormPage'))
const FranchiseeDetailPage = lazy(() => import('@/pages/Franchisee/FranchiseeDetailPage'))

// Projects
const ProjectListPage   = lazy(() => import('@/pages/Projects/ProjectListPage'))
const ProjectDetailPage = lazy(() => import('@/pages/Projects/ProjectDetailPage'))
const ProjectFormPage   = lazy(() => import('@/pages/Projects/ProjectFormPage'))

// CMS
const CmsPage             = lazy(() => import('@/pages/Cms/CmsPage'))
const PageEditorPage      = lazy(() => import('@/pages/Cms/PageEditorPage'))
const ArticleListPage     = lazy(() => import('@/pages/Cms/ArticleListPage'))
const ArticleFormPage     = lazy(() => import('@/pages/Cms/ArticleFormPage'))
const TestimonialListPage = lazy(() => import('@/pages/Cms/TestimonialListPage'))
const TestimonialFormPage = lazy(() => import('@/pages/Cms/TestimonialFormPage'))
const FaqListPage         = lazy(() => import('@/pages/Cms/FaqListPage'))
const FaqFormPage         = lazy(() => import('@/pages/Cms/FaqFormPage'))

// Settings
const SettingsPage        = lazy(() => import('@/pages/Settings/SettingsPage'))
const LeadSourceListPage   = lazy(() => import('@/pages/Settings/LeadSourceListPage'))
const LeadSourceDetailPage = lazy(() => import('@/pages/Settings/LeadSourceDetailPage'))
const LeadSourceFormPage   = lazy(() => import('@/pages/Settings/LeadSourceFormPage'))

// Notifications
const NotificationPage = lazy(() => import('@/pages/Notifications/NotificationPage'))

// Approvals
const ApprovalPage = lazy(() => import('@/pages/Approvals/ApprovalPage'))

// Calendar
const CalendarPage = lazy(() => import('@/pages/Calendar/CalendarPage'))

// ─── Suspense wrapper ─────────────────────────────────────────────────────────

function S({ children }: { children: React.ReactNode }) {
  return <Suspense fallback={<div />}>{children}</Suspense>
}

// ─── Single-tenant routes (VernonEdu) ─────────────────────────────────────────

const singleTenantRoutes = [
  {
    path: '/',
    element: <AuthRoute><AppShell /></AuthRoute>,
    children: [
      { path: 'dashboard', element: <S><DashboardPage /></S> },

      // ── Course ─────────────────────────────────────────────────────────────
      { path: 'course',                               element: <S><CourseListPage /></S> },
      { path: 'pendidikan/struktur',                  element: <S><StrukturPage /></S> },
      { path: 'course/new',                           element: <S><CourseFormPage /></S> },
      { path: 'course/:courseId',                     element: <S><CourseDashboardPage /></S> },
      { path: 'course/:courseId/edit',                element: <S><CourseFormPage /></S> },
      { path: 'course/:courseId/versions',            element: <S><CourseVersionPage /></S> },
      { path: 'course/:courseId/versions/new',        element: <S><VersionFormPage /></S> },
      { path: 'course/:courseId/versions/:versionId/edit', element: <S><VersionFormPage /></S> },
      { path: 'course/:courseId/versions/:versionId/modules', element: <S><CourseModulePage /></S> },
      { path: 'course/:courseId/internship-config',   element: <S><InternshipConfigPage /></S> },
      { path: 'course/:courseId/character-test-config', element: <S><CharacterTestConfigPage /></S> },
      { path: 'course/approvals',                     element: <S><CourseApprovalsPage /></S> },

      // ── Course Batches ─────────────────────────────────────────────────────
      { path: 'course-batches',                       element: <S><CourseBatchListPage /></S> },
      { path: 'course-batches/new',                   element: <S><BatchFormPage /></S> },
      { path: 'course-batches/:batchId',              element: <S><CourseBatchDetailPage /></S> },
      { path: 'course-batches/:batchId/edit',         element: <S><BatchFormPage /></S> },

      // ── Enrollment ─────────────────────────────────────────────────────────
      { path: 'enrollments',                          element: <S><EnrollmentListPage /></S> },
      { path: 'enrollments/new',                      element: <S><EnrollmentFormPage /></S> },
      { path: 'enrollments/:enrollmentId',            element: <S><EnrollmentDetailPage /></S> },
      { path: 'enrollments/:enrollmentId/edit',       element: <S><EnrollmentFormPage /></S> },

      // ── Students ───────────────────────────────────────────────────────────
      { path: 'students',                             element: <S><StudentListPage /></S> },
      { path: 'students/new',                         element: <S><StudentFormPage /></S> },
      { path: 'students/:studentId',                  element: <S><StudentDashboardPage /></S> },
      { path: 'students/:studentId/edit',             element: <S><StudentFormPage /></S> },

      // ── Talent Pool ────────────────────────────────────────────────────────
      { path: 'talentpool',                           element: <S><TalentPoolPage /></S> },
      { path: 'talentpool/placed',                    element: <S><TalentPoolPlacedPage /></S> },
      { path: 'talentpool/lowongan',                  element: <S><TalentPoolLowonganPage /></S> },
      { path: 'talentpool/lowongan/new',              element: <S><TalentPoolLowonganFormPage /></S> },
      { path: 'talentpool/lowongan/:vacancyId',       element: <S><TalentPoolLowonganDetailPage /></S> },
      { path: 'talentpool/lowongan/:vacancyId/edit',  element: <S><TalentPoolLowonganFormPage /></S> },

      // ── Certificates ───────────────────────────────────────────────────────
      { path: 'certificates',                         element: <S><CertificateListPage /></S> },
      { path: 'certificates/issue-participant/:enrollmentId', element: <S><IssueParticipantPage /></S> },
      { path: 'certificates/issue-competency/:enrollmentId',  element: <S><IssueCompetencyPage /></S> },
      { path: 'certificates/templates',               element: <S><CertificateTemplateListPage /></S> },
      { path: 'certificates/templates/new',           element: <S><CertificateTemplateEditorPage /></S> },
      { path: 'certificates/templates/:templateId/edit', element: <S><CertificateTemplateEditorPage /></S> },

      // ── Departments (under Pendidikan → Struktur) ─────────────────────────
      { path: 'pendidikan/struktur/departments/new',         element: <RoleRoute role={['director','education_leader']}><S><DepartmentFormPage /></S></RoleRoute> },
      { path: 'pendidikan/struktur/departments/:deptId',     element: <RoleRoute role={['director','education_leader','dept_leader','course_owner','facilitator']}><S><DepartmentDashboardPage /></S></RoleRoute> },
      { path: 'pendidikan/struktur/departments/:deptId/edit', element: <RoleRoute role={['director','education_leader']}><S><DepartmentFormPage /></S></RoleRoute> },

      // ── Leads ──────────────────────────────────────────────────────────────
      { path: 'leads',                                element: <S><LeadListPage /></S> },
      { path: 'leads/new',                            element: <S><LeadFormPage /></S> },
      { path: 'leads/:leadId/edit',                   element: <S><LeadFormPage /></S> },
      { path: 'leads/:leadId',                        element: <S><LeadDetailPage /></S> },

      // ── Locations (under Pengembangan) ────────────────────────────────────
      { path: 'pengembangan/locations',                  element: <S><LocationListPage /></S> },
      { path: 'pengembangan/locations/new',              element: <S><LocationFormPage /></S> },
      { path: 'pengembangan/locations/:buildingId',      element: <S><LocationDetailPage /></S> },
      { path: 'pengembangan/locations/:buildingId/edit', element: <S><LocationFormPage /></S> },

      // ── Payments ───────────────────────────────────────────────────────────
      { path: 'payments',                             element: <S><PaymentListPage /></S> },

      // ── Marketing ──────────────────────────────────────────────────────────
      { path: 'marketing',                            element: <S><MarketingPage /></S> },
      { path: 'marketing/social',                     element: <S><SocialPostListPage /></S> },
      { path: 'marketing/social/new',                 element: <S><SocialPostFormPage /></S> },
      { path: 'marketing/social/:postId/edit',        element: <S><SocialPostFormPage /></S> },
      { path: 'marketing/pr',                         element: <S><PrContentListPage /></S> },
      { path: 'marketing/pr/new',                     element: <S><PrContentFormPage /></S> },
      { path: 'marketing/pr/:contentId/edit',         element: <S><PrContentFormPage /></S> },
      { path: 'marketing/referral',                   element: <S><ReferralListPage /></S> },
      { path: 'marketing/referral/new',               element: <S><ReferralFormPage /></S> },
      { path: 'marketing/referral/:refId/edit',       element: <S><ReferralFormPage /></S> },

      // ── CRM ────────────────────────────────────────────────────────────────
      { path: 'crm',                                  element: <S><CrmPage /></S> },

      // ── Partners ───────────────────────────────────────────────────────────
      { path: 'partners',                             element: <S><PartnerListPage /></S> },
      { path: 'partners/new',                         element: <S><PartnerFormPage /></S> },
      { path: 'partners/:partnerId',                  element: <S><PartnerDetailPage /></S> },
      { path: 'partners/:partnerId/edit',             element: <S><PartnerFormPage /></S> },

      // ── Finance ────────────────────────────────────────────────────────────
      { path: 'finance',                              element: <S><FinanceMainPage /></S> },
      { path: 'finance/transactions',                 element: <S><TransactionListPage /></S> },
      { path: 'finance/transactions/new',             element: <S><TransactionFormPage /></S> },
      { path: 'finance/transactions/:txId/edit',      element: <S><TransactionFormPage /></S> },
      { path: 'finance/journals',                     element: <S><JournalPage /></S> },
      { path: 'finance/chart-of-accounts',            element: <S><ChartOfAccountsPage /></S> },
      { path: 'finance/chart-of-accounts/new',        element: <S><CoaFormPage /></S> },
      { path: 'finance/chart-of-accounts/:coaId/edit', element: <S><CoaFormPage /></S> },
      { path: 'finance/bank-accounts',                element: <S><BankAccountsPage /></S> },
      { path: 'finance/bank-accounts/new',              element: <S><BankAccountFormPage /></S> },
      { path: 'finance/bank-accounts/:accountId/edit',  element: <S><BankAccountFormPage /></S> },
      { path: 'finance/invoices',                     element: <S><InvoiceListPage /></S> },
      { path: 'finance/invoices/new',                 element: <S><ManualInvoiceFormPage /></S> },
      { path: 'finance/invoices/:invoiceId',          element: <S><InvoiceDetailPage /></S> },
      { path: 'finance/payables',                     element: <S><PayableListPage /></S> },
      { path: 'finance/payables/new',                 element: <S><PayableFormPage /></S> },
      { path: 'finance/payables/:payableId',          element: <S><PayableDetailPage /></S> },
      { path: 'finance/reports',                      element: <S><ReportNavigationPage /></S> },
      { path: 'finance/reports/balance-sheet',        element: <S><BalanceSheetPage /></S> },
      { path: 'finance/reports/profit-loss',          element: <S><ProfitLossPage /></S> },
      { path: 'finance/reports/cash-flow',            element: <S><CashFlowPage /></S> },
      { path: 'finance/reports/general-ledger',       element: <S><GeneralLedgerPage /></S> },
      { path: 'finance/reports/trial-balance',        element: <S><TrialBalancePage /></S> },
      { path: 'finance/reports/analysis',             element: <S><FinancialAnalysisPage /></S> },

      // ── HRM ────────────────────────────────────────────────────────────────
      { path: 'hrm',                                  element: <S><HrmListPage /></S> },
      { path: 'hrm/new',                              element: <S><EmployeeFormPage /></S> },
      { path: 'hrm/:employeeId',                      element: <S><SdmDetailPage /></S> },
      { path: 'hrm/:employeeId/edit',                 element: <S><EmployeeFormPage /></S> },
      { path: 'hrm/attendance',                       element: <S><AttendancePage /></S> },
      { path: 'hrm/attendance/new',                   element: <S><AttendanceFormPage /></S> },
      { path: 'hrm/attendance/:attendanceId',         element: <S><AttendanceDetailPage /></S> },
      { path: 'hrm/attendance/:attendanceId/edit',    element: <S><AttendanceFormPage /></S> },
      { path: 'hrm/leaves',                           element: <S><LeaveRequestsPage /></S> },
      { path: 'hrm/leaves/new',                       element: <S><LeaveRequestFormPage /></S> },
      { path: 'hrm/leaves/:leaveId',                  element: <S><LeaveDetailPage /></S> },
      { path: 'hrm/payroll',                          element: <S><PayrollPeriodsPage /></S> },
      { path: 'hrm/payroll/new',                      element: <S><PayrollPeriodFormPage /></S> },
      { path: 'hrm/payroll/:periodId',                element: <S><PayrollDetailPage /></S> },

      // ── Projects ───────────────────────────────────────────────────────────
      { path: 'projects',                             element: <S><ProjectListPage /></S> },
      { path: 'projects/new',                         element: <S><ProjectFormPage /></S> },
      { path: 'projects/:projectId',                  element: <S><ProjectDetailPage /></S> },
      { path: 'projects/:projectId/edit',             element: <S><ProjectFormPage /></S> },

      // ── Business Development ───────────────────────────────────────────────
      { path: 'business-development',                 element: <S><BusinessDevPage /></S> },
      { path: 'business-development/bmc',             element: <S><BmcPage /></S> },
      { path: 'business-development/branches',        element: <S><BranchManagementPage /></S> },
      { path: 'business-development/franchise',       element: <S><FranchiseManagementPage /></S> },
      { path: 'business-development/okr',             element: <S><OkrPage /></S> },
      { path: 'business-development/investment',      element: <S><InvestmentPlanPage /></S> },
      { path: 'business-development/projections',     element: <S><ProjectionReportsPage /></S> },
      { path: 'business-development/delegation',      element: <S><DelegationPage /></S> },
      { path: 'business-development/partners/:partnerId', element: <S><PartnerDetailPage /></S> },

      // ── Franchisee ─────────────────────────────────────────────────────────
      { path: 'pengembangan/franchisees',          element: <S><FranchiseeListPage /></S> },
      { path: 'pengembangan/franchisees/new',      element: <S><FranchiseeFormPage /></S> },
      { path: 'pengembangan/franchisees/:id',      element: <S><FranchiseeDetailPage /></S> },
      { path: 'pengembangan/franchisees/:id/edit', element: <S><FranchiseeFormPage /></S> },

      // ── CMS ────────────────────────────────────────────────────────────────
      { path: 'cms',                                  element: <S><CmsPage /></S> },
      { path: 'cms/articles',                         element: <S><ArticleListPage /></S> },
      { path: 'cms/testimonials',                     element: <S><TestimonialListPage /></S> },
      { path: 'cms/faq',                              element: <S><FaqListPage /></S> },
      { path: 'cms/pages/new',                        element: <S><PageEditorPage /></S> },
      { path: 'cms/pages/:pageId/edit',               element: <S><PageEditorPage /></S> },
      { path: 'cms/articles/new',                     element: <S><ArticleFormPage /></S> },
      { path: 'cms/articles/:articleId/edit',         element: <S><ArticleFormPage /></S> },
      { path: 'cms/testimonials/new',                 element: <S><TestimonialFormPage /></S> },
      { path: 'cms/testimonials/:testimonialId/edit', element: <S><TestimonialFormPage /></S> },
      { path: 'cms/faq/new',                          element: <S><FaqFormPage /></S> },
      { path: 'cms/faq/:faqId/edit',                  element: <S><FaqFormPage /></S> },

      // ── Approvals ──────────────────────────────────────────────────────────
      { path: 'approvals',                            element: <S><ApprovalPage /></S> },

      // ── Calendar ───────────────────────────────────────────────────────────
      { path: 'calendar',                             element: <S><CalendarPage /></S> },

      // ── Notifications ──────────────────────────────────────────────────────
      { path: 'notifications',                        element: <S><NotificationPage /></S> },

      // ── Settings ───────────────────────────────────────────────────────────
      { path: 'settings',                             element: <S><SettingsPage /></S> },
      { path: 'settings/lead-sources',                element: <S><LeadSourceListPage /></S> },
      { path: 'settings/lead-sources/new',            element: <S><LeadSourceFormPage /></S> },
      { path: 'settings/lead-sources/:sourceId',      element: <S><LeadSourceDetailPage /></S> },
      { path: 'settings/lead-sources/:sourceId/edit', element: <S><LeadSourceFormPage /></S> },
    ],
  },
]

// ─── Multi-tenant routes (kept for future use) ────────────────────────────────

const multiTenantRoutes = [
  {
    path: '/choose-company',
    element: <AuthRoute><S><ChooseCompanyPage /></S></AuthRoute>,
  },
  {
    path: '/su',
    element: <SuperuserRoute><AppShell context="superuser" /></SuperuserRoute>,
    children: [
      { path: 'dashboard', element: <S><DashboardPage /></S> },
    ],
  },
  {
    path: '/g',
    element: <GroupRoute><AppShell context="hq" /></GroupRoute>,
    children: [
      { path: 'dashboard', element: <S><DashboardPage /></S> },
    ],
  },
  {
    path: '/c/:companyCode',
    element: <CompanyRoute><AppShell context="company" /></CompanyRoute>,
    children: [
      { path: 'dashboard', element: <S><DashboardPage /></S> },
    ],
  },
]

// ─── Router ───────────────────────────────────────────────────────────────────

export const router = createBrowserRouter([
  { path: '/', element: <RootRedirect /> },
  { path: '/login', element: <GuestRoute><S><LoginPage /></S></GuestRoute> },
  ...(appConfig.isMultiTenant ? multiTenantRoutes : singleTenantRoutes),
  { path: '/403', element: <S><ForbiddenPage /></S> },
  { path: '*',    element: <S><NotFoundPage /></S> },
])
