import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Handshake, Pencil } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import Button from '@/components/ui/Button'
import { usePartner } from '@/lib/api/partnerships'

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'courses', label: 'Courses' },
  { value: 'revenue', label: 'Revenue' },
  { value: 'activity', label: 'Activity' },
]

export default function PartnerDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: partner, isLoading } = usePartner(id)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-24">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!partner) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <p className="text-neutral-500">Partner not found.</p>
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
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Partners', to: '/internal/partners' },
    { label: partner.name },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<Handshake className="w-5 h-5 text-brand-600" />}
      title={partner.name}
      subtitle={`${partner.type} · ${partner.contact_email}`}
      status={<StatusBadge status={partner.status} />}
      actions={
        <Button variant="primary" onClick={() => navigate(`/internal/partners/${id}/edit`)}>
          <Pencil className="w-4 h-4" />
          Edit
        </Button>
      }
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Type</p>
            <p className="text-sm font-semibold text-neutral-900 capitalize">{partner.type}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Contact</p>
            <p className="text-sm font-semibold text-neutral-900">{partner.contact_name}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Phone</p>
            <p className="text-sm text-neutral-700">{partner.contact_phone}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Status</p>
            <StatusBadge status={partner.status} />
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
