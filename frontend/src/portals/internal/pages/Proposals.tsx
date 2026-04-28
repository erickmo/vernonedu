import { useState } from 'react'
import { Plus, FileText } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import {
  useProposal,
  useCreateProposal,
  useDeptLeaderReview,
  useAcademicLeaderReview,
  type FacilitatorProposal,
} from '@/lib/api/people'
import { useAuth } from '@/lib/auth/useAuth'
import { cn } from '@/lib/utils/cn'
import PageHeader from '@/components/shared/PageHeader'

const proposalSchema = z.object({
  course_id: z.string().uuid('Valid course ID required'),
  facilitator_id: z.string().uuid('Valid facilitator ID required'),
  fee_tier_id: z.string().uuid('Valid fee tier ID required'),
  fee_basis: z.enum(['per_class', 'per_course', 'both']),
})
type ProposalForm = z.infer<typeof proposalSchema>

const reviewSchema = z.object({
  status: z.enum(['approved', 'rejected']),
  note: z.string().optional(),
})
type ReviewForm = z.infer<typeof reviewSchema>

function StatusBadge({ status }: { status: string }) {
  const cls =
    status === 'approved'
      ? 'bg-emerald-50 text-emerald-700'
      : status === 'rejected'
      ? 'bg-red-50 text-red-600'
      : 'bg-amber-50 text-amber-700'
  return (
    <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium capitalize', cls)}>
      {status}
    </span>
  )
}

function ProposalRow({
  proposal,
  role,
}: {
  proposal: FacilitatorProposal
  role: string
}) {
  const [reviewOpen, setReviewOpen] = useState(false)
  const deptReview = useDeptLeaderReview()
  const academicReview = useAcademicLeaderReview()

  const canDeptReview =
    role === 'dept_leader' && proposal.dept_leader_status === 'pending'
  const canAcademicReview =
    role === 'academic_leader' && proposal.academic_leader_status === 'pending'
  const canReview = canDeptReview || canAcademicReview

  const { register, handleSubmit, reset } = useForm<ReviewForm>({
    resolver: zodResolver(reviewSchema),
    defaultValues: { status: 'approved' },
  })

  const onReview = async (form: ReviewForm) => {
    try {
      if (canDeptReview) {
        await deptReview.mutateAsync({ id: proposal.id, ...form })
      } else {
        await academicReview.mutateAsync({ id: proposal.id, ...form })
      }
      toast.success('Review submitted')
      setReviewOpen(false)
      reset()
    } catch {
      toast.error('Failed to submit review')
    }
  }

  return (
    <div className="flex items-center justify-between py-4 px-4 border-b border-neutral-100 last:border-0">
      <div className="space-y-1">
        <p className="text-sm font-medium text-neutral-800 font-mono">{proposal.id.slice(0, 8)}…</p>
        <p className="text-xs text-neutral-500">Basis: {proposal.fee_basis.replace(/_/g, ' ')}</p>
        <div className="flex gap-2 mt-1">
          <span className="text-xs text-neutral-400">Dept:</span>
          <StatusBadge status={proposal.dept_leader_status} />
          <span className="text-xs text-neutral-400">Academic:</span>
          <StatusBadge status={proposal.academic_leader_status} />
          <span className="text-xs text-neutral-400">Final:</span>
          <StatusBadge status={proposal.final_status} />
        </div>
      </div>
      {canReview && (
        <>
          <button
            onClick={() => setReviewOpen(true)}
            className="px-3 py-1.5 text-xs font-medium bg-brand-600 text-white rounded-lg hover:bg-brand-700"
          >
            Review
          </button>
          <Dialog.Root open={reviewOpen} onOpenChange={setReviewOpen}>
            <Dialog.Portal>
              <Dialog.Overlay className="fixed inset-0 bg-black/40 z-40" />
              <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-sm bg-white rounded-xl shadow-xl p-6 space-y-4">
                <Dialog.Title className="text-base font-semibold text-neutral-900">
                  Submit Review
                </Dialog.Title>
                <form onSubmit={handleSubmit(onReview)} className="space-y-3">
                  <div>
                    <label className="block text-sm font-medium text-neutral-700 mb-1">
                      Decision
                    </label>
                    <select
                      {...register('status')}
                      className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                    >
                      <option value="approved">Approve</option>
                      <option value="rejected">Reject</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-neutral-700 mb-1">
                      Note (optional)
                    </label>
                    <textarea
                      {...register('note')}
                      rows={3}
                      className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none"
                    />
                  </div>
                  <div className="flex justify-end gap-3 pt-1">
                    <button
                      type="button"
                      onClick={() => setReviewOpen(false)}
                      className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700"
                    >
                      Submit
                    </button>
                  </div>
                </form>
              </Dialog.Content>
            </Dialog.Portal>
          </Dialog.Root>
        </>
      )}
    </div>
  )
}

export default function Proposals() {
  const { user } = useAuth()
  const [createOpen, setCreateOpen] = useState(false)
  const [viewId, setViewId] = useState('')
  const createProposal = useCreateProposal()

  const { data: viewProposal } = useProposal(viewId)

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ProposalForm>({
    resolver: zodResolver(proposalSchema),
    defaultValues: { fee_basis: 'per_class' },
  })

  const onSubmit = async (form: ProposalForm) => {
    try {
      const created = await createProposal.mutateAsync(form)
      toast.success('Proposal created')
      setCreateOpen(false)
      reset()
      setViewId(created.id)
    } catch {
      toast.error('Failed to create proposal')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<FileText className="w-5 h-5 text-brand-600" />}
        title="Facilitator Proposals"
        description="Create and review facilitator assignment proposals"
        action={
          <button
            onClick={() => setCreateOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            New Proposal
          </button>
        }
      />

      {viewProposal && (
        <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
          <div className="px-4 py-3 border-b border-neutral-100">
            <h3 className="text-sm font-semibold text-neutral-700">Latest Proposal</h3>
          </div>
          <ProposalRow proposal={viewProposal} role={user?.role ?? ''} />
        </div>
      )}

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-6">
        <p className="text-sm text-neutral-500">
          Enter a proposal ID above to load and review a specific proposal.
        </p>
        <div className="flex gap-2 mt-3">
          <input
            value={viewId}
            onChange={(e) => setViewId(e.target.value)}
            placeholder="Paste proposal UUID…"
            className="flex-1 px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>
      </div>

      <Dialog.Root open={createOpen} onOpenChange={setCreateOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-40" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">
              New Facilitator Proposal
            </Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              {(
                [
                  ['course_id', 'Course ID (UUID)'],
                  ['facilitator_id', 'Facilitator ID (UUID)'],
                  ['fee_tier_id', 'Fee Tier ID (UUID)'],
                ] as const
              ).map(([field, label]) => (
                <div key={field}>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">
                    {label}
                  </label>
                  <input
                    {...register(field)}
                    className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 font-mono"
                  />
                  {errors[field] && (
                    <p className="text-xs text-red-500 mt-1">{errors[field]?.message}</p>
                  )}
                </div>
              ))}
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Fee Basis
                </label>
                <select
                  {...register('fee_basis')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  <option value="per_class">Per Class</option>
                  <option value="per_course">Per Course</option>
                  <option value="both">Both</option>
                </select>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => { setCreateOpen(false); reset() }}
                  className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={createProposal.isPending}
                  className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50"
                >
                  {createProposal.isPending ? 'Creating…' : 'Create'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
