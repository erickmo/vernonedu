import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Handshake, Pencil, Plus, FileText, StickyNote, X, Trash2 } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { partnerService } from '@/services/partner.service'
import { toast } from '@/widgets/Toast/Toast'
import { useDeleteConfirmModal } from '@/widgets/Modals/DeleteConfirmModal'

interface Partner {
  id: string
  name: string
  type?: string
  contact_person?: string
  email?: string
  phone?: string
  address?: string
  mou_status?: string
  [key: string]: unknown
}

function InfoRow({ label, value }: { label: string; value?: string | null }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: 'var(--space-2) 0', borderBottom: '1px solid var(--color-border)' }}>
      <span style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>{label}</span>
      <span style={{ fontWeight: 500, fontSize: 'var(--font-sm)' }}>{value || '—'}</span>
    </div>
  )
}

function Badge({ label, variant }: { label: string; variant: 'success' | 'warning' | 'muted' }) {
  const styles: Record<string, { bg: string; color: string }> = {
    success: { bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
    warning: { bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
    muted: { bg: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' },
  }
  const s = styles[variant]
  return (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600, background: s.bg, color: s.color,
    }}>
      {label}
    </span>
  )
}

export default function PartnerDetailPage() {
  const { partnerId } = useParams<{ partnerId: string }>()
  const navigate = useNavigate()
  const confirmDelete = useDeleteConfirmModal()
  const [showMOUDialog, setShowMOUDialog] = useState(false)

  const { data: partner, isLoading } = useQuery({
    queryKey: ['partner', partnerId],
    queryFn: () => partnerService.getDetail(partnerId!),
  })

  const p = partner as Partner | undefined

  function getMOUBadgeVariant(status?: string): 'success' | 'warning' | 'muted' {
    if (status === 'active') return 'success'
    if (status === 'expiring') return 'warning'
    return 'muted'
  }

  function getMOUBadgeLabel(status?: string): string {
    if (status === 'active') return 'MOU Aktif'
    if (status === 'expiring') return 'MOU Segera Berakhir'
    return 'Belum Ada MOU'
  }

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Partner',
      icon: <Pencil size={14} />,
      onClick: () => navigate('/business-dev/partners'),
      variant: 'default',
    },
    {
      label: 'Tambah MOU',
      icon: <Plus size={14} />,
      onClick: () => setShowMOUDialog(true),
      variant: 'default',
    },
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: () => confirmDelete('Hapus Partner', 'Yakin ingin menghapus partner ini?', async () => {
        await partnerService.delete(partnerId!)
        toast.success('Partner berhasil dihapus')
        navigate('/business-dev/partners')
      }),
      variant: 'danger' as const,
    },
  ]

  const overviewTab = (
    <div style={{ display: 'grid', gap: 'var(--space-4)' }}>
      <div style={{
        padding: 'var(--space-5)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
      }}>
        <h3 style={{ fontSize: 'var(--font-sm)', fontWeight: 700, marginBottom: 'var(--space-3)', color: 'var(--color-text-secondary)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
          Informasi Partner
        </h3>
        <InfoRow label="Nama" value={p?.name} />
        <InfoRow label="Tipe" value={p?.type} />
        <InfoRow label="Kontak Person" value={p?.contact_person} />
        <InfoRow label="Email" value={p?.email} />
        <InfoRow label="Telepon" value={p?.phone} />
        <InfoRow label="Alamat" value={p?.address} />
      </div>

      <div style={{
        padding: 'var(--space-5)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
          <div style={{
            width: 40, height: 40, borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary-subtle)', display: 'flex',
            alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)',
          }}>
            <Handshake size={18} />
          </div>
          <div>
            <div style={{ fontWeight: 600 }}>Status MOU</div>
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
              Memorandum of Understanding
            </div>
          </div>
        </div>
        <Badge label={getMOUBadgeLabel(p?.mou_status)} variant={getMOUBadgeVariant(p?.mou_status)} />
      </div>
    </div>
  )

  const mouTab = (
    <div style={{
      padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)',
      borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)',
      background: 'var(--color-surface-elevated)',
    }}>
      <FileText size={32} style={{ marginBottom: 'var(--space-3)', opacity: 0.5 }} />
      <div style={{ fontWeight: 600, fontSize: 'var(--font-base)', color: 'var(--color-text-secondary)' }}>
        Belum ada MOU tercatat
      </div>
      <div style={{ fontSize: 'var(--font-sm)', marginTop: 'var(--space-1)' }}>
        Tambahkan MOU baru untuk memulai kolaborasi dengan partner ini.
      </div>
    </div>
  )

  const notesTab = (
    <div style={{
      padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)',
      borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)',
      background: 'var(--color-surface-elevated)',
    }}>
      <StickyNote size={32} style={{ marginBottom: 'var(--space-3)', opacity: 0.5 }} />
      <div style={{ fontWeight: 600, fontSize: 'var(--font-base)', color: 'var(--color-text-secondary)' }}>
        Belum ada catatan
      </div>
      <div style={{ fontSize: 'var(--font-sm)', marginTop: 'var(--space-1)' }}>
        Catatan kolaborasi dan komunikasi dengan partner akan tampil di sini.
      </div>
    </div>
  )

  return (
    <>
      <DetailPageTemplate
        onBack={() => navigate('/business-dev/partners')}
        icon={<Handshake size={20} />}
        title={isLoading ? 'Memuat...' : (p?.name ?? 'Partner')}
        badges={<Badge label={getMOUBadgeLabel(p?.mou_status)} variant={getMOUBadgeVariant(p?.mou_status)} />}
        actions={actions}
        tabs={[
          { id: 'overview', label: 'Ringkasan', icon: <Handshake size={14} />, content: overviewTab },
          { id: 'mou', label: 'MOU', icon: <FileText size={14} />, content: mouTab },
          { id: 'notes', label: 'Catatan', icon: <StickyNote size={14} />, content: notesTab },
        ]}
      />

      {showMOUDialog && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 400,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }} onClick={() => setShowMOUDialog(false)}>
          <div style={{
            background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', width: 480, overflow: 'hidden',
          }} onClick={(e) => e.stopPropagation()}>
            <div style={{
              padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)',
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            }}>
              <h3 style={{ fontSize: 'var(--font-base)', fontWeight: 700 }}>Tambah MOU</h3>
              <button onClick={() => setShowMOUDialog(false)} style={{
                background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)',
              }}>
                <X size={16} />
              </button>
            </div>
            <div style={{ padding: 'var(--space-5)' }}>
              <p style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginBottom: 'var(--space-4)' }}>
                Formulir penambahan MOU akan tersedia di pembaruan berikutnya.
              </p>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-2)' }}>
                <button
                  onClick={() => setShowMOUDialog(false)}
                  style={{
                    padding: '8px 16px', borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--color-border)', background: 'var(--color-surface)',
                    cursor: 'pointer', fontSize: 'var(--font-sm)',
                  }}
                >
                  Batal
                </button>
                <button
                  onClick={() => {
                    toast.info('Fitur tambah MOU segera hadir')
                    setShowMOUDialog(false)
                  }}
                  style={{
                    padding: '8px 16px', borderRadius: 'var(--radius-md)',
                    border: 'none', background: 'var(--color-primary)', color: '#fff',
                    cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 600,
                  }}
                >
                  Segera Hadir
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
