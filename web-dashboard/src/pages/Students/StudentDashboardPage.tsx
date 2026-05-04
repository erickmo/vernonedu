import { useParams, useNavigate } from 'react-router-dom'
import { User, Mail, Phone, Pencil } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { studentService } from '@/services/student.service'

export default function StudentDashboardPage() {
  const { studentId } = useParams<{ studentId: string }>()
  const navigate = useNavigate()

  const { data: student, isLoading: loadingStudent } = useQuery({
    queryKey: ['student', studentId],
    queryFn: () => studentService.getById(studentId!),
  })

  const { data: enrollments = [], isLoading: loadingEnrollments } = useQuery({
    queryKey: ['student-enrollments', studentId],
    queryFn: () => studentService.getEnrollmentHistory(studentId!),
  })

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Siswa',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/students/${studentId}/edit`),
      variant: 'default',
    },
  ]

  function InfoCard({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
    return (
      <div style={{
        padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)',
        background: 'var(--color-surface-elevated)', display: 'flex', alignItems: 'center', gap: 'var(--space-3)',
      }}>
        <div style={{
          width: 40, height: 40, borderRadius: 'var(--radius-md)', background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)',
        }}>
          {icon}
        </div>
        <div>
          <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>{label}</div>
          <div style={{ fontSize: 'var(--font-base)', fontWeight: 600 }}>{value}</div>
        </div>
      </div>
    )
  }

  const overviewTab = (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 'var(--space-3)' }}>
      <InfoCard
        icon={<Mail size={18} />}
        label="Email"
        value={student?.email || '—'}
      />
      <InfoCard
        icon={<Phone size={18} />}
        label="Telepon"
        value={student?.phone || 'Tidak ada'}
      />
      <InfoCard
        icon={<User size={18} />}
        label="Total Enrollment"
        value={String(enrollments.length)}
      />
    </div>
  )

  const enrollmentsTab = (
    <div>
      {loadingEnrollments ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>Memuat...</div>
      ) : enrollments.length === 0 ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Belum ada enrollment untuk siswa ini.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
          {enrollments.map((e: any) => (
            <div key={e.id} style={{
              padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            }}>
              <div style={{ fontWeight: 600 }}>{e.batch_name || e.course_name || 'Batch'}</div>
              <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
                {e.enrollment_date && `Terdaftar: ${new Date(e.enrollment_date * 1000).toLocaleDateString('id-ID')}`}
                {e.status && ` · ${e.status}`}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/students')}
      icon={<User size={20} />}
      title={loadingStudent ? 'Memuat...' : (student?.name ?? 'Siswa')}
      badges={
        <>
          {student?.is_active === false && (
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px', borderRadius: 'var(--radius-full)',
              fontSize: 'var(--font-xs)', fontWeight: 600,
              background: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)',
            }}>
              Alumni
            </span>
          )}
        </>
      }
      actions={actions}
      tabs={[
        { id: 'overview', label: 'Ringkasan', icon: <User size={14} />, content: overviewTab },
        { id: 'enrollments', label: 'Enrollment', icon: <Mail size={14} />, content: enrollmentsTab },
      ]}
    />
  )
}
