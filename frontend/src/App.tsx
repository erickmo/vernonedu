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
import CourseDetail from '@/portals/student/pages/CourseDetail'
import MyEnrollments from '@/portals/student/pages/MyEnrollments'
import Certificates from '@/portals/student/pages/Certificates'
import StudentProfile from '@/portals/student/pages/Profile'
import InternalDashboard from '@/portals/internal/pages/Dashboard'
import Enrollments from '@/portals/internal/pages/Enrollments'
import Payments from '@/portals/internal/pages/Payments'
import Courses from '@/portals/internal/pages/Courses'
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
import FranchiseDashboard from '@/portals/franchise/pages/Dashboard'
import FranchiseRoyalty from '@/portals/franchise/pages/Royalty'
import FranchiseEnrollments from '@/portals/franchise/pages/Enrollments'
import FranchisePayments from '@/portals/franchise/pages/Payments'
import FranchiseTeamMembers from '@/portals/franchise/pages/TeamMembers'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

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
          <Route path="courses/:id" element={<CourseDetail />} />
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

      <Route element={<ProtectedRoute allowedRoles={['ceo', 'admin', 'vernonedu_admin', 'finance', 'academic_leader', 'dept_leader', 'course_creator', 'facilitator']} />}>
        <Route path="/internal" element={<InternalPortal />}>
          <Route index element={<InternalDashboard />} />
          <Route path="enrollments" element={<Enrollments />} />
          <Route path="payments" element={<Payments />} />
          <Route path="courses" element={<Courses />} />
          <Route path="students" element={<Students />} />
          <Route path="departments" element={<Departments />} />
          <Route path="team-members" element={<TeamMembers />} />
          <Route path="proposals" element={<Proposals />} />
          <Route path="budget" element={<Budget />} />
          <Route path="profit-split" element={<ProfitSplit />} />
          <Route path="partners" element={<Partners />} />
          <Route path="vouchers" element={<Vouchers />} />
          <Route path="calendar" element={<InternalCalendar />} />
          <Route path="franchises" element={<Franchises />} />
          <Route path="notifications" element={<Notifications />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
