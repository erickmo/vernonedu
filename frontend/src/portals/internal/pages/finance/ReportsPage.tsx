import { FileText, TrendingUp, DollarSign, BookOpen, Scale } from 'lucide-react'
import { Link } from 'react-router-dom'

const REPORTS = [
  { label: 'Balance Sheet', to: '/internal/finance/reports/balance-sheet', icon: Scale, description: 'Assets, liabilities, equity snapshot' },
  { label: 'Profit & Loss', to: '/internal/finance/reports/profit-loss', icon: TrendingUp, description: 'Revenue, costs, net profit' },
  { label: 'Cash Flow', to: '/internal/finance/reports/cash-flow', icon: DollarSign, description: 'Cash inflows and outflows' },
  { label: 'General Ledger', to: '/internal/finance/reports/ledger', icon: BookOpen, description: 'All journal entries' },
  { label: 'Trial Balance', to: '/internal/finance/reports/trial-balance', icon: FileText, description: 'Debit and credit verification' },
]

export default function FinanceReportsPage() {
  return (
    <div>
      <div className="mb-6">
        <div className="flex items-center gap-2 mb-1">
          <FileText className="w-5 h-5 text-brand-600" />
          <h1 className="text-xl font-bold text-neutral-900">Financial Reports</h1>
        </div>
        <p className="text-sm text-neutral-500">Generate and view financial statements</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {REPORTS.map(report => (
          <Link
            key={report.to}
            to={report.to}
            className="rounded-xl border border-neutral-100 bg-white p-6 text-left hover:border-brand-200 hover:shadow-sm transition-all group"
          >
            <div className="w-12 h-12 rounded-lg bg-brand-50 flex items-center justify-center mb-4 group-hover:bg-brand-100 transition-colors">
              <report.icon className="w-6 h-6 text-brand-600" />
            </div>
            <p className="text-base font-semibold text-neutral-800">{report.label}</p>
            <p className="text-sm text-neutral-400 mt-1">{report.description}</p>
          </Link>
        ))}
      </div>
    </div>
  )
}
