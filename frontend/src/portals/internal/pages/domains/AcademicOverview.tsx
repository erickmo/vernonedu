import { useNavigate } from 'react-router-dom'
import { BookOpen, Users, FileText, Calendar, GraduationCap, Award } from 'lucide-react'
import { useCourses } from '@/lib/api/catalog'
import { useEnrollments } from '@/lib/api/enrollment'
import { useFacilitatorProposals } from '@/lib/api/identity'
import { useCalendarEvents } from '@/lib/api/businessops'

const QUICK_ACCESS = [
  { label: 'Courses', to: '/internal/courses', icon: BookOpen, description: 'Manage course catalog' },
  { label: 'Enrollments', to: '/internal/enrollments', icon: Users, description: 'Track student enrollments' },
  { label: 'Proposals', to: '/internal/proposals', icon: FileText, description: 'Review course proposals' },
  { label: 'Calendar', to: '/internal/calendar', icon: Calendar, description: 'Session schedule & events' },
  { label: 'Certificate Templates', to: '/internal/certificate-templates', icon: Award, description: 'Global certificate templates' },
] as const

export default function AcademicOverview() {
  const navigate = useNavigate()
  const { data: coursesData } = useCourses({ status: 'published' })
  const { data: enrollmentsData } = useEnrollments({})
  const { data: proposalsData } = useFacilitatorProposals({ status: 'pending' })
  const { data: eventsData } = useCalendarEvents()

  const kpis = [
    { label: 'Active Courses', value: coursesData?.total ?? '—', sub: 'published', color: 'text-brand-600' },
    { label: 'Total Enrollments', value: enrollmentsData?.total ?? '—', sub: 'all time', color: 'text-emerald-600' },
    { label: 'Open Proposals', value: proposalsData?.total ?? '—', sub: 'pending review', color: 'text-amber-600' },
    { label: 'Upcoming Sessions', value: Array.isArray(eventsData) ? eventsData.length : '—', sub: 'scheduled', color: 'text-violet-600' },
  ]

  return (
    <div>
      <div className="mb-6">
        <div className="flex items-center gap-2 mb-1">
          <GraduationCap className="w-5 h-5 text-brand-600" />
          <h1 className="text-xl font-bold text-neutral-900">Academic</h1>
        </div>
        <p className="text-sm text-neutral-500">Courses, enrollments, proposals, and academic calendar</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {kpis.map(kpi => (
          <div key={kpi.label} className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs font-medium text-neutral-500 mb-1">{kpi.label}</p>
            <p className={`text-3xl font-bold ${kpi.color}`}>{kpi.value}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{kpi.sub}</p>
          </div>
        ))}
      </div>

      <p className="text-xs font-semibold text-neutral-400 uppercase tracking-wider mb-3">Quick Access</p>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {QUICK_ACCESS.map(item => (
          <button
            key={item.to}
            onClick={() => navigate(item.to)}
            className="rounded-xl border border-neutral-100 bg-white p-5 text-left hover:border-brand-200 hover:shadow-sm transition-all group"
          >
            <div className="w-10 h-10 rounded-lg bg-brand-50 flex items-center justify-center mb-3 group-hover:bg-brand-100 transition-colors">
              <item.icon className="w-5 h-5 text-brand-600" />
            </div>
            <p className="text-sm font-semibold text-neutral-800">{item.label}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{item.description}</p>
          </button>
        ))}
      </div>
    </div>
  )
}
