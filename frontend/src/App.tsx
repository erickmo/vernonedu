import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import ProtectedRoute from '@/lib/auth/ProtectedRoute'
import StudentPortal from '@/portals/student/StudentPortal'
import FranchisePortal from '@/portals/franchise/FranchisePortal'
import InternalPortal from '@/portals/internal/InternalPortal'
import Login from '@/pages/Login'
import Register from '@/pages/Register'
import CertificateVerify from '@/pages/CertificateVerify'
import StudentDashboard from '@/portals/student/pages/Dashboard'
import CourseCatalog from '@/portals/student/pages/CourseCatalog'
import StudentCourseDetail from '@/portals/student/pages/CourseDetail'
import MyEnrollments from '@/portals/student/pages/MyEnrollments'
import Certificates from '@/portals/student/pages/Certificates'
import StudentProfile from '@/portals/student/pages/Profile'
import InternalDashboard from '@/portals/internal/pages/Dashboard'
import Enrollments from '@/portals/internal/pages/Enrollments'
import EnrollmentCreatePage from '@/portals/internal/pages/EnrollmentCreatePage'
import EnrollmentEditPage from '@/portals/internal/pages/EnrollmentEditPage'
import Payments from '@/portals/internal/pages/Payments'
import Invoices from '@/portals/internal/pages/Invoices'
import InvoiceCreatePage from '@/portals/internal/pages/InvoiceCreatePage'
import InvoiceDetail from '@/portals/internal/pages/detail/InvoiceDetail'
import Courses from '@/portals/internal/pages/Courses'
import CourseCreatePage from '@/portals/internal/pages/CourseCreatePage'
import CourseEditPage from '@/portals/internal/pages/CourseEditPage'
import CertificateTemplates from '@/portals/internal/pages/CertificateTemplates'
import Holidays from '@/portals/internal/pages/Holidays'
import CertificateTemplateCreatePage from '@/portals/internal/pages/CertificateTemplateCreatePage'
import CertificateTemplateEditPage from '@/portals/internal/pages/CertificateTemplateEditPage'
import InternalCertificates from '@/portals/internal/pages/Certificates'
import CertificateIssuePage from '@/portals/internal/pages/CertificateIssuePage'
import CertificateDetail from '@/portals/internal/pages/detail/CertificateDetail'
import Students from '@/portals/internal/pages/Students'
import Departments from '@/portals/internal/pages/Departments'
import TeamMembers from '@/portals/internal/pages/TeamMembers'
import Proposals from '@/portals/internal/pages/Proposals'
import Budget from '@/portals/internal/pages/Budget'
import ProfitSplit from '@/portals/internal/pages/ProfitSplit'
import Partners from '@/portals/internal/pages/Partners'
import Vouchers from '@/portals/internal/pages/Vouchers'
import InternalCalendar from '@/portals/internal/pages/Calendar'
import Franchises from '@/portals/internal/pages/Franchises'
import Notifications from '@/portals/internal/pages/Notifications'
// Domain overviews
import AcademicOverview from '@/portals/internal/pages/domains/AcademicOverview'
import FinanceOverview from '@/portals/internal/pages/domains/FinanceOverview'
// Finance reports + analysis
import BalanceSheet from '@/portals/internal/pages/finance/reports/BalanceSheet'
import ProfitLoss from '@/portals/internal/pages/finance/reports/ProfitLoss'
import CashFlow from '@/portals/internal/pages/finance/reports/CashFlow'
import GeneralLedger from '@/portals/internal/pages/finance/reports/GeneralLedger'
import TrialBalance from '@/portals/internal/pages/finance/reports/TrialBalance'
import FinanceAnalysis from '@/portals/internal/pages/finance/Analysis'
import FinanceCommissions from '@/portals/internal/pages/finance/Commissions'
import FinanceBudgetVsActual from '@/portals/internal/pages/finance/BudgetVsActual'
import OperationsOverview from '@/portals/internal/pages/domains/OperationsOverview'
import HROverview from '@/portals/internal/pages/domains/HROverview'
// Entity detail pages
import CourseDetail from '@/portals/internal/pages/detail/CourseDetail'
import StudentDetail from '@/portals/internal/pages/detail/StudentDetail'
import EnrollmentDetail from '@/portals/internal/pages/detail/EnrollmentDetail'
import DepartmentDetail from '@/portals/internal/pages/detail/DepartmentDetail'
import TeamMemberDetail from '@/portals/internal/pages/detail/TeamMemberDetail'
import ProposalDetail from '@/portals/internal/pages/detail/ProposalDetail'
import PartnerDetail from '@/portals/internal/pages/detail/PartnerDetail'
import PartnerCreatePage from '@/portals/internal/pages/PartnerCreatePage'
import PartnerEditPage from '@/portals/internal/pages/PartnerEditPage'
import Approvals from '@/portals/internal/pages/Approvals'
import ApprovalDetail from '@/portals/internal/pages/ApprovalDetail'
import Branches from '@/portals/internal/pages/Branches'
import BranchCreatePage from '@/portals/internal/pages/BranchCreatePage'
import BranchEditPage from '@/portals/internal/pages/BranchEditPage'
import Projects from '@/portals/internal/pages/Projects'
import ProjectCreatePage from '@/portals/internal/pages/ProjectCreatePage'
import ProjectEditPage from '@/portals/internal/pages/ProjectEditPage'
import ProjectDetail from '@/portals/internal/pages/detail/ProjectDetail'
import Batches from '@/portals/internal/pages/Batches'
import BatchCreatePage from '@/portals/internal/pages/BatchCreatePage'
import BatchEditPage from '@/portals/internal/pages/BatchEditPage'
import BatchDetail from '@/portals/internal/pages/detail/BatchDetail'
import AttendancePage from '@/portals/internal/pages/AttendancePage'
import MySessions from '@/portals/internal/pages/MySessions'
import Buildings from '@/portals/internal/pages/Buildings'
import Leads from '@/portals/internal/pages/Leads'
import LeadCreatePage from '@/portals/internal/pages/LeadCreatePage'
import LeadEditPage from '@/portals/internal/pages/LeadEditPage'
import LeadDetail from '@/portals/internal/pages/detail/LeadDetail'
import BuildingCreatePage from '@/portals/internal/pages/BuildingCreatePage'
import BuildingEditPage from '@/portals/internal/pages/BuildingEditPage'
import BuildingDetail from '@/portals/internal/pages/detail/BuildingDetail'
import FranchiseDetail from '@/portals/internal/pages/detail/FranchiseDetail'
import VoucherDetail from '@/portals/internal/pages/detail/VoucherDetail'
import PaymentDetail from '@/portals/internal/pages/detail/PaymentDetail'
import BudgetDetail from '@/portals/internal/pages/detail/BudgetDetail'
import ProfitSplitDetail from '@/portals/internal/pages/detail/ProfitSplitDetail'
import NotificationDetail from '@/portals/internal/pages/detail/NotificationDetail'
import FranchiseDashboard from '@/portals/franchise/pages/Dashboard'
import FranchiseRoyalty from '@/portals/franchise/pages/Royalty'
import FranchiseEnrollments from '@/portals/franchise/pages/Enrollments'
import FranchisePayments from '@/portals/franchise/pages/Payments'
import FranchiseTeamMembers from '@/portals/franchise/pages/TeamMembers'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
// BizDev pages
import BMC from '@/portals/internal/pages/bizdev/BMC'
import OKR from '@/portals/internal/pages/bizdev/OKR'
import Investments from '@/portals/internal/pages/bizdev/Investments'
import InvestmentCreatePage from '@/portals/internal/pages/bizdev/InvestmentCreatePage'
import InvestmentEditPage from '@/portals/internal/pages/bizdev/InvestmentEditPage'
import InvestmentDetail from '@/portals/internal/pages/bizdev/InvestmentDetail'
import Delegations from '@/portals/internal/pages/bizdev/Delegations'
import DelegationCreatePage from '@/portals/internal/pages/bizdev/DelegationCreatePage'
import DelegationDetail from '@/portals/internal/pages/bizdev/DelegationDetail'
// CMS pages
import CmsPagesList from '@/portals/internal/pages/cms/Pages'
import CmsArticles from '@/portals/internal/pages/cms/Articles'
import CmsArticleCreatePage from '@/portals/internal/pages/cms/ArticleCreatePage'
import CmsArticleEditPage from '@/portals/internal/pages/cms/ArticleEditPage'
import CmsFAQ from '@/portals/internal/pages/cms/FAQ'
import CmsTestimonials from '@/portals/internal/pages/cms/Testimonials'
import CmsMedia from '@/portals/internal/pages/cms/Media'
// Marketing pages
import MarketingPostsList from '@/portals/internal/pages/marketing/MarketingPosts'
import MarketingPostCreatePage from '@/portals/internal/pages/marketing/MarketingPostCreatePage'
import MarketingPostEditPage from '@/portals/internal/pages/marketing/MarketingPostEditPage'
import ClassDocPostsList from '@/portals/internal/pages/marketing/ClassDocPosts'
import ReferralPartnersList from '@/portals/internal/pages/marketing/ReferralPartners'
// Admin pages
import { AdminLayout } from '@/pages/admin/AdminLayout'
import DepartmentListPage from '@/pages/admin/DepartmentListPage'
import DepartmentCreatePage from '@/pages/admin/DepartmentCreatePage'
import DepartmentDetailPage from '@/pages/admin/DepartmentDetailPage'

