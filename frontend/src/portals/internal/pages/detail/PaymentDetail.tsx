import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { CreditCard } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import { useInvoice } from '@/lib/api/finance'

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'activity', label: 'Activity' },
]

function formatRp(amount: number): string {
  return `Rp ${amount.toLocaleString('id-ID')}`
}

export default function PaymentDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: invoice, isLoading } = useInvoice(id)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-24">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!invoice) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <p className="text-neutral-500">Payment not found.</p>
        <button
          onClick={() => navigate(-1)}
          className="text-sm text-brand-600 hover:underline"
        >
          Go back
        </button>
      </div>
    )
  }

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Finance', to: '/internal/finance' },
    { label: 'Payments', to: '/internal/payments' },
    { label: `Invoice #${id.slice(0, 8)}` },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<CreditCard className="w-5 h-5 text-brand-600" />}
      title={`Invoice #${id.slice(0, 8)}`}
      subtitle={invoice.number}
      status={<StatusBadge status={invoice.status} />}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Total Amount</p>
            <p className="text-xl font-bold text-neutral-900 font-mono">{formatRp(invoice.total)}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Status</p>
            <StatusBadge status={invoice.status} />
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Due Date</p>
            <p className="text-sm font-semibold text-neutral-900">
              {new Date(invoice.due_date).toLocaleDateString('id-ID')}
            </p>
          </div>
        </div>
      )}

      {activeTab !== 'overview' && (
        <div className="py-12 text-center text-neutral-400 text-sm">
          {TABS.find(t => t.value === activeTab)?.label} — coming in next sprint
        </div>
      )}
    </DetailPageLayout>
  )
}
