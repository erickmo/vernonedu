import { useMemo, useState } from 'react'
import * as Dialog from '@radix-ui/react-dialog'
import { ArrowLeft, ArrowRight, CheckCircle2, X, XCircle, Ban } from 'lucide-react'
import { toast } from 'sonner'
import Button from '@/components/ui/Button'
import Textarea from '@/components/ui/Textarea'
import { cn } from '@/lib/utils/cn'
import {
  REASON_MAX_LENGTH,
  REASON_MIN_LENGTH,
  wizardDecisionSchema,
} from '@/schemas/approval'
import type { Approval, ApprovalType } from '@/types/approval'
import {
  useApproveApproval,
  useCancelApproval,
  useRejectApproval,
} from '@/lib/api/approval'
import ApprovalChain, { getChainForType } from './ApprovalChain'

export type WizardMode = 'approve' | 'reject' | 'cancel'

interface ApprovalWizardProps {
  approval: Approval
  mode: WizardMode
  open: boolean
  onClose: () => void
  /** Optional: 0-based index of the current step in a multi-stage chain. */
  currentChainStep?: number
}

const STEPS = ['Review', 'Decision', 'Confirm'] as const
type StepIndex = 0 | 1 | 2

const MODE_META: Record<WizardMode, { title: string; verb: string; icon: typeof CheckCircle2; tone: 'primary' | 'danger' | 'secondary' }> = {
  approve: { title: 'Approve request', verb: 'approve', icon: CheckCircle2, tone: 'primary' },
  reject: { title: 'Reject request', verb: 'reject', icon: XCircle, tone: 'danger' },
  cancel: { title: 'Cancel request', verb: 'cancel', icon: Ban, tone: 'secondary' },
}

const CONSEQUENCES: Partial<Record<ApprovalType, string[]>> = {
  assign_dept_leader: ['User akan diberi role Department Leader', 'Notifikasi dikirim ke user terkait'],
  propose_course: ['Course masuk ke katalog aktif', 'Department Leader dinotifikasi'],
  course_version_change: ['Versi kurikulum baru aktif untuk batch berikutnya'],
  create_batch: ['Batch resmi dibuka', 'Slot enrollment di-publish ke website (jika visible)'],
  batch_pricing_override: ['Harga batch di luar range diaktifkan'],
  batch_capacity_override: ['Min/max student batch diperbarui'],
  schedule_conflict: ['Schedule konflik diizinkan untuk berjalan'],
  revoke_certificate: ['Certificate dicabut', 'QR verification akan menampilkan status revoked', 'Holder dinotifikasi'],
  other: ['Lihat deskripsi pengajuan untuk detail efek'],
}

function getConsequences(approval: Approval, mode: WizardMode): string[] {
  if (mode !== 'approve') {
    return mode === 'reject'
      ? ['Pengajuan ditolak', 'Initiator dinotifikasi dengan alasan']
      : ['Pengajuan dibatalkan oleh initiator', 'Approver dinotifikasi']
  }
  return CONSEQUENCES[approval.type] ?? CONSEQUENCES.other!
}

