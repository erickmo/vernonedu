import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { Tag } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'

interface VoucherData {
  id: string
  code: string
  discount_pct: number
  status: string
}

function useVoucherDetail(id: string): { data: VoucherData; isLoading: false } {
  return {
    data: {
      id,
      code: id?.slice(0, 8).toUpperCase(),
      discount_pct: 0,
      status: 'active',
    },
    isLoading: false,
  }
}

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'usage-history', label: 'Usage History' },
  { value: 'activity', label: 'Activity' },
]

export default function VoucherDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: voucher } = useVoucherDetail(id)

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Finance', to: '/internal/finance' },
    { label: 'Vouchers', to: '/internal/vouchers' },
    { label: `Voucher ${id?.slice(0, 8)}` },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<Tag className="w-5 h-5 text-brand-600" />}
      title={`Voucher ${id?.slice(0, 8)}`}
      status={<StatusBadge status={voucher.status} />}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Code</p>
            <p className="text-sm font-bold font-mono text-neutral-900">{voucher.code}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Discount</p>
            <p className="text-xl font-bold text-neutral-900">{voucher.discount_pct}%</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Status</p>
            <StatusBadge status={voucher.status} />
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
