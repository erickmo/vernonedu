import { useNavigate } from 'react-router-dom'
import { CreditCard, PiggyBank, TrendingUp, Tag, DollarSign } from 'lucide-react'
import { useInvoices } from '@/lib/api/finance'
import { useVouchers } from '@/lib/api/businessops'

const QUICK_ACCESS = [
  { label: 'Payments', to: '/internal/payments', icon: CreditCard, description: 'Payment records & invoices' },
  { label: 'Budget', to: '/internal/budget', icon: PiggyBank, description: 'Budget tracking per batch' },
  { label: 'Profit Split', to: '/internal/profit-split', icon: TrendingUp, description: 'Revenue distribution' },
  { label: 'Vouchers', to: '/internal/vouchers', icon: Tag, description: 'Discount voucher management' },
] as const

export default function FinanceOverview() {
  const navigate = useNavigate()
  const { data: invoicesData } = useInvoices({})
  const { data: vouchersData } = useVouchers()

  const pendingCount = invoicesData?.data?.filter((i) => i.status === 'sent')?.length ?? '—'
  const activeVouchers = Array.isArray(vouchersData)
    ? vouchersData.filter((v) => v.is_active).length
    : '—'

  const kpis = [
    { label: 'Total Invoices', value: invoicesData?.total ?? '—', sub: 'all time', color: 'text-brand-600' },
    { label: 'Pending Payments', value: pendingCount, sub: 'awaiting confirmation', color: 'text-amber-600' },
    { label: 'Active Vouchers', value: activeVouchers, sub: 'currently valid', color: 'text-emerald-600' },
    { label: 'Budget Items', value: '—', sub: 'track in batch detail', color: 'text-violet-600' },
  ]

  return (
    <div>
      <div className="mb-6">
        <div className="flex items-center gap-2 mb-1">
          <DollarSign className="w-5 h-5 text-brand-600" />
          <h1 className="text-xl font-bold text-neutral-900">Finance</h1>
        </div>
        <p className="text-sm text-neutral-500">Payments, budget tracking, profit distribution, and vouchers</p>
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