export default function ApprovalWizard({
  approval,
  mode,
  open,
  onClose,
  currentChainStep = 0,
}: ApprovalWizardProps) {
  const [step, setStep] = useState<StepIndex>(0)
  const [reason, setReason] = useState('')

  const approve = useApproveApproval(approval.id)
  const reject = useRejectApproval(approval.id)
  const cancel = useCancelApproval(approval.id)

  const meta = MODE_META[mode]
  const Icon = meta.icon
  const chain = getChainForType(approval.type)
  const isMultiStage = chain.length > 1

  const reasonValidation = useMemo(
    () => wizardDecisionSchema.safeParse({ reason }),
    [reason],
  )
  const reasonError =
    !reasonValidation.success && reason.length > 0
      ? reasonValidation.error.issues[0].message
      : null

  const consequences = useMemo(() => getConsequences(approval, mode), [approval, mode])

  function reset() {
    setStep(0)
    setReason('')
  }

  function handleClose() {
    reset()
    onClose()
  }

  function goNext() {
    if (step === 1 && !reasonValidation.success) return
    if (step < 2) setStep((step + 1) as StepIndex)
  }

  function goBack() {
    if (step > 0) setStep((step - 1) as StepIndex)
  }

  const mutator = mode === 'approve' ? approve : mode === 'reject' ? reject : cancel
  const submitting = approve.isPending || reject.isPending || cancel.isPending

  async function submit() {
    if (!reasonValidation.success) return
    try {
      await mutator.mutateAsync({ reason: reasonValidation.data.reason })
      toast.success(`Approval ${meta.verb}d`)
      handleClose()
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? `Failed to ${meta.verb}`)
    }
  }

  return (
    <Dialog.Root open={open} onOpenChange={(o) => !o && handleClose()}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50" />
        <Dialog.Content className="fixed left-1/2 top-1/2 z-50 -translate-x-1/2 -translate-y-1/2 w-full max-w-2xl bg-white rounded-xl shadow-xl flex flex-col max-h-[90vh]">
          <header className="flex items-start justify-between gap-4 p-6 border-b border-neutral-100">
            <div className="flex items-center gap-3">
              <div
                className={cn(
                  'w-10 h-10 rounded-full flex items-center justify-center',
                  meta.tone === 'primary' && 'bg-brand-50 text-brand-600',
                  meta.tone === 'danger' && 'bg-red-50 text-red-600',
                  meta.tone === 'secondary' && 'bg-neutral-100 text-neutral-600',
                )}
              >
                <Icon className="w-5 h-5" />
              </div>
              <div>
                <Dialog.Title className="text-base font-semibold text-neutral-900">
                  {meta.title}
                </Dialog.Title>
                <Dialog.Description className="text-xs text-neutral-500">
                  Step {step + 1} of {STEPS.length} · {STEPS[step]}
                </Dialog.Description>
              </div>
            </div>
            <button
              type="button"
              aria-label="Close"
              onClick={handleClose}
              className="text-neutral-400 hover:text-neutral-700"
            >
              <X className="w-5 h-5" />
            </button>
          </header>

          <Stepper current={step} />

          <div className="flex-1 overflow-y-auto p-6">
            {step === 0 && (
              <ReviewStep approval={approval} isMultiStage={isMultiStage} currentChainStep={currentChainStep} />
            )}
            {step === 1 && (
              <DecisionStep
                approval={approval}
                mode={mode}
                reason={reason}
                onReasonChange={setReason}
                error={reasonError}
                isMultiStage={isMultiStage}
                currentChainStep={currentChainStep}
              />
            )}
            {step === 2 && (
              <ConfirmStep
                approval={approval}
                mode={mode}
                reason={reason}
                consequences={consequences}
              />
            )}
          </div>

          <footer className="flex items-center justify-between gap-3 p-4 border-t border-neutral-100 bg-neutral-50 rounded-b-xl">
            <Button
              variant="ghost"
              onClick={step === 0 ? handleClose : goBack}
              disabled={submitting}
            >
              {step === 0 ? 'Cancel' : (<><ArrowLeft className="w-4 h-4" /> Back</>)}
            </Button>
            {step < 2 ? (
              <Button
                variant="primary"
                onClick={goNext}
                disabled={step === 1 && !reasonValidation.success}
              >
                Next <ArrowRight className="w-4 h-4" />
              </Button>
            ) : (
              <Button
                variant={meta.tone === 'danger' ? 'danger' : 'primary'}
                onClick={submit}
                loading={submitting}
                disabled={!reasonValidation.success}
              >
                Submit {meta.verb}
              </Button>
            )}
          </footer>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}

function Stepper({ current }: { current: StepIndex }) {
  return (
    <div className="flex gap-2 px-6 py-3 border-b border-neutral-100">
      {STEPS.map((label, idx) => {
        const active = idx === current
        const done = idx < current
        return (
          <div key={label} className="flex items-center gap-2 flex-1">
            <div
              className={cn(
                'w-7 h-7 rounded-full text-xs font-semibold flex items-center justify-center shrink-0',
                done && 'bg-emerald-500 text-white',
                active && 'bg-brand-600 text-white',
                !done && !active && 'bg-neutral-200 text-neutral-500',
              )}
            >
              {idx + 1}
            </div>
            <span
              className={cn(
                'text-xs',
                active ? 'text-neutral-900 font-medium' : 'text-neutral-500',
              )}
            >
              {label}
            </span>
            {idx < STEPS.length - 1 && (
              <div className={cn('h-px flex-1', done ? 'bg-emerald-300' : 'bg-neutral-200')} />
            )}
          </div>
        )
      })}
    </div>
  )
}

