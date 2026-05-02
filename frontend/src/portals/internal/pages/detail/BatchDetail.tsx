import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Calendar, Edit, UserPlus, Lock } from 'lucide-react'
import { toast } from 'sonner'
import DetailPageLayout, { type DetailTab, type BreadcrumbItem } from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import AssignFacilitatorDialog from '@/portals/internal/components/operations/AssignFacilitatorDialog'
import {
  useCourseBatch,
  useCourseBatchDetail,
  useBatchSchedules,
  useUpdateCourseBatch,
} from '@/lib/api/coursebatch'

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'schedule', label: 'Schedule' },
  { value: 'sessions', label: 'Sessions' },
]

const BATCH_COMPLETED_STATUS = 'completed'

function formatDate(s: string | number | undefined): string {
  if (!s) return '—'
  try {
    return new Date(s).toLocaleDateString()
  } catch {
    return String(s)
  }
}

export default function BatchDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: batch, isLoading } = useCourseBatch(id)
  const { data: detail } = useCourseBatchDetail(id)
  const { data: schedules } = useBatchSchedules(id)
  const update = useUpdateCourseBatch(id)
  const [tab, setTab] = useState('overview')
  const [showAssign, setShowAssign] = useState(false)
  const [showClose, setShowClose] = useState(false)

  if (isLoading || !batch) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Batches', to: '/internal/batches' },
    { label: batch.code || batch.name },
  ]

  function handleTabChange(v: string) {
    if (v === 'overview' || v === 'schedule' || v === 'sessions') setTab(v)
  }

  async function onCloseBatch() {
    if (!batch) return
    try {
      await update.mutateAsync({
        code: batch.code ?? '',
        name: batch.name,
        start_date: typeof batch.start_date === 'string' && /^\d{4}-\d{2}-\d{2}/.test(batch.start_date)
          ? batch.start_date.slice(0, 10)
          : new Date(batch.start_date).toISOString().slice(0, 10),
        end_date: typeof batch.end_date === 'string' && /^\d{4}-\d{2}-\d{2}/.test(batch.end_date)
          ? batch.end_date.slice(0, 10)
          : new Date(batch.end_date).toISOString().slice(0, 10),
        min_participants: batch.min_participants ?? 0,
        max_participants: batch.max_participants,
        website_visible: batch.website_visible ?? true,
        is_active: false,
        price: batch.price ?? 0,
        payment_method: (batch.payment_method as any) ?? 'upfront',
        // status hint — backend may use to mark completed
        ...({ status: BATCH_COMPLETED_STATUS } as Record<string, unknown>),
      } as any)
      toast.success('Batch closed')
      setShowClose(false)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to close batch')
    }
  }

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<Calendar className="w-5 h-5 text-brand-600" />}
      title={`${batch.code || '—'} · ${batch.name}`}
      subtitle={`${formatDate(batch.start_date)} → ${formatDate(batch.end_date)}`}
      status={<StatusBadge status={batch.status} variant="batch" />}
      actions={
        <RoleGate action="update" resource="coursebatch">
          <Button onClick={() => navigate(`/internal/batches/${id}/edit`)}>
            <Edit className="w-4 h-4" /> Edit
          </Button>
        </RoleGate>
      }
      tabs={TABS}
      activeTab={tab}
      onTabChange={handleTabChange}
    >
      {tab === 'overview' && (
        <div className="space-y-6 max-w-3xl">
          <section className="grid grid-cols-2 gap-4 bg-white rounded-xl border border-neutral-100 p-5">
            <Field label="Course">
              {detail?.course_name ?? batch.course_id}
            </Field>
            <Field label="Department">
              {detail?.department_name ?? '—'}
            </Field>
            <Field label="Period">
              {formatDate(batch.start_date)} → {formatDate(batch.end_date)}
            </Field>
            <Field label="Participants">
              {batch.enrollment_count ?? detail?.total_enrolled ?? 0} / {batch.max_participants}
              {batch.min_participants ? ` (min ${batch.min_participants})` : ''}
            </Field>
            <Field label="Facilitator">
              {batch.facilitator_name || detail?.facilitator_name || '—'}
            </Field>
            <Field label="Payment Method">
              {String(batch.payment_method ?? '—')}
            </Field>
            <Field label="Price">
              {batch.price ? `Rp ${batch.price.toLocaleString('id-ID')}` : '—'}
            </Field>
            <Field label="Website Visible">
              {batch.website_visible ? 'Yes' : 'No'}
            </Field>
          </section>

          <section className="flex items-center gap-2">
            <RoleGate action="update" resource="coursebatch">
              <Button variant="secondary" onClick={() => setShowAssign(true)}>
                <UserPlus className="w-4 h-4" /> Assign Facilitator
              </Button>
            </RoleGate>
            <RoleGate action="update" resource="coursebatch">
              {batch.status !== BATCH_COMPLETED_STATUS && (
                <Button variant="danger" onClick={() => setShowClose(true)}>
                  <Lock className="w-4 h-4" /> Close Batch
                </Button>
              )}
            </RoleGate>
          </section>
        </div>
      )}

      {tab === 'schedule' && (
        <div className="max-w-3xl bg-white rounded-xl border border-neutral-100 p-5">
          {!schedules || schedules.length === 0 ? (
            <p className="text-sm text-neutral-400">No schedules yet.</p>
          ) : (
            <ul className="divide-y divide-neutral-100">
              {schedules.map((s) => (
                <li key={s.id} className="py-3 flex items-center justify-between text-sm">
                  <div>
                    <div className="font-medium text-neutral-800">
                      {formatDate(s.scheduled_at)} · {s.duration_minutes}min
                    </div>
                    <div className="text-xs text-neutral-500 font-mono">
                      module: {s.module_id ?? '—'} · room: {s.room_id ?? '—'}
                    </div>
                  </div>
                  <StatusBadge status={s.status} />
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      {tab === 'sessions' && (
        <div className="max-w-3xl bg-white rounded-xl border border-neutral-100 p-5 text-sm text-neutral-500">
          Sessions tab coming soon.
        </div>
      )}

      <AssignFacilitatorDialog
        open={showAssign}
        batchId={id}
        initialFacilitatorId={batch.facilitator_id}
        onClose={() => setShowAssign(false)}
      />

      <ConfirmDialog
        open={showClose}
        title="Close this batch?"
        description="Closing marks the batch completed and inactive. This may trigger commission payouts."
        confirmLabel="Close Batch"
        destructive
        onConfirm={onCloseBatch}
        onCancel={() => setShowClose(false)}
      />
    </DetailPageLayout>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <div className="text-xs font-semibold text-neutral-500 uppercase mb-0.5">{label}</div>
      <div className="text-sm text-neutral-800">{children}</div>
    </div>
  )
}
