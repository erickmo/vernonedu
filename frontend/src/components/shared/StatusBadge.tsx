import { cn } from '@/lib/utils/cn'

type EnrollmentStatus = 'confirmed' | 'pending' | 'dropped' | 'completed'
type PaymentStatus = 'paid' | 'partial' | 'pending' | 'overdue'
type InvoiceStatus = 'paid' | 'sent' | 'draft' | 'overdue' | 'cancelled'
type BatchStatus = 'open' | 'full' | 'ongoing' | 'completed' | 'cancelled' | 'draft'
type ProposalStatus = 'pending' | 'approved' | 'rejected'

type StatusVariant = 'enrollment' | 'payment' | 'invoice' | 'batch' | 'proposal'

const ENROLLMENT_MAP: Record<EnrollmentStatus, { label: string; className: string }> = {
  confirmed: { label: 'Confirmed', className: 'bg-emerald-100 text-emerald-800' },
  pending: { label: 'Pending', className: 'bg-amber-100 text-amber-800' },
  dropped: { label: 'Dropped', className: 'bg-red-100 text-red-800' },
  completed: { label: 'Completed', className: 'bg-blue-100 text-blue-800' },
}

const PAYMENT_MAP: Record<PaymentStatus, { label: string; className: string }> = {
  paid: { label: 'Paid', className: 'bg-emerald-100 text-emerald-800' },
  partial: { label: 'Partial', className: 'bg-amber-100 text-amber-800' },
  pending: { label: 'Pending', className: 'bg-slate-100 text-slate-700' },
  overdue: { label: 'Overdue', className: 'bg-red-100 text-red-800' },
}

const INVOICE_MAP: Record<InvoiceStatus, { label: string; className: string }> = {
  paid: { label: 'Paid', className: 'bg-emerald-100 text-emerald-800' },
  sent: { label: 'Sent', className: 'bg-blue-100 text-blue-800' },
  draft: { label: 'Draft', className: 'bg-slate-100 text-slate-700' },
  overdue: { label: 'Overdue', className: 'bg-red-100 text-red-800' },
  cancelled: { label: 'Cancelled', className: 'bg-gray-100 text-gray-600' },
}

const BATCH_MAP: Record<BatchStatus, { label: string; className: string }> = {
  open: { label: 'Open', className: 'bg-emerald-100 text-emerald-800' },
  full: { label: 'Full', className: 'bg-orange-100 text-orange-800' },
  ongoing: { label: 'Ongoing', className: 'bg-blue-100 text-blue-800' },
  completed: { label: 'Completed', className: 'bg-slate-100 text-slate-700' },
  cancelled: { label: 'Cancelled', className: 'bg-gray-100 text-gray-600' },
  draft: { label: 'Draft', className: 'bg-slate-100 text-slate-700' },
}

const PROPOSAL_MAP: Record<ProposalStatus, { label: string; className: string }> = {
  pending: { label: 'Pending', className: 'bg-amber-100 text-amber-800' },
  approved: { label: 'Approved', className: 'bg-emerald-100 text-emerald-800' },
  rejected: { label: 'Rejected', className: 'bg-red-100 text-red-800' },
}

interface StatusBadgeProps {
  status: string
  variant?: StatusVariant
}

function resolveConfig(status: string, variant?: StatusVariant) {
  switch (variant) {
    case 'enrollment':
      return ENROLLMENT_MAP[status as EnrollmentStatus]
    case 'payment':
      return PAYMENT_MAP[status as PaymentStatus]
    case 'invoice':
      return INVOICE_MAP[status as InvoiceStatus]
    case 'batch':
      return BATCH_MAP[status as BatchStatus]
    case 'proposal':
      return PROPOSAL_MAP[status as ProposalStatus]
    default:
      return null
  }
}

export default function StatusBadge({ status, variant }: StatusBadgeProps) {
  const config = resolveConfig(status, variant)
  const label = config?.label ?? status
  const className = config?.className ?? 'bg-gray-100 text-gray-700'

  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize',
        className
      )}
    >
      {label}
    </span>
  )
}
