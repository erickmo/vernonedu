import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Building2, Edit } from 'lucide-react'
import DetailPageLayout, { type DetailTab, type BreadcrumbItem } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import { useBuilding } from '@/lib/api/location'
import RoomsSection from '@/portals/internal/components/location/RoomsSection'

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'rooms', label: 'Rooms' },
]

export default function BuildingDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useBuilding(id)
  const [tab, setTab] = useState('overview')

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Buildings', to: '/internal/buildings' },
    { label: data.name },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<Building2 className="w-5 h-5 text-brand-600" />}
      title={data.name}
      subtitle={data.address || '—'}
      actions={
        <RoleGate action="update" resource="building">
          <Button onClick={() => navigate(`/internal/buildings/${id}/edit`)}>
            <Edit className="w-4 h-4" /> Edit
          </Button>
        </RoleGate>
      }
      tabs={TABS}
      activeTab={tab}
      onTabChange={(v) => {
        if (v === 'overview' || v === 'rooms') setTab(v)
      }}
    >
      {tab === 'overview' && (
        <div className="space-y-6 max-w-3xl">
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Address</h3>
            <p className="text-sm text-neutral-700 whitespace-pre-wrap">
              {data.address || '—'}
            </p>
          </section>
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Description</h3>
            <p className="text-sm text-neutral-700 whitespace-pre-wrap">
              {data.description || '—'}
            </p>
          </section>
          <section className="pt-4 border-t border-neutral-100 text-xs text-neutral-500">
            Created: {new Date(data.created_at).toLocaleDateString()} ·
            Updated: {new Date(data.updated_at).toLocaleDateString()}
          </section>
        </div>
      )}
      {tab === 'rooms' && <RoomsSection buildingId={id} />}
    </DetailPageLayout>
  )
}
