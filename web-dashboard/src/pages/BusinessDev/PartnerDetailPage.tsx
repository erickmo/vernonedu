import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import {
  Handshake, Pencil, Plus, FileText, StickyNote,
  X, Trash2, ExternalLink,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { partnerService } from '@/services/partner.service'
import { toast } from '@/widgets/Toast/Toast'
import { useDeleteConfirmModal } from '@/widgets/Modals/DeleteConfirmModal'
import { DatePicker } from '@/widgets/DatePicker/DatePicker'
import type { MOU, MOUPayload, MOUStatus, Partner } from '@/types/partner.types'

const MOU_STATUSES: { value: MOUStatus; label: string }[] = [
  { value: 'active',     label: 'Aktif' },
  { value: 'expiring',   label: 'Segera Berakhir' },
  { value: 'expired',    label: 'Berakhir' },
  { value: 'terminated', label: 'Dihentikan' },
]

const MOU_BADGE_COLOR: Record<MOUStatus, { bg: string; color: string }> = {
  active:     { bg: 'var(--color-success-light)',  color: 'var(--color-success-dark)' },
  expiring:   { bg: 'var(--color-warning-light)',  color: 'var(--color-warning-dark)' },
  expired:    { bg: 'var(--color-error-light)',    color: 'var(--color-error-dark)' },
  terminated: { bg: 'var(--color-surface-alt)',    color: 'var(--color-text-tertiary)' },
}

const MOU_BADGE_LABEL: Record<string, string> = {
  active:     'MOU Aktif',
  expiring:   'MOU Segera Berakhir',
  expired:    'MOU Berakhir',
  terminated: 'MOU Dihentikan',
}

function StatusBadge({ status }: { status?: string | null }) {
  const s = MOU_BADGE_COLOR[(status as MOUStatus) ?? ''] ?? { bg: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' }
  const label = MOU_BADGE_LABEL[status ?? ''] ?? 'Belum Ada MOU'
  return (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600, background: s.bg, color: s.color,
    }}>
      {label}
    </span>
  )
}

function InfoRow({ label, value }: { label: string; value?: string | null }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: 'var(--space-2) 0', borderBottom: '1px solid var(--color-border)' }}>
      <span style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>{label}</span>
      <span style={{ fontWeight: 500, fontSize: 'var(--font-sm)' }}>{value || '—'}</span>
    </div>
  )
}

const INPUT_STYLE = {
  width: '100%', padding: '8px 12px', borderRadius: 'var(--radius-md)',
  border: '1px solid var(--color-border)', background: 'var(--color-surface)',
  fontSize: 'var(--font-sm)', boxSizing: 'border-box' as const,
}

interface MOUFormModalProps {
  partnerId: string
  mou: MOU | null
  onClose: () => void
}

