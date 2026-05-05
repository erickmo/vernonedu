import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { X, CheckCircle, XCircle } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { hrmService } from '@/services/hrm.service'
import { toast } from '@/widgets/Toast/Toast'
import {
  LEAVE_TYPE_LABELS, LEAVE_STATUS_LABELS, LEAVE_STATUS_COLORS,
} from '@/types/hrm.types'
import type { LeaveRequest, LeaveStatus, LeaveType } from '@/types/hrm.types'

function calcDuration(start: string, end: string): number {
  if (!start || !end) return 0
  const d1 = new Date(start)
  const d2 = new Date(end)
  const diff = Math.ceil((d2.getTime() - d1.getTime()) / (1000 * 60 * 60 * 24)) + 1
  return diff > 0 ? diff : 0
}

const columns: ColumnDef<LeaveRequest>[] = [
  {
    key: 'employee_name',
    header: 'Karyawan',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 30, height: 30, borderRadius: 'var(--radius-full)',
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0, fontWeight: 700,
          fontSize: 'var(--font-xs)',
        }}>
          {(row.employee_name || '?').charAt(0).toUpperCase()}
        </div>
        <span style={{ fontWeight: 500 }}>{row.employee_name || '—'}</span>
      </div>
    ),
  },
  {
    key: 'leave_type',
    header: 'Jenis Cuti',
    width: 120,
    render: (_v, row) => LEAVE_TYPE_LABELS[row.leave_type as LeaveType] ?? row.leave_type,
  },
  {
    key: 'start_date',
    header: 'Mulai',
    sortable: true,
    width: 120,
    render: (_v, row) => {
      if (!row.start_date) return '—'
      return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(row.start_date))
    },
  },
  {
    key: 'end_date',
    header: 'Selesai',
    width: 120,
    render: (_v, row) => {
      if (!row.end_date) return '—'
      return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(row.end_date))
    },
  },
  {
    key: 'duration',
    header: 'Durasi',
    width: 80,
    align: 'center',
    render: (_v, row) => {
      const d = calcDuration(row.start_date, row.end_date)
      return <span>{d} hari</span>
    },
  },
  {
    key: 'status',
    header: 'Status',
    width: 110,
    align: 'center',
    render: (_v, row) => {
      const s = row.status as LeaveStatus
      const colors = LEAVE_STATUS_COLORS[s]
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: colors?.bg ?? 'var(--color-surface-alt)',
          color: colors?.color ?? 'var(--color-text-tertiary)',
        }}>
          {LEAVE_STATUS_LABELS[s] ?? s}
        </span>
      )
    },
  },
  {
    key: 'reason',
    header: 'Alasan',
    render: (_v, row) => (
      <span style={{ color: row.reason ? 'var(--color-text-secondary)' : 'var(--color-text-tertiary)' }}>
        {row.reason ? (row.reason.length > 50 ? row.reason.slice(0, 50) + '...' : row.reason) : '—'}
      </span>
    ),
  },
]

const filterDefs: FilterDef[] = [
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: Object.entries(LEAVE_STATUS_LABELS).map(([value, label]) => ({ label, value })),
  },
]

