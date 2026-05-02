import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { CheckCircle, ClipboardCheck, PlayCircle, XCircle } from 'lucide-react'
import { toast } from 'sonner'
import DetailPageLayout, { type BreadcrumbItem } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  useDelegation, useAcceptDelegation, useCompleteDelegation, useCancelDelegation,
} from '@/lib/api/delegation'

type Action = 'accept' | 'complete' | 'cancel' | null

export default function DelegationDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useDelegation(id)
  const accept = useAcceptDelegation(id)
  const complete = useCompleteDelegation(id)
  const cancel = useCancelDelegation(id)
  const [pendingAction, setPendingAction] = useState<Action>(null)

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Delegations', to: '/internal/delegations' },
    { label: data.title },
  ]

  async function runAction() {
    if (!pendingAction) return
    const fn = pendingAction === 'accept' ? accept
      : pendingAction === 'complete' ? complete
      : cancel
    try {
      await fn.mutateAsync({ notes: '' })
      toast.success(`Delegation ${pendingAction}ed`)
      setPendingAction(null)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? `Failed to ${pendingAction}`)
    }
  }

  const canAccept = data.status === 'pending'
  const canComplete = data.status === 'accepted' || data.status === 'in_progress'
  const canCancel = data.status === 'pending' || data.status === 'accepted' || data.status === 'in_progress'

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<ClipboardCheck className="w-5 h-5 text-brand-600" />}
      title={data.title}
      subtitle={`${data.type} · priority ${data.priority}`}
      status={<StatusBadge status={data.status} />}
      actions={
        <div className="flex gap-2">
          {canAccept && (
            <RoleGate action="update" resource="delegation">
              <Button variant="secondary" onClick={() => setPendingAction('accept')}>
                <PlayCircle className="w-4 h-4" /> Accept
              </Button>
            </RoleGate>
          )}
          {canComplete && (
            <RoleGate action="update" resource="delegation">
              <Button onClick={() => setPendingAction('complete')}>
                <CheckCircle className="w-4 h-4" /> Complete
              </Button>
            </RoleGate>
          )}
          {canCancel && (
            <RoleGate action="update" resource="delegation">
              <Button variant="secondary" onClick={() => setPendingAction('cancel')}>
                <XCircle className="w-4 h-4" /> Cancel
              </Button>
            </RoleGate>
          )}
        </div>
      }
      tabs={[{ value: 'overview', label: 'Overview' }]}
      activeTab="overview"
      onTabChange={() => {}}
    >
      <div className="max-w-3xl space-y-6">
        <section className="grid grid-cols-2 gap-4">
          <Field label="Requested By" value={data.requested_by_name} />
          <Field label="Assigned To" value={`${data.assigned_to_name}${data.assigned_to_role ? ` (${data.assigned_to_role})` : ''}`} />
          {data.due_date && <Field label="Due Date" value={new Date(data.due_date).toLocaleDateString()} />}
          {data.linked_entity_type && (
            <Field label="Linked" value={`${data.linked_entity_type} · ${data.linked_entity_id ?? ''}`} />
          )}
        </section>

        <section>
          <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Description</h3>
          <p className="text-sm text-neutral-700 whitespace-pre-wrap">{data.description || '—'}</p>
        </section>

        <section>
          <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Notes</h3>
          <p className="text-sm text-neutral-700 whitespace-pre-wrap">{data.notes || '—'}</p>
        </section>

        <div className="pt-4">
          <Button variant="secondary" onClick={() => navigate('/internal/delegations')}>Back to list</Button>
        </div>
      </div>

      <ConfirmDialog
        open={pendingAction !== null}
        title={`${pendingAction ?? ''} delegation?`.replace(/^./, (c) => c.toUpperCase())}
        description={`Confirm to ${pendingAction} this delegation.`}
        confirmLabel={pendingAction ?? 'Confirm'}
        destructive={pendingAction === 'cancel'}
        onConfirm={runAction}
        onCancel={() => setPendingAction(null)}
      />
    </DetailPageLayout>
  )
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-white border border-neutral-100 rounded-xl p-3">
      <div className="text-xs font-semibold text-neutral-500 uppercase mb-0.5">{label}</div>
      <div className="text-sm text-neutral-900">{value}</div>
    </div>
  )
}
