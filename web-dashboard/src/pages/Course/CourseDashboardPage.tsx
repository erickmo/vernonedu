import { useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { BookOpen, Calendar, FolderTree, Pencil, CheckCircle2 } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { courseService } from '@/services/course.service'
import { apiClient } from '@/services/api.client'

const PRICE_TYPE_OPTIONS = [
  { value: 'per_student',             label: 'Per Siswa' },
  { value: 'per_batch',               label: 'Per Batch' },
  { value: 'per_session',             label: 'Per Pertemuan' },
  { value: 'per_student_per_session', label: 'Per Siswa Per Pertemuan' },
  { value: 'by_request',              label: 'Nego / By Request' },
]

export default function CourseDashboardPage() {
  const { courseId } = useParams<{ courseId: string }>()
  const navigate = useNavigate()

  const [showTypeForm, setShowTypeForm] = useState(false)
  const [typeFormData, setTypeFormData] = useState({
    type_name: '',
    normal_price: 0,
    min_price: 0,
    min_participants: 1,
    max_participants: 30,
    min_sessions: 1,
    max_sessions: 12,
    price_type: 'per_student',
    target_audience: '',
  })

  const { data: course, isLoading: loadingCourse } = useQuery({
    queryKey: ['course', courseId],
    queryFn: () => courseService.getById(courseId!),
  })

  const { data: versions = [], isLoading: loadingVersions } = useQuery({
    queryKey: ['course-versions', courseId],
    queryFn: async () => {
      const data = await apiClient.get<any>(`/curriculum/versions?course_id=${courseId}`)
      return (data as any).items ?? data ?? []
    },
  })

  const { data: batches = [], isLoading: loadingBatches } = useQuery({
    queryKey: ['course-batches', courseId],
    queryFn: async () => {
      const data = await apiClient.get<any>(`/course-batches?course_id=${courseId}`)
      return (data as any).items ?? data ?? []
    },
  })

  const { data: courseTypes = [], refetch: refetchTypes } = useQuery({
    queryKey: ['course-types', courseId],
    queryFn: async () => {
      const data = await apiClient.get<any>(`/curriculum/courses/${courseId}/types`)
      return (data as any)?.items ?? (data as any)?.data ?? []
    },
  })

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Kursus',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/course/${courseId}/edit`),
      variant: 'default',
    },
  ]

  async function handleCreateType(e: React.FormEvent) {
    e.preventDefault()
    try {
      await apiClient.post(`/curriculum/courses/${courseId}/types`, typeFormData)
      setShowTypeForm(false)
      setTypeFormData({
        type_name: '',
        normal_price: 0,
        min_price: 0,
        min_participants: 1,
        max_participants: 30,
        min_sessions: 1,
        max_sessions: 12,
        price_type: 'per_student',
        target_audience: '',
      })
      refetchTypes()
    } catch {
      alert('Gagal membuat tipe kursus')
    }
  }

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

  const courseTypesTab = (
    <div>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 'var(--space-3)' }}>
        <button
          onClick={() => setShowTypeForm(v => !v)}
          style={{
            padding: '6px 16px', borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary)', color: '#fff', border: 'none', cursor: 'pointer',
            fontSize: 'var(--font-sm)', fontWeight: 600,
          }}
        >
          {showTypeForm ? 'Batal' : '+ Tambah Tipe'}
        </button>
      </div>

      {showTypeForm && (
        <form onSubmit={handleCreateType} style={{
          padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
          marginBottom: 'var(--space-4)', display: 'grid', gap: 'var(--space-3)',
        }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-3)' }}>
            <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
              Tipe Kursus *
              <select
                value={typeFormData.type_name}
                onChange={e => setTypeFormData(p => ({ ...p, type_name: e.target.value }))}
                required
                style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
              >
                <option value="">Pilih tipe...</option>
                <option value="regular">Regular</option>
                <option value="private">Private</option>
                <option value="company_training">Inhouse Training</option>
                <option value="collab_school">Kolaborasi Sekolah</option>
                <option value="collab_university">Kolaborasi Universitas</option>
                <option value="program_karir">Program Karir</option>
              </select>
            </label>

            <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
              Tipe Harga *
              <select
                value={typeFormData.price_type}
                onChange={e => setTypeFormData(p => ({ ...p, price_type: e.target.value }))}
                style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
              >
                {PRICE_TYPE_OPTIONS.map(o => (
                  <option key={o.value} value={o.value}>{o.label}</option>
                ))}
              </select>
            </label>

            {['normal_price', 'min_price'].map(field => (
              <label key={field} style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
                {field === 'normal_price' ? 'Harga Normal (IDR)' : 'Harga Minimum (IDR)'}
                <input
                  type="number" min={0}
                  value={typeFormData[field as keyof typeof typeFormData] as number}
                  onChange={e => setTypeFormData(p => ({ ...p, [field]: Number(e.target.value) }))}
                  style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
                />
              </label>
            ))}

            {[
              { key: 'min_participants', label: 'Min Peserta' },
              { key: 'max_participants', label: 'Max Peserta' },
              { key: 'min_sessions', label: 'Min Pertemuan' },
              { key: 'max_sessions', label: 'Max Pertemuan' },
            ].map(({ key, label }) => (
              <label key={key} style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
                {label}
                <input
                  type="number" min={1}
                  value={typeFormData[key as keyof typeof typeFormData] as number}
                  onChange={e => setTypeFormData(p => ({ ...p, [key]: Number(e.target.value) }))}
                  style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
                />
              </label>
            ))}
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button type="submit" style={{
              padding: '8px 20px', borderRadius: 'var(--radius-md)',
              background: 'var(--color-primary)', color: '#fff', border: 'none',
              cursor: 'pointer', fontWeight: 600,
            }}>
              Simpan Tipe
            </button>
          </div>
        </form>
      )}

      {courseTypes.length === 0 && !showTypeForm ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Belum ada tipe kursus. Tambahkan tipe pertama.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
          {(courseTypes as any[]).map((t: any) => (
            <div key={t.id} style={{
              padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
              display: 'grid', gridTemplateColumns: '1fr auto', alignItems: 'center',
            }}>
              <div>
                <div style={{ fontWeight: 600 }}>{t.type_name}</div>
                <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
                  {PRICE_TYPE_OPTIONS.find(o => o.value === t.price_type)?.label ?? t.price_type}
                  {' · '}Rp {(t.normal_price ?? 0).toLocaleString('id-ID')}
                  {' · '}{t.min_sessions ?? 1}–{t.max_sessions ?? 1} pertemuan
                  {' · '}{t.min_participants ?? 1}–{t.max_participants ?? 30} peserta
                </div>
              </div>
              <span style={{
                padding: '2px 10px', borderRadius: 'var(--radius-full)',
                fontSize: 'var(--font-xs)', fontWeight: 600,
                background: t.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
                color: t.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
              }}>
                {t.is_active ? 'Aktif' : 'Nonaktif'}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/course')}
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
        { id: 'types', label: 'Tipe Kursus', icon: <BookOpen size={14} />, content: courseTypesTab },
        { id: 'versions', label: 'Versi Silabus', icon: <FolderTree size={14} />, content: versionsTab },
        { id: 'batches', label: 'Batch Kelas', icon: <Calendar size={14} />, content: batchesTab },
      ]}
    />
  )
}