function MOUFormModal({ partnerId, mou, onClose }: MOUFormModalProps) {
  const queryClient = useQueryClient()
  const isEdit = mou !== null

  const [form, setForm] = useState<MOUPayload>({
    title:           mou?.title ?? '',
    document_number: mou?.document_number ?? '',
    start_date:      mou?.start_date ?? '',
    end_date:        mou?.end_date ?? '',
    status:          mou?.status ?? 'active',
    document_url:    mou?.document_url ?? '',
    notes:           mou?.notes ?? '',
  })

  const mutation = useMutation({
    mutationFn: (payload: MOUPayload) =>
      isEdit
        ? partnerService.updateMOU(mou!.id, payload)
        : partnerService.addMOU(partnerId, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['partner-mous', partnerId] })
      toast.success(isEdit ? 'MOU berhasil diperbarui' : 'MOU berhasil ditambahkan')
      onClose()
    },
    onError: () => toast.error('Terjadi kesalahan, coba lagi'),
  })

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const payload: MOUPayload = {
      ...form,
      end_date:     form.end_date || undefined,
      document_url: form.document_url || undefined,
      notes:        form.notes || undefined,
    }
    mutation.mutate(payload)
  }

  function renderField(id: string, label: string, el: React.ReactNode) {
    return (
      <div style={{ marginBottom: 'var(--space-3)' }}>
        <label htmlFor={id} style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 600, marginBottom: 4 }}>
          {label}
        </label>
        {el}
      </div>
    )
  }

  return (
    <div
      style={{
        position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 400,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}
      onClick={onClose}
    >
      <div
        style={{
          background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', width: 520, maxHeight: '90vh', overflow: 'auto',
        }}
        onClick={e => e.stopPropagation()}
      >
        <div style={{
          padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          position: 'sticky', top: 0, background: 'var(--color-surface-elevated)',
        }}>
          <h3 role="heading" style={{ fontSize: 'var(--font-base)', fontWeight: 700 }}>
            {isEdit ? 'Edit MOU' : 'Tambah MOU'}
          </h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)' }}>
            <X size={16} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ padding: 'var(--space-5)' }}>
          {renderField('title', 'Judul', (
            <input
              id="title"
              value={form.title}
              onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
              required
              style={INPUT_STYLE}
            />
          ))}
          {renderField('document_number', 'No. Dokumen', (
            <input
              id="document_number"
              value={form.document_number}
              onChange={e => setForm(f => ({ ...f, document_number: e.target.value }))}
              required
              style={INPUT_STYLE}
            />
          ))}
          {renderField('start_date', 'Tanggal Mulai', (
            <DatePicker
              id="start_date"
              value={form.start_date}
              onChange={v => setForm(f => ({ ...f, start_date: v }))}
            />
          ))}
          {renderField('end_date', 'Tanggal Berakhir (opsional)', (
            <DatePicker
              id="end_date"
              value={form.end_date ?? ''}
              onChange={v => setForm(f => ({ ...f, end_date: v }))}
            />
          ))}
          {renderField('status', 'Status', (
            <div style={{ display: 'flex', gap: 'var(--space-2)', flexWrap: 'wrap' }}>
              {MOU_STATUSES.map(s => {
                const active = form.status === s.value
                const colors = MOU_BADGE_COLOR[s.value]
                return (
                  <button
                    key={s.value}
                    type="button"
                    onClick={() => setForm(f => ({ ...f, status: s.value }))}
                    style={{
                      padding: '5px 14px',
                      borderRadius: 'var(--radius-full)',
                      border: active ? '2px solid transparent' : '2px solid var(--color-border)',
                      background: active ? colors.bg : 'transparent',
                      color: active ? colors.color : 'var(--color-text-secondary)',
                      fontSize: 'var(--font-sm)',
                      fontWeight: active ? 600 : 400,
                      cursor: 'pointer',
                      transition: 'all 0.15s',
                    }}
                  >
                    {s.label}
                  </button>
                )
              })}
            </div>
          ))}
          {renderField('document_url', 'URL Dokumen (opsional)', (
            <input
              id="document_url"
              type="url"
              value={form.document_url ?? ''}
              onChange={e => setForm(f => ({ ...f, document_url: e.target.value }))}
              style={INPUT_STYLE}
              placeholder="https://..."
            />
          ))}
          {renderField('notes', 'Catatan (opsional)', (
            <textarea
              id="notes"
              value={form.notes ?? ''}
              onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
              rows={3}
              style={{ ...INPUT_STYLE, resize: 'vertical' }}
            />
          ))}

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-2)', marginTop: 'var(--space-4)' }}>
            <button
              type="button"
              onClick={onClose}
              style={{
                padding: '8px 16px', borderRadius: 'var(--radius-md)',
                border: '1px solid var(--color-border)', background: 'var(--color-surface)',
                cursor: 'pointer', fontSize: 'var(--font-sm)',
              }}
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={mutation.isPending}
              style={{
                padding: '8px 16px', borderRadius: 'var(--radius-md)',
                border: 'none', background: 'var(--color-primary)', color: '#fff',
                cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 600,
                opacity: mutation.isPending ? 0.7 : 1,
              }}
            >
              {mutation.isPending ? 'Menyimpan...' : 'Simpan'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function MOUTable({ mous, onEdit, onDelete }: {
  mous: MOU[]
  onEdit: (mou: MOU) => void
  onDelete: (mouId: string) => void
}) {
  return (
    <div style={{ borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)', overflow: 'hidden' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)' }}>
        <thead>
          <tr style={{ background: 'var(--color-surface-alt)' }}>
            {['No. Dokumen', 'Judul', 'Mulai', 'Berakhir', 'Status', 'Aksi'].map(h => (
              <th key={h} style={{
                padding: '10px 12px', textAlign: 'left', fontWeight: 600,
                color: 'var(--color-text-secondary)', fontSize: 'var(--font-xs)',
                textTransform: 'uppercase', letterSpacing: '0.5px',
              }}>
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {mous.map((mou, i) => (
            <tr key={mou.id} style={{ borderTop: i > 0 ? '1px solid var(--color-border)' : undefined }}>
              <td style={{ padding: '10px 12px', fontFamily: 'monospace', fontSize: 'var(--font-xs)' }}>
                {mou.document_number}
              </td>
              <td style={{ padding: '10px 12px' }}>
                {mou.document_url ? (
                  <a
                    href={mou.document_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{ color: 'var(--color-primary)', display: 'flex', alignItems: 'center', gap: 4 }}
                  >
                    {mou.title} <ExternalLink size={12} />
                  </a>
                ) : mou.title}
              </td>
              <td style={{ padding: '10px 12px' }}>{mou.start_date}</td>
              <td style={{ padding: '10px 12px' }}>{mou.end_date ?? '—'}</td>
              <td style={{ padding: '10px 12px' }}><StatusBadge status={mou.status} /></td>
              <td style={{ padding: '10px 12px' }}>
                <div style={{ display: 'flex', gap: 8 }}>
                  <button
                    data-testid={`edit-mou-${mou.id}`}
                    onClick={() => onEdit(mou)}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-secondary)' }}
                    title="Edit MOU"
                  >
                    <Pencil size={14} />
                  </button>
                  <button
                    data-testid={`delete-mou-${mou.id}`}
                    onClick={() => onDelete(mou.id)}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-error)' }}
                    title="Hapus MOU"
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export default function PartnerDetailPage() {
  const { partnerId } = useParams<{ partnerId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const confirmDelete = useDeleteConfirmModal()

  const [mouModalOpen, setMouModalOpen] = useState(false)
  const [editingMOU, setEditingMOU] = useState<MOU | null>(null)

  const { data: partner, isLoading } = useQuery({
    queryKey: ['partner', partnerId],
    queryFn: () => partnerService.getById(partnerId!),
    enabled: !!partnerId,
  })

  const { data: mous = [] } = useQuery({
    queryKey: ['partner-mous', partnerId],
    queryFn: () => partnerService.listMOUs(partnerId!),
    enabled: !!partnerId,
  })

  const deleteMOUMutation = useMutation({
    mutationFn: (mouId: string) => partnerService.deleteMOU(mouId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['partner-mous', partnerId] })
      toast.success('MOU berhasil dihapus')
    },
    onError: () => toast.error('Gagal menghapus MOU'),
  })

  function handleDeleteMOU(mouId: string) {
    if (!window.confirm('Yakin ingin menghapus MOU ini?')) return
    deleteMOUMutation.mutate(mouId)
  }

  function openCreate() {
    setEditingMOU(null)
    setMouModalOpen(true)
  }

  function openEdit(mou: MOU) {
    setEditingMOU(mou)
    setMouModalOpen(true)
  }

  function closeModal() {
    setMouModalOpen(false)
    setEditingMOU(null)
  }

  const p = partner as Partner | undefined

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Partner',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/partners/${partnerId}/edit`),
      variant: 'default',
    },
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: () => confirmDelete('Hapus Partner', 'Yakin ingin menghapus partner ini?', async () => {
        try {
          await partnerService.delete(partnerId!)
          toast.success('Partner berhasil dihapus')
          navigate('/partners')
        } catch {
          toast.error('Gagal menghapus partner')
        }
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
        <h3 style={{
          fontSize: 'var(--font-sm)', fontWeight: 700, marginBottom: 'var(--space-3)',
          color: 'var(--color-text-secondary)', textTransform: 'uppercase', letterSpacing: '0.5px',
        }}>
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
        <StatusBadge status={p?.mou_status} />
      </div>
    </div>
  )

  const mouTab = (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-4)' }}>
        <span style={{ fontWeight: 600, fontSize: 'var(--font-sm)' }}>
          {mous.length} MOU tercatat
        </span>
        <button
          onClick={openCreate}
          style={{
            display: 'flex', alignItems: 'center', gap: 6, padding: '6px 14px',
            borderRadius: 'var(--radius-md)', border: 'none', background: 'var(--color-primary)',
            color: '#fff', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 600,
          }}
        >
          <Plus size={14} /> Tambah MOU
        </button>
      </div>

      {mous.length === 0 ? (
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
      ) : (
        <MOUTable mous={mous} onEdit={openEdit} onDelete={handleDeleteMOU} />
      )}
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
        onBack={() => navigate('/partners')}
        icon={<Handshake size={20} />}
        title={isLoading ? 'Memuat...' : (p?.name ?? 'Partner')}
        badges={<StatusBadge status={p?.mou_status} />}
        actions={actions}
        sections={[
          {
            id: 'overview',
            label: 'Ringkasan',
            icon: <Handshake size={14} />,
            tabs: [{ id: 'detail', label: 'Ringkasan', content: overviewTab }],
          },
          {
            id: 'mou',
            label: 'MOU',
            icon: <FileText size={14} />,
            tabs: [{ id: 'list', label: 'Daftar MOU', content: mouTab }],
          },
          {
            id: 'notes',
            label: 'Catatan',
            icon: <StickyNote size={14} />,
            tabs: [{ id: 'list', label: 'Catatan', content: notesTab }],
          },
        ]}
      />

      {mouModalOpen && (
        <MOUFormModal
          partnerId={partnerId!}
          mou={editingMOU}
          onClose={closeModal}
        />
      )}
    </>
  )
}
