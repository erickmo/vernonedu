import { useNavigate } from 'react-router-dom'
import { Building2, Handshake, Bell, Settings } from 'lucide-react'
import { useFranchises } from '@/lib/api/partnerships'
import { usePartners } from '@/lib/api/partnerships'
import { useUnreadCount } from '@/lib/api/platform'

const QUICK_ACCESS = [
  { label: 'Franchises', to: '/internal/franchises', icon: Building2, description: 'Franchise network management' },
  { label: 'Partners', to: '/internal/partners', icon: Handshake, description: 'Business partner directory' },
  { label: 'Notifications', to: '/internal/notifications', icon: Bell, description: 'Notification templates' },
] as const

export default function OperationsOverview() {
  const navigate = useNavigate()
  const { data: franchisesData } = useFranchises()
  const { data: partnersData } = usePartners({})
  const unreadCount = useUnreadCount()

  const franchiseCount = Array.isArray(franchisesData) ? franchisesData.length : '—'
  const partnerCount = partnersData?.total ?? '—'

  const kpis = [
    { label: 'Active Franchises', value: franchiseCount, sub: 'franchise locations', color: 'text-brand-600' },
    { label: 'Active Partners', value: partnerCount, sub: 'business partners', color: 'text-emerald-600' },
    { label: 'Unread Notifications', value: unreadCount, sub: 'pending', color: 'text-amber-600' },
  ]

  return (
    <div>
      <div className="mb-6">
        <div className="flex items-center gap-2 mb-1">
          <Settings className="w-5 h-5 text-brand-600" />
          <h1 className="text-xl font-bold text-neutral-900">Operations</h1>
        </div>
        <p className="text-sm text-neutral-500">Franchise network, business partners, and notifications</p>
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
