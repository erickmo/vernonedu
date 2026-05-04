import { useNavigate, useLocation } from 'react-router-dom'
import { Users, ClipboardCheck, UserCog, Wallet, Plus } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { hrmService } from '@/services/hrm.service'
import { toast } from '@/widgets/Toast/Toast'
import { PAYROLL_STATUS_LABELS, PAYROLL_STATUS_COLORS } from '@/types/hrm.types'
import type { PayrollPeriod, PayrollPeriodStatus } from '@/types/hrm.types'

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)
}

const columns: ColumnDef<PayrollPeriod>[] = [
  {
    key: 'period',
    header: 'Periode',
    sortable: true,
    width: 150,
    render: (_v, row) => (
      <span style={{ fontWeight: 600 }}>{row.period}</span>
    ),
  },
  {
    key: 'start_date',
    header: 'Mulai',
    width: 130,
    render: (_v, row) => {
      if (!row.start_date) return '—'
      return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(row.start_date))
    },
  },
  {
    key: 'end_date',
    header: 'Selesai',
    width: 130,
    render: (_v, row) => {
      if (!row.end_date) return '—'
      return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(row.end_date))
    },
  },
  {
    key: 'status',
    header: 'Status',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const s = row.status as PayrollPeriodStatus
      const colors = PAYROLL_STATUS_COLORS[s]
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: colors?.bg ?? 'var(--color-surface-alt)',
          color: colors?.color ?? 'var(--color-text-tertiary)',
        }}>
          {PAYROLL_STATUS_LABELS[s] ?? s}
        </span>
      )
    },
  },
  {
    key: 'total_amount',
    header: 'Total',
    width: 180,
    align: 'right',
    render: (_v, row) => (
      <span style={{ fontWeight: 600 }}>
        {row.total_amount ? formatCurrency(row.total_amount) : '—'}
      </span>
    ),
  },
]

const filterDefs: FilterDef[] = [
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: Object.entries(PAYROLL_STATUS_LABELS).map(([value, label]) => ({ label, value })),
  },
]

const TAB_ITEMS = [
  { key: 'employees', label: 'Karyawan', icon: <Users size={15} />, path: '/hrm' },
  { key: 'attendance', label: 'Kehadiran', icon: <ClipboardCheck size={15} />, path: '/hrm/attendance' },
  { key: 'leaves', label: 'Cuti', icon: <UserCog size={15} />, path: '/hrm/leaves' },
  { key: 'payroll', label: 'Penggajian', icon: <Wallet size={15} />, path: '/hrm/payroll' },
]

