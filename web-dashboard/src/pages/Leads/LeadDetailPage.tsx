import { useParams, useNavigate } from 'react-router-dom'
import { UserSearch, Pencil, UserCheck, Trash2, MessageSquare } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { leadService } from '@/services/lead.service'
import { toast } from '@/widgets/Toast/Toast'

function formatDate(dateStr?: string | null) {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(dateStr))
}

const STATUS_COLORS: Record<string, { background: string; color: string }> = {
  new:       { background: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  contacted: { background: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  qualified: { background: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  lost:      { background: 'var(--color-danger-light)',  color: 'var(--color-danger-dark)' },
}

function StatusBadge({ status }: { status?: string }) {
  const s = STATUS_COLORS[status ?? ''] ?? { background: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' }
  return (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600, ...s,
    }}>
      {status ?? '—'}
    </span>
  )
}

function InfoCard({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{
      padding: 'var(--space-4)', border: '1px solid var(--color-border)',
      borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)',
    }}>
      <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>
        {label}
      </div>
      <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{children}</div>
    </div>
  )
}

export default function LeadDetailPage() {
  const { leadId } = useParams<{ leadId: string }>()
  const navigate = useNavigate()

  const { data } = useQuery({
    queryKey: ['lead', leadId],
    queryFn: () => leadService.getById(leadId!),
  })

  const { data: crmData } = useQuery({
    queryKey: ['lead-crm-logs', leadId],
    queryFn: () => leadService.getCrmLogs(leadId!),
  })

  const lead = data as any
  const logs = Array.isArray(crmData) ? crmData : (crmData as any)?.items ?? []

  const actions: DetailPageAction[] = [
    {
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/leads/${leadId}/edit`),
      variant: 'default',
    },
    {
      label: 'Convert to Student',
      icon: <UserCheck size={14} />,
      onClick: async () => {
        try {
          await leadService.convertToStudent(leadId!)
          toast.success('Lead berhasil dikonversi menjadi siswa')
          navigate('/students')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal mengkonversi lead')
        }
      },
      variant: 'success',
    },
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus lead ini?')) return
        try {
          await leadService.delete(leadId!)
          toast.success('Lead berhasil dihapus')
          navigate('/leads')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus lead')
        }
      },
      variant: 'danger',
    },
  ]

  const detailContent = (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 'var(--space-3)' }}>
      <InfoCard label="Nama">{lead?.name || '—'}</InfoCard>
      <InfoCard label="Email">{lead?.email || '—'}</InfoCard>
      <InfoCard label="Telepon">{lead?.phone || '—'}</InfoCard>
      <InfoCard label="Status"><StatusBadge status={lead?.status} /></InfoCard>
      <InfoCard label="Sumber">{(lead as any)?.source?.name || '—'}</InfoCard>
      <InfoCard label="Dibuat">{formatDate(lead?.created_at)}</InfoCard>
      <InfoCard label="Catatan">{lead?.notes || '—'}</InfoCard>
    </div>
    {Array.isArray((lead as any)?.interests) && (lead as any).interests.length > 0 && (
      <div style={{ marginTop: 'var(--space-3)' }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 8 }}>Minat</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {(lead as any).interests.map((i: any) => (
            <span key={i.id} style={{
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '4px 10px', borderRadius: 'var(--radius-full)',
              background: 'var(--color-primary-subtle)', color: 'var(--color-primary)',
              fontSize: 'var(--font-xs)', fontWeight: 600,
            }}>
              <span style={{ opacity: 0.7 }}>[{(i.entity_type as string)?.replace('_', ' ')}]</span>
              {i.entity_name ?? i.entity_id}
            </span>
          ))}
        </div>
      </div>
    )}
  )

  const crmLogsContent = (
    <div>
      {logs.length === 0 ? (
        <div style={{
          textAlign: 'center', padding: 'var(--space-8)',
          border: '2px dashed var(--color-border)', borderRadius: 'var(--radius-lg)',
        }}>
          <MessageSquare size={32} style={{ color: 'var(--color-text-tertiary)', marginBottom: 'var(--space-2)' }} />
          <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)', margin: 0 }}>
            Belum ada log aktivitas
          </p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-2)' }}>
          {logs.map((log: any, i: number) => (
            <div key={log.id ?? i} style={{
              padding: 'var(--space-3) var(--space-4)',
              border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)',
              background: 'var(--color-surface-elevated)',
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                <span style={{ fontWeight: 600, fontSize: 'var(--font-sm)' }}>
                  {log.contact_method || '—'}
                </span>
                <span style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)' }}>
                  {formatDate(log.date ?? log.created_at)}
                </span>
              </div>
              {log.notes && (
                <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', lineHeight: 1.5 }}>
                  {log.notes}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )

  const status = lead?.status as string | undefined
  const badgeStyle = STATUS_COLORS[status ?? ''] ?? { background: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' }

  return (
    <DetailPageTemplate
      onBack={() => navigate('/leads')}
      icon={<UserSearch size={20} />}
      title={lead?.name || 'Lead'}
      code={lead?.id?.substring(0, 8)?.toUpperCase()}
      badges={
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600, ...badgeStyle,
        }}>
          {status ?? '—'}
        </span>
      }
      actions={actions}
      helpTitle="Lead"
      helpText="Lead adalah calon pelanggan yang tertarik dengan program kursus. Anda dapat mengkonversi lead menjadi siswa setelah memenuhi syarat."
      sections={[
        {
          id: 'info',
          label: 'Informasi Lead',
          icon: <UserSearch size={14} />,
          tabs: [{ id: 'detail', label: 'Detail', content: detailContent }],
        },
        {
          id: 'crm',
          label: 'Aktivitas CRM',
          icon: <MessageSquare size={14} />,
          tabs: [{ id: 'logs', label: 'Log Aktivitas', content: crmLogsContent }],
        },
      ]}
    />
  )
}
