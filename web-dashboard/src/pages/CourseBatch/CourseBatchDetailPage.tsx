import { useParams, useNavigate, Link } from 'react-router-dom'
import { Calendar, Users, DollarSign, Pencil, Trash2 } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { courseBatchService } from '@/services/course-batch.service'
import { toast } from '@/widgets/Toast/Toast'

export default function CourseBatchDetailPage() {
  const { batchId } = useParams<{ batchId: string }>()
  const navigate = useNavigate()

  const { data: batch, isLoading } = useQuery({
    queryKey: ['course-batch', batchId],
    queryFn: () => courseBatchService.getDetail(batchId!),
  })

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Batch',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/course-batches/${batchId}/edit`),
      variant: 'default',
    },
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus batch ini?')) return
        try {
          await courseBatchService.delete(batchId!)
          toast.success('Batch berhasil dihapus')
          navigate('/course-batches')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus batch')
        }
      },
      variant: 'danger' as const,
    },
  ]

  function StatCard({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: number | string; color: string }) {
    return (
      <div style={{
        padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)',
        background: 'var(--color-surface-elevated)', display: 'flex', alignItems: 'center', gap: 'var(--space-3)',
      }}>
        <div style={{
          width: 40, height: 40, borderRadius: 'var(--radius-md)', background: `${color}15`,
          display: 'flex', alignItems: 'center', justifyContent: 'center', color,
        }}>
          {icon}
        </div>
        <div>
          <div style={{ fontSize: 'var(--font-2xl)', fontWeight: 700, lineHeight: 1.2 }}>{value}</div>
          <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>{label}</div>
        </div>
      </div>
    )
  }

  const formatPrice = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency', currency: 'IDR', minimumFractionDigits: 0,
    }).format(amount)
  }

  const formatDate = (ts: number) => {
    return new Intl.DateTimeFormat('id-ID', {
      day: '2-digit', month: 'short', year: 'numeric',
    }).format(new Date(ts * 1000))
  }

  const paymentMethodLabels: Record<string, string> = {
    upfront: 'Pembayaran Penuh',
    scheduled: 'Terjadwal',
    monthly: 'Bulanan',
    batch_lump: 'Sekaligus',
    per_session: 'Per Sesi',
  }

  const overviewTab = (
    <div>
      {isLoading ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Memuat...
        </div>
      ) : batch ? (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 'var(--space-3)', marginBottom: 'var(--space-6)' }}>
            <StatCard
              icon={<Users size={18} />}
              label="Peserta Terdaftar"
              value={batch.enrollment_count ?? 0}
              color="var(--color-primary)"
            />
            <StatCard
              icon={<DollarSign size={18} />}
              label="Pendapatan"
              value={formatPrice(batch.revenue ?? 0)}
              color="var(--color-success-dark)"
            />
            <StatCard
              icon={<Calendar size={18} />}
              label="Status"
              value={batch.is_active ? 'Aktif' : 'Selesai'}
              color={batch.is_active ? 'var(--color-info)' : 'var(--color-text-tertiary)'}
            />
          </div>

          <div style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            display: 'flex', flexDirection: 'column', gap: 'var(--space-4)',
          }}>
            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 600 }}>
                Kursus
              </div>
              <div style={{ fontSize: 'var(--font-base)', fontWeight: 600, marginTop: 4 }}>
                {batch.course_name}
              </div>
            </div>
            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 600 }}>
                Fasilitator
              </div>
              <div style={{ fontSize: 'var(--font-base)', fontWeight: 600, marginTop: 4 }}>
                {batch.facilitator_name || 'Belum ada fasilitator'}
              </div>
            </div>
            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 600 }}>
                Jadwal
              </div>
              <div style={{ fontSize: 'var(--font-base)', fontWeight: 600, marginTop: 4 }}>
                {formatDate(batch.start_date)} — {formatDate(batch.end_date)}
              </div>
            </div>
            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 600 }}>
                Harga
              </div>
              <div style={{ fontSize: 'var(--font-base)', fontWeight: 600, marginTop: 4 }}>
                {formatPrice(batch.price)} · {paymentMethodLabels[batch.payment_method] || batch.payment_method}
              </div>
            </div>
            <div>
              <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 600 }}>
                Kapasitas
              </div>
              <div style={{ fontSize: 'var(--font-base)', fontWeight: 600, marginTop: 4 }}>
                {batch.min_participants || 0} — {batch.max_participants || '∞'} peserta
              </div>
            </div>
          </div>
        </>
      ) : null}
    </div>
  )

  const enrollmentsTab = (
    <div>
      {isLoading ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Memuat...
        </div>
      ) : batch?.enrollments && batch.enrollments.length > 0 ? (
        <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
          {batch.enrollments.map((e: any) => (
            <Link
              key={e.enrollment_id ?? e.id}
              to={`/students/${e.student_id ?? e.student?.id}`}
              style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
                textDecoration: 'none', color: 'inherit',
              }}
            >
              <div>
                <div style={{ fontWeight: 600 }}>{e.student_name || e.student?.name}</div>
                <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
                  {e.student?.email || ''}
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                <span style={{
                  display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
                  fontSize: 'var(--font-xs)', fontWeight: 600,
                  background: e.is_paid ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
                  color: e.is_paid ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
                }}>
                  {e.is_paid ? 'Lunas' : 'Belum Bayar'}
                </span>
                <span style={{
                  display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
                  fontSize: 'var(--font-xs)', fontWeight: 600,
                  background: e.is_active ? 'var(--color-primary-subtle)' : 'var(--color-surface-alt)',
                  color: e.is_active ? 'var(--color-primary)' : 'var(--color-text-tertiary)',
                }}>
                  {e.is_active ? 'Aktif' : 'Nonaktif'}
                </span>
              </div>
            </Link>
          ))}
        </div>
      ) : (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Belum ada pendaftaran untuk batch ini.
        </div>
      )}
    </div>
  )

  const scheduleTab = (
    <div style={{ padding: 'var(--space-8)', textAlign: 'center' }}>
      <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-base)', marginBottom: 'var(--space-2)' }}>
        Belum ada jadwal
      </div>
      <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>
        Jadwal sesi akan ditampilkan di sini setelah ditambahkan.
      </div>
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/course-batches')}
      icon={<Calendar size={20} />}
      title={isLoading ? 'Memuat...' : (batch?.batch_name ?? 'Batch Kelas')}
      badges={
        <>
          {!batch?.is_active && (
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px', borderRadius: 'var(--radius-full)',
              fontSize: 'var(--font-xs)', fontWeight: 600,
              background: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)',
            }}>
              Selesai
            </span>
          )}
        </>
      }
      actions={actions}
      tabs={[
        { id: 'overview', label: 'Ringkasan', icon: <Calendar size={14} />, content: overviewTab },
        { id: 'enrollments', label: 'Pendaftaran', icon: <Users size={14} />, content: enrollmentsTab },
        { id: 'schedule', label: 'Jadwal', icon: <Calendar size={14} />, content: scheduleTab },
      ]}
    />
  )
}
