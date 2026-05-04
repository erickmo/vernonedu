import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Ban } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { certificateService } from '@/services/certificate.service'
import { toast } from '@/widgets/Toast/Toast'
import { QK } from '@/services/query-keys'

interface Certificate {
  id: string
  student_name: string
  batch_name: string
  type: string
  status: string
  issued_at?: string
  [key: string]: unknown
}

const TYPE_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  participant:  { label: 'Peserta',      bg: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  competency:   { label: 'Kompetensi',   bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:    { label: 'Aktif',        bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  revoked:   { label: 'Dicabut',      bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
  expired:   { label: 'Kedaluwarsa',  bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
}

function formatDate(dateStr?: string): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  }).format(new Date(dateStr))
}

function getInitials(name: string): string {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('')
}

const filterDefs: FilterDef[] = [
  {
    key: 'type',
    label: 'Jenis',
    type: 'select',
    options: [
      { label: 'Semua', value: '' },
      { label: 'Peserta', value: 'participant' },
      { label: 'Kompetensi', value: 'competency' },
    ],
  },
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: [
      { label: 'Semua', value: '' },
      { label: 'Aktif', value: 'active' },
      { label: 'Dicabut', value: 'revoked' },
      { label: 'Kedaluwarsa', value: 'expired' },
    ],
  },
]

const columns: ColumnDef<Certificate>[] = [
  {
    key: 'student_name',
    header: 'Siswa',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 'var(--radius-full)',
          background: 'var(--color-primary-subtle)', display: 'flex',
          alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          color: 'var(--color-primary)', fontSize: 'var(--font-xs)', fontWeight: 600,
        }}>
          {getInitials(row.student_name || '?')}
        </div>
        <div style={{ fontWeight: 600 }}>{row.student_name || '—'}</div>
      </div>
    ),
  },
  {
    key: 'batch_name',
    header: 'Batch',
    sortable: true,
    width: 200,
    render: (_v, row) => row.batch_name || '—',
  },
  {
    key: 'type',
    header: 'Jenis',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const cfg = TYPE_CONFIG[row.type] || TYPE_CONFIG.participant
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: cfg.bg, color: cfg.color,
        }}>
          {cfg.label}
        </span>
      )
    },
  },
  {
    key: 'status',
    header: 'Status',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const cfg = STATUS_CONFIG[row.status] || STATUS_CONFIG.active
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: cfg.bg, color: cfg.color,
        }}>
          {cfg.label}
        </span>
      )
    },
  },
  {
    key: 'issued_at',
    header: 'Diterbitkan',
    sortable: true,
    width: 140,
    render: (_v, row) => formatDate(row.issued_at),
  },
]

export default function CertificateListPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [revokingRow, setRevokingRow] = useState<Certificate | null>(null)
  const [revokeReason, setRevokeReason] = useState('')
  const [isRevoking, setIsRevoking] = useState(false)

  const rowActions: RowActionDef<Certificate>[] = [
    {
      key: 'revoke',
      label: 'Cabut Sertifikat',
      icon: <Ban size={14} />,
      variant: 'danger',
      onClick: (row) => {
        setRevokingRow(row)
        setRevokeReason('')
      },
      visible: (row) => row.status === 'active',
    },
  ]

  async function handleConfirmRevoke() {
    if (!revokingRow) return
    if (!revokeReason.trim()) {
      toast.error('Alasan pencabutan wajib diisi')
      return
    }
    setIsRevoking(true)
    try {
      await certificateService.revoke(revokingRow.id, revokeReason.trim())
      await queryClient.invalidateQueries({ queryKey: [QK.certificates] })
      toast.success(`Sertifikat ${revokingRow.student_name} berhasil dicabut`)
      setRevokingRow(null)
    } catch {
      toast.error('Gagal mencabut sertifikat')
    } finally {
      setIsRevoking(false)
    }
  }

  return (
    <>
      <ListPageTemplate<Certificate>
        title="Sertifikat"
        addLabel="Terbitkan Sertifikat Peserta"
        onAdd={() => navigate('/certificates/issue-participant/new')}
        queryKey={QK.certificates}
        fetcher={(params) => certificateService.list(params)}
        columns={columns}
        rowActions={rowActions}
        searchPlaceholder="Cari sertifikat..."
        exportFilename="sertifikat"
        emptyTitle="Belum ada sertifikat"
        emptyDescription="Sertifikat akan muncul setelah diterbitkan untuk siswa yang menyelesaikan kursus."
        helpTitle="Sertifikat"
        helpText="Sertifikat diterbitkan untuk siswa yang menyelesaikan kursus. Sertifikat Peserta otomatis setelah batch selesai, sedangkan Sertifikat Kompetensi memerlukan kelulusan tes. Gunakan aksi 'Cabut Sertifikat' jika diperlukan."
        filterDefs={filterDefs}
      />

      {revokingRow && (
        <div
          style={{
            position: 'fixed', inset: 0, zIndex: 1000,
            background: 'rgba(0,0,0,0.4)', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
          }}
          onClick={() => !isRevoking && setRevokingRow(null)}
        >
          <div
            style={{
              background: 'var(--color-surface)', borderRadius: 'var(--radius-xl)',
              padding: 'var(--space-6)', maxWidth: 440, width: '100%',
              boxShadow: 'var(--shadow-lg)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{
              width: 48, height: 48, borderRadius: 'var(--radius-full)',
              background: 'var(--color-error-light)', display: 'flex',
              alignItems: 'center', justifyContent: 'center',
              color: 'var(--color-error)', marginBottom: 'var(--space-4)',
            }}>
              <Ban size={24} />
            </div>
            <h3 style={{ fontSize: 'var(--font-lg)', fontWeight: 700, marginBottom: 'var(--space-2)' }}>
              Cabut Sertifikat?
            </h3>
            <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginBottom: 'var(--space-4)' }}>
              Sertifikat milik <strong>{revokingRow.student_name}</strong> akan dicabut. Tindakan ini tidak dapat dibatalkan.
            </p>
            <label style={{
              display: 'block', fontSize: 'var(--font-sm)', fontWeight: 600,
              marginBottom: 'var(--space-1)',
            }}>
              Alasan Pencabutan <span style={{ color: 'var(--color-error)' }}>*</span>
            </label>
            <textarea
              value={revokeReason}
              onChange={(e) => setRevokeReason(e.target.value)}
              placeholder="Jelaskan alasan pencabutan sertifikat..."
              rows={3}
              style={{
                width: '100%', padding: 'var(--space-3)', borderRadius: 'var(--radius-md)',
                border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                resize: 'vertical', fontFamily: 'inherit',
              }}
              autoFocus
            />
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-3)', marginTop: 'var(--space-4)' }}>
              <button
                onClick={() => setRevokingRow(null)}
                disabled={isRevoking}
                style={{
                  padding: 'var(--space-2) var(--space-4)', borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--color-border)', background: 'var(--color-surface)',
                  fontSize: 'var(--font-sm)', fontWeight: 600, cursor: 'pointer',
                }}
              >
                Batal
              </button>
              <button
                onClick={handleConfirmRevoke}
                disabled={isRevoking || !revokeReason.trim()}
                style={{
                  padding: 'var(--space-2) var(--space-4)', borderRadius: 'var(--radius-md)',
                  border: 'none', background: 'var(--color-error)', color: '#fff',
                  fontSize: 'var(--font-sm)', fontWeight: 600, cursor: 'pointer',
                  opacity: isRevoking || !revokeReason.trim() ? 0.5 : 1,
                }}
              >
                {isRevoking ? 'Mencabut...' : 'Ya, Cabut'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