export default function LeaveRequestsPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [reviewingLeave, setReviewingLeave] = useState<LeaveRequest | null>(null)
  const [reviewAction, setReviewAction] = useState<'approved' | 'rejected'>('approved')
  const [isReviewing, setIsReviewing] = useState(false)

  const rowActions: RowActionDef<LeaveRequest>[] = [
    {
      key: 'review',
      label: 'Review',
      icon: <CheckCircle size={14} />,
      visible: (row) => row.status === 'pending',
      onClick: (row) => {
        setReviewingLeave(row)
        setReviewAction('approved')
      },
    },
  ]

  async function handleReviewSubmit() {
    if (!reviewingLeave) return
    setIsReviewing(true)
    try {
      await hrmService.reviewLeave(reviewingLeave.id, { status: reviewAction })
      toast.success(`Cuti berhasil ${reviewAction === 'approved' ? 'disetujui' : 'ditolak'}`)
      await queryClient.invalidateQueries({ queryKey: ['hrm-leaves'] })
      setReviewingLeave(null)
    } catch {
      toast.error('Gagal memproses review cuti')
    } finally {
      setIsReviewing(false)
    }
  }

  return (
    <>
      <ListPageTemplate<LeaveRequest>
        title="Permintaan Cuti"
        addLabel="Ajukan Cuti"
        onAdd={() => navigate('/hrm/leaves/new')}
        queryKey="hrm-leaves"
        fetcher={(params) => hrmService.listLeaves(params)}
        columns={columns}
        rowActions={rowActions}
        onRowClick={(row) => navigate(`/hrm/leaves/${row.id}`)}
        searchPlaceholder="Cari karyawan..."
        exportFilename="cuti"
        filterDefs={filterDefs}
        emptyTitle="Belum ada permintaan cuti"
        emptyDescription="Permintaan cuti dari karyawan akan muncul di sini."
        helpTitle="Cuti"
        helpText="Kelola permintaan cuti karyawan. Setujui atau tolak permintaan yang menunggu persetujuan."
      />

      {reviewingLeave && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 400,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }} onClick={() => !isReviewing && setReviewingLeave(null)}>
          <div style={{
            background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', width: 440, overflow: 'hidden',
          }} onClick={(e) => e.stopPropagation()}>
            <div style={{
              padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)',
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            }}>
              <h3 style={{ fontSize: 'var(--font-base)', fontWeight: 700 }}>Review Cuti</h3>
              <button onClick={() => !isReviewing && setReviewingLeave(null)} style={{
                background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)',
              }}>
                <X size={16} />
              </button>
            </div>
            <div style={{ padding: 'var(--space-5)' }}>
              <div style={{ marginBottom: 'var(--space-4)' }}>
                <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Karyawan</div>
                <div style={{ fontWeight: 600 }}>{reviewingLeave.employee_name}</div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-3)', marginBottom: 'var(--space-4)' }}>
                <div>
                  <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Jenis</div>
                  <div style={{ fontSize: 'var(--font-sm)', fontWeight: 500 }}>
                    {LEAVE_TYPE_LABELS[reviewingLeave.leave_type as LeaveType]}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Durasi</div>
                  <div style={{ fontSize: 'var(--font-sm)', fontWeight: 500 }}>
                    {calcDuration(reviewingLeave.start_date, reviewingLeave.end_date)} hari
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Mulai</div>
                  <div style={{ fontSize: 'var(--font-sm)' }}>
                    {new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(reviewingLeave.start_date))}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Selesai</div>
                  <div style={{ fontSize: 'var(--font-sm)' }}>
                    {new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(reviewingLeave.end_date))}
                  </div>
                </div>
              </div>
              <div style={{ marginBottom: 'var(--space-4)' }}>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Alasan</div>
                <div style={{ fontSize: 'var(--font-sm)', lineHeight: 1.5 }}>{reviewingLeave.reason || '—'}</div>
              </div>

              <div style={{ display: 'flex', gap: 'var(--space-2)', marginBottom: 'var(--space-5)' }}>
                <button
                  type="button"
                  onClick={() => setReviewAction('approved')}
                  style={{
                    flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                    padding: 'var(--space-3)', borderRadius: 'var(--radius-md)',
                    border: `2px solid ${reviewAction === 'approved' ? 'var(--color-success-dark)' : 'var(--color-border)'}`,
                    background: reviewAction === 'approved' ? 'var(--color-success-light)' : 'transparent',
                    cursor: 'pointer', fontWeight: 600, fontSize: 'var(--font-sm)',
                    color: reviewAction === 'approved' ? 'var(--color-success-dark)' : 'var(--color-text-secondary)',
                  }}
                >
                  <CheckCircle size={16} />
                  Setujui
                </button>
                <button
                  type="button"
                  onClick={() => setReviewAction('rejected')}
                  style={{
                    flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                    padding: 'var(--space-3)', borderRadius: 'var(--radius-md)',
                    border: `2px solid ${reviewAction === 'rejected' ? 'var(--color-error-dark)' : 'var(--color-border)'}`,
                    background: reviewAction === 'rejected' ? 'var(--color-error-light)' : 'transparent',
                    cursor: 'pointer', fontWeight: 600, fontSize: 'var(--font-sm)',
                    color: reviewAction === 'rejected' ? 'var(--color-error-dark)' : 'var(--color-text-secondary)',
                  }}
                >
                  <XCircle size={16} />
                  Tolak
                </button>
              </div>
            </div>
            <div style={{
              padding: 'var(--space-4) var(--space-5)', borderTop: '1px solid var(--color-border)',
              display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-3)',
            }}>
              <button
                onClick={() => setReviewingLeave(null)}
                disabled={isReviewing}
                style={{
                  padding: '8px 16px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)',
                  background: 'var(--color-surface-elevated)', cursor: 'pointer', fontSize: 'var(--font-sm)',
                }}
              >
                Batal
              </button>
              <button
                onClick={handleReviewSubmit}
                disabled={isReviewing}
                style={{
                  padding: '8px 16px', borderRadius: 'var(--radius-md)', border: 'none',
                  background: reviewAction === 'approved' ? 'var(--color-success-dark)' : 'var(--color-error-dark)',
                  color: '#fff', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 600,
                }}
              >
                {isReviewing ? 'Memproses...' : reviewAction === 'approved' ? 'Setujui' : 'Tolak'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
