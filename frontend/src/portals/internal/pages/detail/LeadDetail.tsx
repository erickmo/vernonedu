import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { UserPlus, Edit, Trash2, ArrowRightCircle } from 'lucide-react'
import { toast } from 'sonner'
import DetailPageLayout, { type DetailTab, type BreadcrumbItem } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import StatusBadge from '@/components/shared/StatusBadge'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import CrmLogList from '@/portals/internal/components/leads/CrmLogList'
import AddCrmLogForm from '@/portals/internal/components/leads/AddCrmLogForm'
import { useLead, useDeleteLead, useConvertLead } from '@/lib/api/lead'

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'crm', label: 'CRM Logs' },
]

export default function LeadDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useLead(id)
  const del = useDeleteLead()
  const convert = useConvertLead()
  const [tab, setTab] = useState('overview')
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [confirmConvert, setConfirmConvert] = useState(false)

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Leads', to: '/internal/leads' },
    { label: data.name },
  ]

  async function handleDelete() {
    try {
      await del.mutateAsync(id)
      toast.success('Lead deleted')
      navigate('/internal/leads')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to delete lead')
    } finally {
      setConfirmDelete(false)
    }
  }

  async function handleConvert() {
    try {
      await convert.mutateAsync(id)
      toast.success('Lead converted to student')
      navigate('/internal/students')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to convert lead')
    } finally {
      setConfirmConvert(false)
    }
  }

  const isConverted = data.status === 'converted'

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<UserPlus className="w-5 h-5 text-brand-600" />}
      title={data.name}
      subtitle={data.interest || '—'}
      status={<StatusBadge status={data.status} />}
      actions={
        <div className="flex gap-2">
          <RoleGate action="update" resource="lead">
            <Button
              variant="secondary"
              onClick={() => setConfirmConvert(true)}
              disabled={isConverted}
            >
              <ArrowRightCircle className="w-4 h-4" /> Convert
            </Button>
          </RoleGate>
          <RoleGate action="update" resource="lead">
            <Button onClick={() => navigate(`/internal/leads/${id}/edit`)}>
              <Edit className="w-4 h-4" /> Edit
            </Button>
          </RoleGate>
          <RoleGate action="delete" resource="lead">
            <Button variant="danger" onClick={() => setConfirmDelete(true)}>
              <Trash2 className="w-4 h-4" /> Delete
            </Button>
          </RoleGate>
        </div>
      }
      tabs={TABS}
      activeTab={tab}
      onTabChange={(v) => {
        if (v === 'overview' || v === 'crm') setTab(v)
      }}
    >
      {tab === 'overview' && (
        <div className="space-y-6 max-w-3xl">
          <div className="grid grid-cols-2 gap-6">
            <section>
              <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Email</h3>
              <p className="text-sm text-neutral-700">{data.email || '—'}</p>
            </section>
            <section>
              <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Phone</h3>
              <p className="text-sm text-neutral-700">{data.phone || '—'}</p>
            </section>
            <section>
              <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Source</h3>
              <p className="text-sm text-neutral-700">{data.source || '—'}</p>
            </section>
            <section>
              <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Interest</h3>
              <p className="text-sm text-neutral-700">{data.interest || '—'}</p>
            </section>
          </div>
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Notes</h3>
            <p className="text-sm text-neutral-700 whitespace-pre-wrap">{data.notes || '—'}</p>
          </section>
          <section className="pt-4 border-t border-neutral-100 text-xs text-neutral-500">
            Created: {new Date(data.created_at).toLocaleDateString()} ·
            Updated: {new Date(data.updated_at).toLocaleDateString()}
          </section>
        </div>
      )}

      {tab === 'crm' && (
        <div className="space-y-4 max-w-3xl">
          <RoleGate action="create" resource="crmlog">
            <AddCrmLogForm leadId={id} />
          </RoleGate>
          <CrmLogList leadId={id} />
        </div>
      )}

      <ConfirmDialog
        open={confirmDelete}
        title="Delete lead?"
        description={`Are you sure you want to delete "${data.name}"? This cannot be undone.`}
        confirmLabel="Delete"
        destructive
        onConfirm={handleDelete}
        onCancel={() => setConfirmDelete(false)}
      />
      <ConfirmDialog
        open={confirmConvert}
        title="Convert lead to student?"
        description={`This will create a student record from "${data.name}" and mark the lead as converted.`}
        confirmLabel="Convert"
        onConfirm={handleConvert}
        onCancel={() => setConfirmConvert(false)}
      />
    </DetailPageLayout>
  )
}
