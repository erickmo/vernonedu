import { createBrowserRouter } from 'react-router-dom'
import { lazy, Suspense } from 'react'
import { AppShell } from '@/layouts/AppShell/AppShell'
import { appConfig } from '@/config/app.config'
import {
  RootRedirect,
  AuthRoute,
  GuestRoute,
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

// Curriculum
const CurriculumPage           = lazy(() => import('@/pages/Curriculum/CurriculumPage'))
const CourseFormPage           = lazy(() => import('@/pages/Curriculum/CourseFormPage'))
const CourseVersionPage        = lazy(() => import('@/pages/Curriculum/CourseVersionPage'))
const VersionFormPage          = lazy(() => import('@/pages/Curriculum/VersionFormPage'))
const CourseModulePage         = lazy(() => import('@/pages/Curriculum/CourseModulePage'))
const InternshipConfigPage     = lazy(() => import('@/pages/Curriculum/InternshipConfigPage'))
const CharacterTestConfigPage  = lazy(() => import('@/pages/Curriculum/CharacterTestConfigPage'))
const CurriculumApprovalsPage  = lazy(() => import('@/pages/Curriculum/CurriculumApprovalsPage'))
const CourseDashboardPage      = lazy(() => import('@/pages/Curriculum/CourseDashboardPage'))

// Course Batches
const CourseBatchListPage   = lazy(() => import('@/pages/CourseBatch/CourseBatchListPage'))
const BatchFormPage         = lazy(() => import('@/pages/CourseBatch/BatchFormPage'))
const CourseBatchDetailPage = lazy(() => import('@/pages/CourseBatch/CourseBatchDetailPage'))

// Enrollment
const EnrollmentListPage = lazy(() => import('@/pages/Enrollment/EnrollmentListPage'))
const EnrollmentFormPage = lazy(() => import('@/pages/Enrollment/EnrollmentFormPage'))

// Students
const StudentListPage     = lazy(() => import('@/pages/Students/StudentListPage'))
const StudentFormPage     = lazy(() => import('@/pages/Students/StudentFormPage'))
const StudentDashboardPage = lazy(() => import('@/pages/Students/StudentDashboardPage'))

// Talent Pool
const TalentPoolPage = lazy(() => import('@/pages/TalentPool/TalentPoolPage'))

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
const ReportNavigationPage  = lazy(() => import('@/pages/Finance/ReportNavigationPage'))
const BalanceSheetPage      = lazy(() => import('@/pages/Finance/BalanceSheetPage'))
const ProfitLossPage        = lazy(() => import('@/pages/Finance/ProfitLossPage'))
const CashFlowPage          = lazy(() => import('@/pages/Finance/CashFlowPage'))
const GeneralLedgerPage     = lazy(() => import('@/pages/Finance/GeneralLedgerPage'))
const TrialBalancePage      = lazy(() => import('@/pages/Finance/TrialBalancePage'))
const FinancialAnalysisPage = lazy(() => import('@/pages/Finance/FinancialAnalysisPage'))

// HRM
const HrmListPage         = lazy(() => import('@/pages/Hrm/HrmListPage'))
const SdmDetailPage       = lazy(() => import('@/pages/Hrm/SdmDetailPage'))
const EmployeeFormPage    = lazy(() => import('@/pages/Hrm/EmployeeFormPage'))
const AttendancePage      = lazy(() => import('@/pages/Hrm/AttendancePage'))
const LeaveRequestsPage   = lazy(() => import('@/pages/Hrm/LeaveRequestsPage'))
const PayrollPeriodsPage  = lazy(() => import('@/pages/Hrm/PayrollPeriodsPage'))
const PayrollDetailPage   = lazy(() => import('@/pages/Hrm/PayrollDetailPage'))

// Leads
const LeadListPage = lazy(() => import('@/pages/Leads/LeadListPage'))
const LeadFormPage = lazy(() => import('@/pages/Leads/LeadFormPage'))

// Operations
const LocationListPage = lazy(() => import('@/pages/Operations/LocationListPage'))
const PaymentListPage  = lazy(() => import('@/pages/Operations/PaymentListPage'))

// Marketing
const MarketingPage      = lazy(() => import('@/pages/Marketing/MarketingPage'))
const SocialPostFormPage = lazy(() => import('@/pages/Marketing/SocialPostFormPage'))
const PrContentFormPage  = lazy(() => import('@/pages/Marketing/PrContentFormPage'))
const ReferralFormPage   = lazy(() => import('@/pages/Marketing/ReferralFormPage'))

// CRM
const CrmPage = lazy(() => import('@/pages/Crm/CrmPage'))

// Partners
const PartnerListPage = lazy(() => import('@/pages/Partners/PartnerListPage'))

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

// Projects
const ProjectListPage = lazy(() => import('@/pages/Projects/ProjectListPage'))

// CMS
const CmsPage            = lazy(() => import('@/pages/Cms/CmsPage'))
const PageEditorPage     = lazy(() => import('@/pages/Cms/PageEditorPage'))
const ArticleFormPage    = lazy(() => import('@/pages/Cms/ArticleFormPage'))
const TestimonialFormPage = lazy(() => import('@/pages/Cms/TestimonialFormPage'))
const FaqFormPage        = lazy(() => import('@/pages/Cms/FaqFormPage'))

// Settings
const SettingsPage = lazy(() => import('@/pages/Settings/SettingsPage'))

// Notifications
const NotificationPage = lazy(() => import('@/pages/Notifications/NotificationPage'))

// Approvals
const ApprovalPage = lazy(() => import('@/pages/Approvals/ApprovalPage'))

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

      // ── Curriculum ─────────────────────────────────────────────────────────
      { path: 'curriculum',                           element: <S><CurriculumPage /></S> },
      { path: 'curriculum/new',                       element: <S><CourseFormPage /></S> },
      { path: 'curriculum/:courseId',                 element: <S><CourseDashboardPage /></S> },
      { path: 'curriculum/:courseId/edit',            element: <S><CourseFormPage /></S> },
      { path: 'curriculum/:courseId/versions',        element: <S><CourseVersionPage /></S> },
      { path: 'curriculum/:courseId/versions/new',    element: <S><VersionFormPage /></S> },
      { path: 'curriculum/:courseId/versions/:versionId/edit', element: <S><VersionFormPage /></S> },
      { path: 'curriculum/:courseId/versions/:versionId/modules', element: <S><CourseModulePage /></S> },
      { path: 'curriculum/:courseId/internship-config', element: <S><InternshipConfigPage /></S> },
      { path: 'curriculum/:courseId/character-test-config', element: <S><CharacterTestConfigPage /></S> },
      { path: 'curriculum/approvals',                 element: <S><CurriculumApprovalsPage /></S> },

      // ── Course Batches ─────────────────────────────────────────────────────
      { path: 'course-batches',                       element: <S><CourseBatchListPage /></S> },
      { path: 'course-batches/new',                   element: <S><BatchFormPage /></S> },
      { path: 'course-batches/:batchId',              element: <S><CourseBatchDetailPage /></S> },
      { path: 'course-batches/:batchId/edit',         element: <S><BatchFormPage /></S> },

      // ── Enrollment ─────────────────────────────────────────────────────────
      { path: 'enrollments',                          element: <S><EnrollmentListPage /></S> },
      { path: 'enrollments/new',                      element: <S><EnrollmentFormPage /></S> },
      { path: 'enrollments/:enrollmentId',            element: <S><EnrollmentFormPage /></S> },

      // ── Students ───────────────────────────────────────────────────────────
      { path: 'students',                             element: <S><StudentListPage /></S> },
      { path: 'students/new',                         element: <S><StudentFormPage /></S> },
      { path: 'students/:studentId',                  element: <S><StudentDashboardPage /></S> },
      { path: 'students/:studentId/edit',             element: <S><StudentFormPage /></S> },

      // ── Talent Pool ────────────────────────────────────────────────────────
      { path: 'talentpool',                           element: <S><TalentPoolPage /></S> },

      // ── Certificates ───────────────────────────────────────────────────────
      { path: 'certificates',                         element: <S><CertificateListPage /></S> },
      { path: 'certificates/issue-participant/:enrollmentId', element: <S><IssueParticipantPage /></S> },
      { path: 'certificates/issue-competency/:enrollmentId',  element: <S><IssueCompetencyPage /></S> },
      { path: 'certificates/templates',               element: <S><CertificateTemplateListPage /></S> },
      { path: 'certificates/templates/new',           element: <S><CertificateTemplateEditorPage /></S> },
      { path: 'certificates/templates/:templateId/edit', element: <S><CertificateTemplateEditorPage /></S> },

      // ── Departments ────────────────────────────────────────────────────────
      { path: 'departments',                          element: <S><DepartmentListPage /></S> },
      { path: 'departments/new',                      element: <S><DepartmentFormPage /></S> },
      { path: 'departments/:deptId',                  element: <S><DepartmentDashboardPage /></S> },
      { path: 'departments/:deptId/edit',             element: <S><DepartmentFormPage /></S> },

      // ── Leads ──────────────────────────────────────────────────────────────
      { path: 'leads',                                element: <S><LeadListPage /></S> },
      { path: 'leads/new',                            element: <S><LeadFormPage /></S> },
      { path: 'leads/:leadId/edit',                   element: <S><LeadFormPage /></S> },

      // ── Locations ──────────────────────────────────────────────────────────
      { path: 'locations',                            element: <S><LocationListPage /></S> },

      // ── Payments ───────────────────────────────────────────────────────────
      { path: 'payments',                             element: <S><PaymentListPage /></S> },

      // ── Marketing ──────────────────────────────────────────────────────────
      { path: 'marketing',                            element: <S><MarketingPage /></S> },
      { path: 'marketing/social/new',                 element: <S><SocialPostFormPage /></S> },
      { path: 'marketing/social/:postId/edit',        element: <S><SocialPostFormPage /></S> },
      { path: 'marketing/pr/new',                     element: <S><PrContentFormPage /></S> },
      { path: 'marketing/pr/:contentId/edit',         element: <S><PrContentFormPage /></S> },
      { path: 'marketing/referral/new',               element: <S><ReferralFormPage /></S> },
      { path: 'marketing/referral/:refId/edit',       element: <S><ReferralFormPage /></S> },

      // ── CRM ────────────────────────────────────────────────────────────────
      { path: 'crm',                                  element: <S><CrmPage /></S> },

      // ── Partners ───────────────────────────────────────────────────────────
      { path: 'partners',                             element: <S><PartnerListPage /></S> },

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
      { path: 'finance/invoices',                     element: <S><InvoiceListPage /></S> },
      { path: 'finance/invoices/new',                 element: <S><ManualInvoiceFormPage /></S> },
      { path: 'finance/invoices/:invoiceId',          element: <S><InvoiceDetailPage /></S> },
      { path: 'finance/payables',                     element: <S><PayableListPage /></S> },
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
      { path: 'hrm/leaves',                           element: <S><LeaveRequestsPage /></S> },
      { path: 'hrm/payroll',                          element: <S><PayrollPeriodsPage /></S> },
      { path: 'hrm/payroll/:periodId',                element: <S><PayrollDetailPage /></S> },

      // ── Projects ───────────────────────────────────────────────────────────
      { path: 'projects',                             element: <S><ProjectListPage /></S> },

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

      // ── CMS ────────────────────────────────────────────────────────────────
      { path: 'cms',                                  element: <S><CmsPage /></S> },
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

      // ── Notifications ──────────────────────────────────────────────────────
      { path: 'notifications',                        element: <S><NotificationPage /></S> },

      // ── Settings ───────────────────────────────────────────────────────────
      { path: 'settings',                             element: <S><SettingsPage /></S> },
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