const ROLE_STUDENT = 'student'
const ROLE_FRANCHISEE = 'franchisee'

function RoleBasedRedirect() {
  const { user, isLoading } = useAuth()

  if (isLoading) return <LoadingSpinner size="lg" />
  if (!user) return <Navigate to="/login" replace />
  if (user.role === ROLE_STUDENT) return <Navigate to="/student" replace />
  if (user.role === ROLE_FRANCHISEE) return <Navigate to="/franchise" replace />
  return <Navigate to="/internal" replace />
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      <Route path="/verify/:certNumber" element={<CertificateVerify />} />
      <Route path="/" element={<RoleBasedRedirect />} />

      <Route element={<ProtectedRoute allowedRoles={[ROLE_STUDENT]} />}>
        <Route path="/student" element={<StudentPortal />}>
          <Route index element={<StudentDashboard />} />
          <Route path="catalog" element={<CourseCatalog />} />
          <Route path="courses/:id" element={<StudentCourseDetail />} />
          <Route path="enrollments" element={<MyEnrollments />} />
          <Route path="certificates" element={<Certificates />} />
          <Route path="profile" element={<StudentProfile />} />
        </Route>
      </Route>

      <Route element={<ProtectedRoute allowedRoles={[ROLE_FRANCHISEE]} />}>
        <Route path="/franchise" element={<FranchisePortal />}>
          <Route index element={<FranchiseDashboard />} />
          <Route path="royalty" element={<FranchiseRoyalty />} />
          <Route path="enrollments" element={<FranchiseEnrollments />} />
          <Route path="payments" element={<FranchisePayments />} />
          <Route path="team" element={<FranchiseTeamMembers />} />
        </Route>
      </Route>

      <Route element={<ProtectedRoute allowedRoles={['ceo', 'admin', 'vernonedu_admin', 'finance', 'academic_leader', 'dept_leader', 'course_creator', 'facilitator', 'marketing', 'operation_leader', 'director', 'education_leader']} />}>
        <Route path="/internal" element={<InternalPortal />}>
          <Route index element={<InternalDashboard />} />
          <Route path="enrollments" element={<Enrollments />} />
          <Route path="enrollments/new" element={<EnrollmentCreatePage />} />
          <Route path="enrollments/:id/edit" element={<EnrollmentEditPage />} />
          <Route path="payments" element={<Payments />} />
          <Route path="invoices" element={<Invoices />} />
          <Route path="invoices/new" element={<InvoiceCreatePage />} />
          <Route path="invoices/:id" element={<InvoiceDetail />} />
          <Route path="courses" element={<Courses />} />
          <Route path="courses/new" element={<CourseCreatePage />} />
          <Route path="courses/:id/edit" element={<CourseEditPage />} />
          <Route path="certificate-templates" element={<CertificateTemplates />} />
          <Route path="certificate-templates/new" element={<CertificateTemplateCreatePage />} />
          <Route path="certificate-templates/:id/edit" element={<CertificateTemplateEditPage />} />
          <Route path="certificates" element={<InternalCertificates />} />
          <Route path="certificates/new" element={<CertificateIssuePage />} />
          <Route path="certificates/:id" element={<CertificateDetail />} />
          <Route path="students" element={<Students />} />
          <Route path="departments" element={<Departments />} />
          <Route path="team-members" element={<TeamMembers />} />
          <Route path="proposals" element={<Proposals />} />
          <Route path="budget" element={<Budget />} />
          <Route path="profit-split" element={<ProfitSplit />} />
          <Route path="partners" element={<Partners />} />
          <Route path="partners/new" element={<PartnerCreatePage />} />
          <Route path="partners/:id/edit" element={<PartnerEditPage />} />
          <Route path="batches" element={<Batches />} />
          <Route path="batches/new" element={<BatchCreatePage />} />
          <Route path="batches/:id" element={<BatchDetail />} />
          <Route path="batches/:id/edit" element={<BatchEditPage />} />
          <Route path="batches/:id/sessions/:sessionId/attendance" element={<AttendancePage />} />
          <Route path="my-sessions" element={<MySessions />} />
          <Route path="buildings" element={<Buildings />} />
          <Route path="buildings/new" element={<BuildingCreatePage />} />
          <Route path="buildings/:id" element={<BuildingDetail />} />
          <Route path="buildings/:id/edit" element={<BuildingEditPage />} />
          <Route path="leads" element={<Leads />} />
          <Route path="leads/new" element={<LeadCreatePage />} />
          <Route path="leads/:id" element={<LeadDetail />} />
          <Route path="leads/:id/edit" element={<LeadEditPage />} />
          <Route path="vouchers" element={<Vouchers />} />
          <Route path="calendar" element={<InternalCalendar />} />
          <Route path="franchises" element={<Franchises />} />
          <Route path="notifications" element={<Notifications />} />
          <Route path="settings/holidays" element={<Holidays />} />
          {/* BizDev */}
          <Route path="bmc" element={<BMC />} />
          <Route path="okr" element={<OKR />} />
          <Route path="investments" element={<Investments />} />
          <Route path="investments/new" element={<InvestmentCreatePage />} />
          <Route path="investments/:id" element={<InvestmentDetail />} />
          <Route path="investments/:id/edit" element={<InvestmentEditPage />} />
          <Route path="delegations" element={<Delegations />} />
          <Route path="delegations/new" element={<DelegationCreatePage />} />
          <Route path="delegations/:id" element={<DelegationDetail />} />
          <Route path="settings/branches" element={<Branches />} />
          <Route path="settings/branches/new" element={<BranchCreatePage />} />
          <Route path="settings/branches/:id/edit" element={<BranchEditPage />} />
          <Route path="approvals" element={<Approvals />} />
          <Route path="approvals/:id" element={<ApprovalDetail />} />
          <Route path="projects" element={<Projects />} />
          <Route path="projects/new" element={<ProjectCreatePage />} />
          <Route path="projects/:id" element={<ProjectDetail />} />
          <Route path="projects/:id/edit" element={<ProjectEditPage />} />
          {/* Domain overviews */}
          <Route path="academic" element={<AcademicOverview />} />
          <Route path="finance" element={<FinanceOverview />} />
          <Route path="finance/reports/balance-sheet" element={<BalanceSheet />} />
          <Route path="finance/reports/profit-loss" element={<ProfitLoss />} />
          <Route path="finance/reports/cash-flow" element={<CashFlow />} />
          <Route path="finance/reports/ledger" element={<GeneralLedger />} />
          <Route path="finance/reports/trial-balance" element={<TrialBalance />} />
          <Route path="finance/analysis" element={<FinanceAnalysis />} />
          <Route path="finance/commissions" element={<FinanceCommissions />} />
          <Route path="finance/budget" element={<FinanceBudgetVsActual />} />
          <Route path="operations" element={<OperationsOverview />} />
          <Route path="hr" element={<HROverview />} />
          {/* Entity detail pages */}
          <Route path="courses/:id" element={<CourseDetail />} />
          <Route path="students/:id" element={<StudentDetail />} />
          <Route path="enrollments/:id" element={<EnrollmentDetail />} />
          <Route path="departments/:id" element={<DepartmentDetail />} />
          <Route path="team-members/:id" element={<TeamMemberDetail />} />
          <Route path="proposals/:id" element={<ProposalDetail />} />
          <Route path="partners/:id" element={<PartnerDetail />} />
          <Route path="franchises/:id" element={<FranchiseDetail />} />
          <Route path="vouchers/:id" element={<VoucherDetail />} />
          <Route path="payments/:id" element={<PaymentDetail />} />
          <Route path="budget/:id" element={<BudgetDetail />} />
          <Route path="profit-split/:id" element={<ProfitSplitDetail />} />
          <Route path="notifications/:id" element={<NotificationDetail />} />
          {/* CMS */}
          <Route path="cms/pages" element={<CmsPagesList />} />
          <Route path="cms/articles" element={<CmsArticles />} />
          <Route path="cms/articles/new" element={<CmsArticleCreatePage />} />
          <Route path="cms/articles/:slug/edit" element={<CmsArticleEditPage />} />
          <Route path="cms/faq" element={<CmsFAQ />} />
          <Route path="cms/testimonials" element={<CmsTestimonials />} />
          <Route path="cms/media" element={<CmsMedia />} />
          {/* Marketing */}
          <Route path="marketing/posts" element={<MarketingPostsList />} />
          <Route path="marketing/posts/new" element={<MarketingPostCreatePage />} />
          <Route path="marketing/posts/:id/edit" element={<MarketingPostEditPage />} />
          <Route path="marketing/class-docs" element={<ClassDocPostsList />} />
          <Route path="marketing/referral-partners" element={<ReferralPartnersList />} />
        </Route>
      </Route>

      {/* Admin Routes */}
      <Route path="/admin" element={<AdminLayout />}>
        <Route index element={<Navigate to="/admin/departments" replace />} />
        <Route path="departments" element={<DepartmentListPage />} />
        <Route path="departments/new" element={<DepartmentCreatePage />} />
        <Route path="departments/:id" element={<DepartmentDetailPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