function ReviewStep({
  approval,
  isMultiStage,
  currentChainStep,
}: {
  approval: Approval
  isMultiStage: boolean
  currentChainStep: number
}) {
  return (
    <div className="space-y-5">
      <Field label="Title" value={approval.title} />
      <Field
        label="Type"
        value={approval.type.replace(/_/g, ' ')}
      />
      <Field label="Description" value={approval.description || '—'} multiline />
      <div className="grid grid-cols-2 gap-4">
        <Field label="Initiator" value={approval.requested_by_name ?? approval.requested_by_id} />
        <Field label="Approver" value={approval.approver_name ?? approval.approver_id} />
        <Field
          label="Entity"
          value={approval.entity_type ? `${approval.entity_type} · ${approval.entity_id}` : '—'}
        />
        <Field label="Created" value={new Date(approval.created_at).toLocaleString()} />
      </div>
      {isMultiStage && (
        <section className="pt-4 border-t border-neutral-100">
          <h4 className="text-xs font-semibold text-neutral-500 uppercase mb-3">Approval Chain</h4>
          <ApprovalChain type={approval.type} currentStep={currentChainStep} />
        </section>
      )}
    </div>
  )
}

function DecisionStep({
  approval,
  mode,
  reason,
  onReasonChange,
  error,
  isMultiStage,
  currentChainStep,
}: {
  approval: Approval
  mode: WizardMode
  reason: string
  onReasonChange: (v: string) => void
  error: string | null
  isMultiStage: boolean
  currentChainStep: number
}) {
  return (
    <div className="space-y-5">
      {isMultiStage && (
        <section>
          <h4 className="text-xs font-semibold text-neutral-500 uppercase mb-3">
            Current Stage
          </h4>
          <ApprovalChain type={approval.type} currentStep={currentChainStep} />
        </section>
      )}
      <section>
        <label className="block text-sm font-medium text-neutral-800 mb-1">
          Reason / Justification <span className="text-red-500">*</span>
        </label>
        <p className="text-xs text-neutral-500 mb-2">
          Wajib diisi minimal {REASON_MIN_LENGTH} karakter. Akan dicatat di audit log untuk
          decision &ldquo;{mode}&rdquo;.
        </p>
        <Textarea
          rows={5}
          value={reason}
          maxLength={REASON_MAX_LENGTH}
          onChange={(e) => onReasonChange(e.target.value)}
          placeholder="Jelaskan alasan keputusan ini…"
        />
        <div className="flex items-center justify-between mt-1">
          <span className={cn('text-xs', error ? 'text-red-600' : 'text-neutral-400')}>
            {error ?? `${reason.length} / ${REASON_MAX_LENGTH}`}
          </span>
        </div>
      </section>
    </div>
  )
}

function ConfirmStep({
  approval,
  mode,
  reason,
  consequences,
}: {
  approval: Approval
  mode: WizardMode
  reason: string
  consequences: string[]
}) {
  const meta = MODE_META[mode]
  return (
    <div className="space-y-5">
      <div className={cn(
        'rounded-lg p-4 border',
        meta.tone === 'danger'
          ? 'bg-red-50 border-red-200 text-red-900'
          : meta.tone === 'primary'
            ? 'bg-brand-50 border-brand-200 text-brand-900'
            : 'bg-neutral-50 border-neutral-200 text-neutral-800',
      )}>
        <p className="text-sm font-medium capitalize">{mode} &ldquo;{approval.title}&rdquo;?</p>
        <p className="text-xs mt-1 opacity-80">
          Periksa kembali sebelum submit. Aksi ini akan tercatat permanen.
        </p>
      </div>
      <Field label="Reason" value={reason} multiline />
      <section>
        <h4 className="text-xs font-semibold text-neutral-500 uppercase mb-2">
          Consequences
        </h4>
        <ul className="space-y-1.5">
          {consequences.map((c, idx) => (
            <li key={idx} className="text-sm text-neutral-700 flex gap-2">
              <span className="text-neutral-400">•</span>
              <span>{c}</span>
            </li>
          ))}
        </ul>
      </section>
    </div>
  )
}

function Field({
  label,
  value,
  multiline = false,
}: {
  label: string
  value: string
  multiline?: boolean
}) {
  return (
    <div>
      <h4 className="text-xs font-semibold text-neutral-500 uppercase mb-1">{label}</h4>
      <p
        className={cn(
          'text-sm text-neutral-800',
          multiline && 'whitespace-pre-wrap',
        )}
      >
        {value}
      </p>
    </div>
  )
}
