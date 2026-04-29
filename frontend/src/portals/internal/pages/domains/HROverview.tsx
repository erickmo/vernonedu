import { useNavigate } from 'react-router-dom'
import { GraduationCap, Building, Users, UsersRound } from 'lucide-react'
import { useStudents, useDepartments, useTeamMembers } from '@/lib/api/identity'

const QUICK_ACCESS = [
  { label: 'Students', to: '/internal/students', icon: GraduationCap, description: 'Student records & profiles' },
  { label: 'Departments', to: '/internal/departments', icon: Building, description: 'Department structure' },
  { label: 'Team Members', to: '/internal/team-members', icon: Users, description: 'Staff & facilitators' },
] as const

export default function HROverview() {
  const navigate = useNavigate()
  const { data: studentsData } = useStudents({})
  const { data: departmentsData } = useDepartments()
  const { data: teamData } = useTeamMembers({})

  const deptCount = Array.isArray(departmentsData) ? departmentsData.length : '—'

  const kpis = [
    { label: 'Total Students', value: studentsData?.total ?? '—', sub: 'registered', color: 'text-brand-600' },
    { label: 'Departments', value: deptCount, sub: 'active units', color: 'text-emerald-600' },
    { label: 'Team Members', value: teamData?.total ?? '—', sub: 'staff & facilitators', color: 'text-violet-600' },
  ]

  return (
    <div>
      <div className="mb-6">
        <div className="flex items-center gap-2 mb-1">
          <UsersRound className="w-5 h-5 text-brand-600" />
          <h1 className="text-xl font-bold text-neutral-900">HR</h1>
        </div>
        <p className="text-sm text-neutral-500">Students, departments, and team member management</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        {kpis.map(kpi => (
          <div key={kpi.label} className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs font-medium text-neutral-500 mb-1">{kpi.label}</p>
            <p className={`text-3xl font-bold ${kpi.color}`}>{kpi.value}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{kpi.sub}</p>
          </div>
        ))}
      </div>

      <p className="text-xs font-semibold text-neutral-400 uppercase tracking-wider mb-3">Quick Access</p>
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
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
