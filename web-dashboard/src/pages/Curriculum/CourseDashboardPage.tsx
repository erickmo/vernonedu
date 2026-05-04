import { useParams, useNavigate, Link } from 'react-router-dom'
import { BookOpen, Calendar, FolderTree, Pencil, CheckCircle2 } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { courseService } from '@/services/course.service'

export default function CourseDashboardPage() {
  const { courseId } = useParams<{ courseId: string }>()
  const navigate = useNavigate()

  const { data: course, isLoading: loadingCourse } = useQuery({
    queryKey: ['course', courseId],
    queryFn: () => courseService.getById(courseId!),
  })

  const { data: versions = [], isLoading: loadingVersions } = useQuery({
    queryKey: ['course-versions', courseId],
    queryFn: async () => {
      const res = await fetch(`/api/v1/curriculum/versions?course_id=${courseId}`)
      const data = await res.json()
      return data.items ?? data ?? []
    },
  })

  const { data: batches = [], isLoading: loadingBatches } = useQuery({
    queryKey: ['course-batches', courseId],
    queryFn: async () => {
      const res = await fetch(`/api/v1/course-batches?course_id=${courseId}`)
      const data = await res.json()
      return data.items ?? data ?? []
    },
  })

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Kursus',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/curriculum/${courseId}/edit`),
      variant: 'default',
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

  function formatDate(ts: number | undefined) {
    if (!ts) return '—'
    return new Intl.DateTimeFormat('id-ID', {
      day: '2-digit', month: 'short', year: 'numeric',
    }).format(new Date(ts * 1000))
  }

  const overviewTab = (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 'var(--space-3)' }}>
        <StatCard icon={<FolderTree size={18} />} label="Versi Silabus" value={course?.version_count ?? 0} color="var(--color-primary)" />
        <StatCard icon={<Calendar size={18} />} label="Total Batch" value={course?.batch_count ?? 0} color="var(--color-secondary)" />
        <StatCard icon={<CheckCircle2 size={18} />} label="Status" value={course?.is_active ? 'Aktif' : 'Nonaktif'} color={course?.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)'} />
      </div>
    </div>
  )

  const versionsTab = (
    <div>
      {loadingVersions ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>Memuat...</div>
      ) : versions.length === 0 ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Belum ada versi silabus untuk kursus ini.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
          {versions.map((v: any) => (
            <div key={v.id ?? v.version_id} style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            }}>
              <div>
                <div style={{ fontWeight: 600 }}>Versi {v.version_number ?? v.version}</div>
                {v.description && (
                  <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
                    {v.description.length > 100 ? v.description.slice(0, 100) + '...' : v.description}
                  </div>
                )}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                <span style={{
                  display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
                  fontSize: 'var(--font-xs)', fontWeight: 600,
                  background: v.is_approved ? 'var(--color-success-light)' : 'var(--color-warning-light)',
                  color: v.is_approved ? 'var(--color-success-dark)' : 'var(--color-warning-dark)',
                }}>
                  {v.is_approved ? 'Disetujui' : 'Draft'}
                </span>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)' }}>
                  {formatDate(v.created_at)}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )

  const batchesTab = (
    <div>
      {loadingBatches ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>Memuat...</div>
      ) : batches.length === 0 ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Belum ada batch kelas untuk kursus ini.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
          {batches.map((b: any) => (
            <Link
              key={b.id ?? b.batch_id}
              to={`/course-batches/${b.id ?? b.batch_id}`}
              style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
                textDecoration: 'none', color: 'inherit',
              }}
            >
              <div>
                <div style={{ fontWeight: 600 }}>{b.name ?? b.batch_name}</div>
                <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
                  {b.facilitator_name || 'Belum ada fasilitator'}
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <span style={{
                  display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
                  fontSize: 'var(--font-xs)', fontWeight: 600,
                  background: b.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
                  color: b.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
                }}>
                  {b.is_active ? 'Aktif' : 'Selesai'}
                </span>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginTop: 4 }}>
                  {b.enrollment_count ?? 0}/{b.max_participants ?? '∞'} peserta
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/curriculum')}
      icon={<BookOpen size={20} />}
      title={loadingCourse ? 'Memuat...' : (course?.name ?? 'Kursus')}
      badges={
        <>
          {!course?.is_active && (
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px', borderRadius: 'var(--radius-full)',
              fontSize: 'var(--font-xs)', fontWeight: 600,
              background: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)',
            }}>
              Nonaktif
            </span>
          )}
        </>
      }
      actions={actions}
      tabs={[
        { id: 'overview', label: 'Ringkasan', icon: <BookOpen size={14} />, content: overviewTab },
        { id: 'versions', label: 'Versi Silabus', icon: <FolderTree size={14} />, content: versionsTab },
        { id: 'batches', label: 'Batch Kelas', icon: <Calendar size={14} />, content: batchesTab },
      ]}
    />
  )
}