export default function PayrollPeriodsPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const queryClient = useQueryClient()

  const [showCreateModal, setShowCreateModal] = useState(false)
  const [newPeriod, setNewPeriod] = useState('')
  const [newStart, setNewStart] = useState('')
  const [newEnd, setNewEnd] = useState('')
  const [newNotes, setNewNotes] = useState('')
  const [isCreating, setIsCreating] = useState(false)

  const rowActions: RowActionDef<PayrollPeriod>[] = [
    {
      key: 'generate',
      label: 'Generate Payroll',
      visible: (row) => row.status === 'draft',
      onClick: async (row) => {
        try {
          await hrmService.generatePayroll(row.id)
          toast.success('Payroll berhasil digenerate')
          await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-periods'] })
        } catch {
          toast.error('Gagal generate payroll')
        }
      },
    },
    {
      key: 'approve',
      label: 'Setujui',
      visible: (row) => row.status === 'processing',
      onClick: async (row) => {
        try {
          await hrmService.approvePayroll(row.id)
          toast.success('Payroll berhasil disetujui')
          await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-periods'] })
        } catch {
          toast.error('Gagal menyetujui payroll')
        }
      },
    },
    {
      key: 'disburse',
      label: 'Salurkan',
      visible: (row) => row.status === 'approved',
      onClick: async (row) => {
        try {
          await hrmService.disbursePayroll(row.id)
          toast.success('Payroll berhasil disalurkan')
          await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-periods'] })
        } catch {
          toast.error('Gagal menyalurkan payroll')
        }
      },
    },
  ]

  async function handleCreatePeriod() {
    if (!newPeriod || !newStart || !newEnd) {
      toast.error('Periode, tanggal mulai, dan tanggal selesai wajib diisi')
      return
    }
    setIsCreating(true)
    try {
      await hrmService.createPayrollPeriod({
        period: newPeriod,
        start_date: newStart,
        end_date: newEnd,
        notes: newNotes,
      })
      toast.success('Periode payroll berhasil dibuat')
      await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-periods'] })
      setShowCreateModal(false)
      setNewPeriod('')
      setNewStart('')
      setNewEnd('')
      setNewNotes('')
    } catch {
      toast.error('Gagal membuat periode payroll')
    } finally {
      setIsCreating(false)
    }
  }

  return (
    <div>
      {/* Tab navigation */}
      <div style={{
        display: 'flex', gap: 'var(--space-1)', marginBottom: 'var(--space-4)',
        borderBottom: '1px solid var(--color-border)', paddingBottom: 0,
      }}>
        {TAB_ITEMS.map((tab) => {
          const isActive = location.pathname === tab.path
          return (
            <button
              key={tab.key}
              onClick={() => navigate(tab.path)}
              style={{
                display: 'flex', alignItems: 'center', gap: 6,
                padding: 'var(--space-3) var(--space-4)',
                border: 'none', borderBottom: isActive ? '2px solid var(--color-primary)' : '2px solid transparent',
                background: 'none', cursor: 'pointer',
                color: isActive ? 'var(--color-primary)' : 'var(--color-text-secondary)',
                fontWeight: isActive ? 600 : 400,
                fontSize: 'var(--font-sm)',
                marginBottom: -1,
              }}
            >
              {tab.icon}
              {tab.label}
            </button>
          )
        })}
      </div>

      <ListPageTemplate<PayrollPeriod>
        title="Periode Penggajian"
        addLabel="Buat Periode"
        onAdd={() => setShowCreateModal(true)}
        queryKey="hrm-payroll-periods"
        fetcher={(params) => hrmService.listPayrollPeriods(params)}
        columns={columns}
        rowActions={rowActions}
        onRowClick={(row) => navigate(`/hrm/payroll/${row.id}`)}
        searchPlaceholder="Cari periode..."
        exportFilename="penggajian"
        filterDefs={filterDefs}
        emptyTitle="Belum ada periode penggajian"
        emptyDescription="Buat periode payroll pertama untuk mulai mengelola penggajian."
        helpTitle="Penggajian"
        helpText="Kelola periode penggajian karyawan. Alur: Draft → Generate → Approve → Disburse."
      />

      {/* Create Period Modal */}
      {showCreateModal && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 400,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }} onClick={() => !isCreating && setShowCreateModal(false)}>
          <div style={{
            background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', width: 440, overflow: 'hidden',
          }} onClick={(e) => e.stopPropagation()}>
            <div style={{
              padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)',
            }}>
              <h3 style={{ fontSize: 'var(--font-base)', fontWeight: 700 }}>Buat Periode Payroll</h3>
            </div>
            <div style={{ padding: 'var(--space-5)', display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
              <div>
                <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>
                  Nama Periode *
                </label>
                <input
                  type="text"
                  value={newPeriod}
                  onChange={(e) => setNewPeriod(e.target.value)}
                  placeholder="cth. Januari 2026"
                  style={{
                    width: '100%', padding: '8px 12px', borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                    background: 'var(--color-surface)', color: 'var(--color-text)',
                  }}
                />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-3)' }}>
                <div>
                  <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>
                    Mulai *
                  </label>
                  <input
                    type="date"
                    value={newStart}
                    onChange={(e) => setNewStart(e.target.value)}
                    style={{
                      width: '100%', padding: '8px 12px', borderRadius: 'var(--radius-md)',
                      border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                      background: 'var(--color-surface)', color: 'var(--color-text)',
                    }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>
                    Selesai *
                  </label>
                  <input
                    type="date"
                    value={newEnd}
                    onChange={(e) => setNewEnd(e.target.value)}
                    style={{
                      width: '100%', padding: '8px 12px', borderRadius: 'var(--radius-md)',
                      border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                      background: 'var(--color-surface)', color: 'var(--color-text)',
                    }}
                  />
                </div>
              </div>
              <div>
                <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>
                  Catatan
                </label>
                <textarea
                  value={newNotes}
                  onChange={(e) => setNewNotes(e.target.value)}
                  placeholder="Opsional..."
                  rows={3}
                  style={{
                    width: '100%', padding: '8px 12px', borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                    background: 'var(--color-surface)', color: 'var(--color-text)',
                    resize: 'vertical',
                  }}
                />
              </div>
            </div>
            <div style={{
              padding: 'var(--space-4) var(--space-5)', borderTop: '1px solid var(--color-border)',
              display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-3)',
            }}>
              <button
                onClick={() => setShowCreateModal(false)}
                disabled={isCreating}
                style={{
                  padding: '8px 16px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)',
                  background: 'var(--color-surface-elevated)', cursor: 'pointer', fontSize: 'var(--font-sm)',
                }}
              >
                Batal
              </button>
              <button
                onClick={handleCreatePeriod}
                disabled={isCreating}
                style={{
                  padding: '8px 16px', borderRadius: 'var(--radius-md)', border: 'none',
                  background: 'var(--color-primary)', color: '#fff', cursor: 'pointer',
                  fontSize: 'var(--font-sm)', fontWeight: 600,
                }}
              >
                {isCreating ? 'Menyimpan...' : 'Buat Periode'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
