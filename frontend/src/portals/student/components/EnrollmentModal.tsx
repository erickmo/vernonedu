import { useState } from 'react'
import * as Dialog from '@radix-ui/react-dialog'
import { X, Loader2, CheckCircle2 } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useBatches, type Batch } from '@/lib/api/catalog'
import { useCreateEnrollment } from '@/lib/api/enrollment'
import { useAuth } from '@/lib/auth/useAuth'
import { formatCurrency } from '@/lib/utils/format'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'
import BatchCard from './BatchCard'

type Step = 'batches' | 'confirm' | 'success'

interface EnrollmentModalProps {
  open: boolean
  onClose: () => void
  courseId: string
  courseName: string
  courseFormat: string
}

export default function EnrollmentModal({
  open,
  onClose,
  courseId,
  courseName,
  courseFormat: _courseFormat,
}: EnrollmentModalProps) {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [step, setStep] = useState<Step>('batches')
  const [selectedBatch, setSelectedBatch] = useState<Batch | null>(null)
  const [voucherCode, setVoucherCode] = useState('')
  const [submitError, setSubmitError] = useState<string | null>(null)
  const [enrolledBatchLabel, setEnrolledBatchLabel] = useState('')

  const { data: batches, isLoading: loadingBatches } = useBatches(courseId)
  const enrollMutation = useCreateEnrollment()

  function handleClose() {
    setStep('batches')
    setSelectedBatch(null)
    setVoucherCode('')
    setSubmitError(null)
    onClose()
  }

  async function handleSubmit() {
    if (!selectedBatch || !user) return
    setSubmitError(null)
    try {
      await enrollMutation.mutateAsync({
        student_id: user.id,
        batch_id: selectedBatch.id,
        voucher_code: voucherCode.trim() || undefined,
      })
      setEnrolledBatchLabel(selectedBatch.label)
      setStep('success')
    } catch (err: unknown) {
      const msg =
        err instanceof Error ? err.message : 'Enrollment failed. Please try again.'
      setSubmitError(msg)
    }
  }

  const openBatches = (batches ?? []).filter((b) => b.status === 'open')

  return (
    <Dialog.Root open={open} onOpenChange={(v) => { if (!v) handleClose() }}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50" />
        <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-lg bg-white rounded-2xl shadow-2xl flex flex-col max-h-[90vh]">

          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-neutral-100 shrink-0">
            <div>
              <Dialog.Title className="font-semibold text-neutral-900 text-sm">
                {step === 'batches' && 'Select a Batch'}
                {step === 'confirm' && 'Confirm Enrollment'}
                {step === 'success' && 'Enrollment Confirmed'}
              </Dialog.Title>
              <p className="text-xs text-neutral-500 mt-0.5 truncate max-w-xs">{courseName}</p>
            </div>
            {step !== 'success' && (
              <button
                type="button"
                onClick={handleClose}
                className="p-1.5 rounded-lg hover:bg-neutral-100 transition-colors text-neutral-500"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>

          {/* Step indicator */}
          <div className="flex items-center justify-center gap-2 px-6 pt-4 shrink-0">
            {(['batches', 'confirm', 'success'] as Step[]).map((s, i) => (
              <div key={s} className="flex items-center gap-2">
                <div
                  className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-semibold transition-colors ${
                    step === s
                      ? 'bg-brand-600 text-white'
                      : i < (['batches', 'confirm', 'success'] as Step[]).indexOf(step)
                        ? 'bg-brand-100 text-brand-700'
                        : 'bg-neutral-100 text-neutral-400'
                  }`}
                >
                  {i + 1}
                </div>
                {i < 2 && <div className="w-8 h-px bg-neutral-200" />}
              </div>
            ))}
          </div>

          {/* Body */}
          <div className="flex-1 overflow-y-auto px-6 py-4">

            {/* Step 1: Batch Selection */}
            {step === 'batches' && (
              <div className="space-y-3">
                {loadingBatches ? (
                  <LoadingSpinner className="py-12" />
                ) : openBatches.length === 0 ? (
                  <EmptyState
                    title="No open batches"
                    description="There are no open batches available for this course right now. Check back later."
                  />
                ) : (
                  <>
                    <p className="text-xs text-neutral-500">
                      Choose the batch you want to join.
                    </p>
                    {(batches ?? []).map((batch) => (
                      <BatchCard
                        key={batch.id}
                        batch={batch}
                        selected={selectedBatch?.id === batch.id}
                        onSelect={() => setSelectedBatch(batch)}
                      />
                    ))}
                  </>
                )}
              </div>
            )}

            {/* Step 2: Confirm & Voucher */}
            {step === 'confirm' && selectedBatch && (
              <div className="space-y-4">
                <div className="rounded-xl border border-neutral-100 p-4 bg-neutral-50 space-y-2">
                  <p className="text-sm font-semibold text-neutral-900">{selectedBatch.label}</p>
                  <p className="text-xs text-neutral-500">
                    {selectedBatch.start_date} – {selectedBatch.end_date}
                  </p>
                  <p className="text-lg font-bold text-brand-700">
                    {formatCurrency(selectedBatch.price)}
                  </p>
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-medium text-neutral-700">
                    Voucher code <span className="text-neutral-400 font-normal">(optional)</span>
                  </label>
                  <input
                    type="text"
                    value={voucherCode}
                    onChange={(e) => setVoucherCode(e.target.value)}
                    placeholder="e.g. SAVE20"
                    className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
                  />
                </div>

                {submitError && (
                  <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-lg px-3 py-2">
                    {submitError}
                  </p>
                )}
              </div>
            )}

            {/* Step 3: Success */}
            {step === 'success' && (
              <div className="flex flex-col items-center text-center py-6 space-y-3">
                <div className="w-16 h-16 rounded-full bg-emerald-100 flex items-center justify-center">
                  <CheckCircle2 className="w-8 h-8 text-emerald-600" />
                </div>
                <h3 className="text-base font-bold text-neutral-900">You're enrolled!</h3>
                <p className="text-sm text-neutral-600">
                  Successfully enrolled in <span className="font-semibold">{enrolledBatchLabel}</span>.
                </p>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="px-6 py-4 border-t border-neutral-100 shrink-0 flex justify-between gap-3">
            {step === 'batches' && (
              <>
                <button
                  type="button"
                  onClick={handleClose}
                  className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-900 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={!selectedBatch}
                  onClick={() => setStep('confirm')}
                  className="px-5 py-2 rounded-lg bg-brand-600 text-white text-sm font-semibold disabled:opacity-40 disabled:cursor-not-allowed hover:bg-brand-700 transition-colors"
                >
                  Next →
                </button>
              </>
            )}

            {step === 'confirm' && (
              <>
                <button
                  type="button"
                  onClick={() => { setSubmitError(null); setStep('batches') }}
                  className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-900 transition-colors"
                >
                  ← Back
                </button>
                <button
                  type="button"
                  disabled={enrollMutation.isPending}
                  onClick={handleSubmit}
                  className="inline-flex items-center gap-2 px-5 py-2 rounded-lg bg-brand-600 text-white text-sm font-semibold disabled:opacity-40 disabled:cursor-not-allowed hover:bg-brand-700 transition-colors"
                >
                  {enrollMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
                  Confirm Enrollment
                </button>
              </>
            )}

            {step === 'success' && (
              <button
                type="button"
                onClick={() => { handleClose(); navigate('/student/enrollments') }}
                className="w-full px-5 py-2.5 rounded-lg bg-brand-600 text-white text-sm font-semibold hover:bg-brand-700 transition-colors"
              >
                View My Enrollments
              </button>
            )}
          </div>

        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
