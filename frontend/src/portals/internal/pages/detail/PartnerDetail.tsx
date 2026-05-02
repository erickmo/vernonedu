import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Handshake, Pencil, Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import DetailPageLayout, { type BreadcrumbItem, type DetailTab } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import MouSection from '@/portals/internal/components/partners/MouSection'
import { usePartner, useDeletePartner } from '@/lib/api/partner'

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'mous', label: 'MOUs' },
]

export default function PartnerDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = usePartner(id)
  const del = useDeletePartner()
  const [tab, setTab] = useState('overview')
  const [confirmDelete, setConfirmDelete] = useState(false)

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Partners', to: '/internal/partners' },
    { label: data.name },
  ]

  async function handleDelete() {
    try {
      await del.mutateAsync(id)
      toast.success('Partner deleted')
      navigate('/internal/partners')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to delete partner')
    } finally {
      setConfirmDelete(false)
    }
  }

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<Handshake className="w-5 h-5 text-brand-600" />}
      title={data.name}
      subtitle={`${data.type} · ${data.contact_email || '—'}`}
      status={<StatusBadge status={data.status} />}
      actions={
        <div className="flex gap-2">
          <RoleGate action="update" resource="mou">
            <Button onClick={() => navigate(`/internal/partners/${id}/edit`)}>
              <Pencil className="w-4 h-4" /> Edit
            </Button>
          </RoleGate>
          <RoleGate action="delete" resource="mou">
            <Button variant="danger" onClick={() => setConfirmDelete(true)}>
              <Trash2 className="w-4 h-4" /> Delete
            </Button>
          </RoleGate>
        </div>
      }
      tabs={TABS}
      activeTab={tab}
      onTabChange={(v) => {
        if (v === 'overview' || v === 'mous') setTab(v)
      }}
    >
      {tab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Type</p>
            <p className="text-sm font-semibold capitalize">{data.type}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Contact</p>
            <p className="text-sm font-semibold">{data.contact_name || '—'}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Phone</p>
            <p className="text-sm">{data.contact_phone || '—'}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Email</p>
            <p className="text-sm break-all">{data.contact_email || '—'}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4 col-span-2 md:col-span-4">
            <p className="text-xs text-neutral-400 mb-1">Address</p>
            <p className="text-sm">{data.address || '—'}</p>
          </div>
          {data.notes && (
            <div className="bg-white rounded-xl border border-neutral-100 p-4 col-span-2 md:col-span-4">
              <p className="text-xs text-neutral-400 mb-1">Notes</p>
              <p className="text-sm whitespace-pre-wrap">{data.notes}</p>
            </div>
          )}
        </div>
      )}

      {tab === 'mous' && <MouSection partnerId={id} />}

      <ConfirmDialog
        open={confirmDelete}
        title="Delete partner?"
        description={`Are you sure you want to delete "${data.name}"?`}
        confirmLabel="Delete"
        destructive
        onConfirm={handleDelete}
        onCancel={() => setConfirmDelete(false)}
      />
    </DetailPageLayout>
  )
}
