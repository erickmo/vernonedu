import { useNavigate, useParams } from 'react-router-dom'
import { Edit, TrendingUp } from 'lucide-react'
import DetailPageLayout, { type BreadcrumbItem } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import { useInvestment } from '@/lib/api/investment'

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(amount)
}

export default function InvestmentDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useInvestment(id)

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Investments', to: '/internal/investments' },
    { label: data.title },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<TrendingUp className="w-5 h-5 text-brand-600" />}
      title={data.title}
      subtitle={`${data.category} · proposed by ${data.proposed_by}`}
      status={<StatusBadge status={data.status} />}
      actions={
        <RoleGate action="update" resource="investment_plan">
          <Button onClick={() => navigate(`/internal/investments/${id}/edit`)}>
            <Edit className="w-4 h-4" /> Edit
          </Button>
        </RoleGate>
      }
      tabs={[{ value: 'overview', label: 'Overview' }]}
      activeTab="overview"
      onTabChange={() => {}}
    >
      <div className="max-w-3xl space-y-6">
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white border border-neutral-100 rounded-xl p-4">
            <div className="text-xs font-semibold text-neutral-500 uppercase mb-1">Amount</div>
            <div className="text-lg font-semibold text-neutral-900">{formatCurrency(data.amount)}</div>
          </div>
          <div className="bg-white border border-neutral-100 rounded-xl p-4">
            <div className="text-xs font-semibold text-neutral-500 uppercase mb-1">Expected ROI</div>
            <div className="text-lg font-semibold text-neutral-900">{data.expected_roi}%</div>
          </div>
          {data.actual_roi !== undefined && (
            <div className="bg-white border border-neutral-100 rounded-xl p-4 col-span-2">
              <div className="text-xs font-semibold text-neutral-500 uppercase mb-1">Actual ROI</div>
              <div className="text-lg font-semibold text-neutral-900">{data.actual_roi}%</div>
            </div>
          )}
        </div>

        <section>
          <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Notes</h3>
          <p className="text-sm text-neutral-700 whitespace-pre-wrap">{data.notes || '—'}</p>
        </section>
      </div>
    </DetailPageLayout>
  )
}
