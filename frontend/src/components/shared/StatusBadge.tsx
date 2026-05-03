import Badge from '@/components/ui/Badge'

type StatusVariant = 'enrollment' | 'payment' | 'invoice' | 'batch' | 'proposal' | 'franchisee' | 'royalty'

interface StatusBadgeProps {
  status: string
  variant?: StatusVariant
}

// Status to variant mapping based on semantic meaning
const STATUS_VARIANT_MAP: Record<string, string> = {
  // Success statuses
  confirmed: 'success',
  paid: 'success',
  active: 'success',
  open: 'success',
  approved: 'success',

  // Warning statuses
  pending: 'warning',
  partial: 'warning',
  sent: 'warning',
  ongoing: 'warning',
  unpaid: 'warning',

  // Danger statuses
  overdue: 'danger',
  dropped: 'danger',
  cancelled: 'danger',
  rejected: 'danger',
  terminated: 'danger',

  // Secondary statuses
  draft: 'secondary',
  completed: 'secondary',
  full: 'secondary',
  inactive: 'secondary'
}

// Status label mapping
const STATUS_LABEL_MAP: Record<string, string> = {
  confirmed: 'Confirmed',
  pending: 'Pending',
  dropped: 'Dropped',
  completed: 'Completed',
  paid: 'Paid',
  partial: 'Partial',
  overdue: 'Overdue',
  open: 'Open',
  full: 'Full',
  ongoing: 'Ongoing',
  sent: 'Sent',
  draft: 'Draft',
  cancelled: 'Cancelled',
  approved: 'Approved',
  rejected: 'Rejected',
  active: 'Active',
  inactive: 'Inactive',
  terminated: 'Terminated',
  unpaid: 'Unpaid'
}

function getStatusVariant(status: string): string {
  return STATUS_VARIANT_MAP[status] || 'secondary'
}

export default function StatusBadge({ status, variant }: StatusBadgeProps) {
  const statusVariant = getStatusVariant(status)
  const label = STATUS_LABEL_MAP[status] || status

  return (
    <Badge variant={statusVariant as any} className="capitalize">
      {label}
    </Badge>
  )
}
