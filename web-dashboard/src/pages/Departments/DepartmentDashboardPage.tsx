import { useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { Building2, BookOpen, Users, GraduationCap, Calendar, Pencil, UserPlus, X, Search, User } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { departmentService } from '@/services/department.service'
import { apiClient } from '@/services/api.client'
import { toast } from '@/widgets/Toast/Toast'

export default function DepartmentDashboardPage() {
  const { deptId } = useParams<{ deptId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [showAssignModal, setShowAssignModal] = useState(false)
  const [leaderSearch, setLeaderSearch] = useState('')
  const [isAssigning, setIsAssigning] = useState(false)

  const { data: dept, isLoading: loadingDept } = useQuery({
    queryKey: ['department', deptId],
    queryFn: () => departmentService.getById(deptId!),
  })

  const { data: batches = [], isLoading: loadingBatches } = useQuery({
    queryKey: ['department-batches', deptId],
    queryFn: () => departmentService.getBatches(deptId!),
  })

  const { data: courses = [], isLoading: loadingCourses } = useQuery({
    queryKey: ['department-courses', deptId],
    queryFn: () => departmentService.getCourses(deptId!),
  })

  const { data: students = [], isLoading: loadingStudents } = useQuery({
    queryKey: ['department-students', deptId],
    queryFn: () => departmentService.getStudents(deptId!),
  })

  const { data: leaderUsers = [] } = useQuery({
    queryKey: ['users-search', leaderSearch],
    queryFn: async () => {
      const res = await apiClient.get<any>(`/users/search?name=${encodeURIComponent(leaderSearch)}&limit=20`)
      const data = (res as any).data ?? res
      const users = Array.isArray(data) ? data : data?.items ?? []
      return users.filter((u: any) => u.roles?.includes('dept_leader'))
    },
    enabled: showAssignModal && leaderSearch.length >= 2,
  })

  const [batchFilter, setBatchFilter] = useState<string>('all')

  const filteredBatches = batchFilter === 'all'
    ? batches
    : batches.filter((b: any) =>
        batchFilter === 'upcoming' ? b.is_active && !b.start_date
        : batchFilter === 'ongoing' ? b.is_active
        : !b.is_active
      )

  async function handleAssignLeader(userId: string, userName: string) {
    setIsAssigning(true)
    try {
      await departmentService.assignLeader(deptId!, userId)
      toast.success(`${userName} ditetapkan sebagai Leader`)
      await queryClient.invalidateQueries({ queryKey: ['department', deptId] })
      setShowAssignModal(false)
      setLeaderSearch('')
    } catch (err) {
      toast.error('Gagal menetapkan Leader')
    } finally {
      setIsAssigning(false)
    }
  }

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Departemen',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/departments/${deptId}/edit`),
      variant: 'default',
    },
    {
      label: dept?.leader_id ? 'Ganti Leader' : 'Tetapkan Leader',
      icon: <UserPlus size={14} />,
      onClick: () => setShowAssignModal(true),
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

  const batchTab = (
    <div>
      <div style={{ display: 'flex', gap: 'var(--space-2)', marginBottom: 'var(--space-4)' }}>
        {[
          { key: 'all', label: 'Semua' },
          { key: 'ongoing', label: 'Berlangsung' },
          { key: 'completed', label: 'Selesai' },
        ].map((f) => (
          <button
            key={f.key}
            onClick={() => setBatchFilter(f.key)}
            style={{
              padding: '6px 14px', borderRadius: 'var(--radius-full)', border: '1px solid var(--color-border)',
              background: batchFilter === f.key ? 'var(--color-primary)' : 'var(--color-surface-elevated)',
              color: batchFilter === f.key ? '#fff' : 'var(--color-text-secondary)',
              fontSize: 'var(--font-sm)', fontWeight: 600, cursor: 'pointer',
            }}
          >
            {f.label}
          </button>
        ))}
      </div>

      {loadingBatches ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>Memuat...</div>
      ) : filteredBatches.length === 0 ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Belum ada batch kelas.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
          {filteredBatches.map((b: any) => (
            <Link
              key={b.batch_id ?? b.id}
              to={`/course-batches/${b.batch_id ?? b.id}`}
              style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
                textDecoration: 'none', color: 'inherit',
              }}
            >
              <div>
                <div style={{ fontWeight: 600 }}>{b.batch_name ?? b.name}</div>
                <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
                  {b.course_name} · {b.facilitator_name || 'Belum ada fasilitator'}
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

  const coursesTab = (
    <div>
      {loadingCourses ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>Memuat...</div>
      ) : courses.length === 0 ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Belum ada kursus di departemen ini.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
          {courses.map((c: any) => (
            <div key={c.course_id ?? c.id} style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            }}>
              <div>
                <div style={{ fontWeight: 600 }}>{c.course_name ?? c.name}</div>
                {c.description && (
                  <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
                    {c.description.length > 100 ? c.description.slice(0, 100) + '...' : c.description}
                  </div>
                )}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
                  {c.batch_count ?? 0} batch
                </span>
                <span style={{
                  display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
                  fontSize: 'var(--font-xs)', fontWeight: 600,
                  background: c.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
                  color: c.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
                }}>
                  {c.is_active ? 'Aktif' : 'Nonaktif'}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )

  const studentsTab = (
    <div>
      {loadingStudents ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>Memuat...</div>
      ) : students.length === 0 ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Belum ada siswa di departemen ini.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
          {students.map((s: any) => (
            <Link
              key={s.student_id ?? s.id}
              to={`/students/${s.student_id ?? s.id}`}
              style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
                textDecoration: 'none', color: 'inherit',
              }}
            >
              <div>
                <div style={{ fontWeight: 600 }}>{s.student_name ?? s.name}</div>
                <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
                  {s.email} {s.phone ? `· ${s.phone}` : ''}
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
                  {s.enrolled_batch_count ?? 0} batch
                </span>
                <span style={{
                  display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
                  fontSize: 'var(--font-xs)', fontWeight: 600,
                  background: s.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
                  color: s.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
                }}>
                  {s.is_active ? 'Aktif' : 'Alumni'}
                </span>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  )

  return (
    <>
    <DetailPageTemplate
      onBack={() => navigate('/departments')}
      icon={<Building2 size={20} />}
      title={loadingDept ? 'Memuat...' : (dept?.name ?? 'Departemen')}
      badges={
        <>
          {!dept?.is_active && (
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px', borderRadius: 'var(--radius-full)',
              fontSize: 'var(--font-xs)', fontWeight: 600,
              background: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)',
            }}>
              Nonaktif
            </span>
          )}
          {dept?.leader_id ? (
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px', borderRadius: 'var(--radius-full)',
              fontSize: 'var(--font-xs)', fontWeight: 600,
              background: 'var(--color-primary-subtle)', color: 'var(--color-primary)',
            }}>
              <User size={12} />
              Leader Ditetapkan
            </span>
          ) : (
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px', borderRadius: 'var(--radius-full)',
              fontSize: 'var(--font-xs)', fontWeight: 600,
              background: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)',
            }}>
              <User size={12} />
              Belum ada Leader
            </span>
          )}
        </>
      }
      actions={actions}
      tabs={[
        { id: 'overview', label: 'Ringkasan', icon: <Building2 size={14} />, content: (
          <div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 'var(--space-3)' }}>
              <StatCard icon={<BookOpen size={18} />} label="Kursus" value={courses.length} color="var(--color-primary)" />
              <StatCard icon={<Calendar size={18} />} label="Batch Aktif" value={batches.filter((b: any) => b.is_active).length} color="var(--color-secondary)" />
              <StatCard icon={<Users size={18} />} label="Siswa" value={students.length} color="var(--color-info)" />
              <StatCard icon={<GraduationCap size={18} />} label="Batch Selesai" value={batches.filter((b: any) => !b.is_active).length} color="var(--color-success-dark)" />
            </div>
          </div>
        )},
        { id: 'batches', label: 'Batch Kelas', icon: <Calendar size={14} />, content: batchTab },
        { id: 'courses', label: 'Kursus', icon: <BookOpen size={14} />, content: coursesTab },
        { id: 'students', label: 'Siswa', icon: <Users size={14} />, content: studentsTab },
      ]}
    />

    {showAssignModal && (
      <div style={{
        position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 400,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }} onClick={() => !isAssigning && setShowAssignModal(false)}>
        <div style={{
          background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', width: 420, maxHeight: 480, overflow: 'hidden',
          display: 'flex', flexDirection: 'column',
        }} onClick={(e) => e.stopPropagation()}>
          <div style={{
            padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)',
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          }}>
            <h3 style={{ fontSize: 'var(--font-base)', fontWeight: 700 }}>Tetapkan Leader</h3>
            <button onClick={() => !isAssigning && setShowAssignModal(false)} style={{
              background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)',
            }}>
              <X size={16} />
            </button>
          </div>
          <div style={{ padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)' }}>
            <div style={{ position: 'relative' }}>
              <Search size={14} style={{
                position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)',
                color: 'var(--color-text-tertiary)',
              }} />
              <input
                type="text"
                value={leaderSearch}
                onChange={(e) => setLeaderSearch(e.target.value)}
                placeholder="Cari nama user (role: dept_leader)..."
                autoFocus
                style={{
                  width: '100%', padding: '8px 12px 8px 32px', borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                  background: 'var(--color-surface)', color: 'var(--color-text)',
                }}
              />
            </div>
          </div>
          <div style={{ flex: 1, overflowY: 'auto', padding: 'var(--space-2)' }}>
            {leaderSearch.length < 2 ? (
              <div style={{ padding: 'var(--space-6)', textAlign: 'center', color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>
                Ketik minimal 2 karakter untuk mencari
              </div>
            ) : leaderUsers.length === 0 ? (
              <div style={{ padding: 'var(--space-6)', textAlign: 'center', color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>
                Tidak ada user dengan role dept_leader ditemukan
              </div>
            ) : (
              leaderUsers.map((u: any) => (
                <button
                  key={u.id}
                  disabled={isAssigning}
                  onClick={() => handleAssignLeader(u.id, u.name)}
                  style={{
                    display: 'flex', alignItems: 'center', gap: 'var(--space-3)',
                    width: '100%', padding: 'var(--space-3) var(--space-4)',
                    borderRadius: 'var(--radius-md)', border: 'none', cursor: 'pointer',
                    background: u.id === dept?.leader_id ? 'var(--color-primary-subtle)' : 'transparent',
                    textAlign: 'left',
                  }}
                >
                  <div style={{
                    width: 32, height: 32, borderRadius: 'var(--radius-full)',
                    background: 'var(--color-primary-subtle)', display: 'flex',
                    alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)',
                    flexShrink: 0,
                  }}>
                    <User size={14} />
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontWeight: 600, fontSize: 'var(--font-sm)' }}>{u.name}</div>
                    <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)' }}>{u.email}</div>
                  </div>
                  {u.id === dept?.leader_id && (
                    <span style={{
                      marginLeft: 'auto', fontSize: 'var(--font-min)', fontWeight: 600,
                      padding: '2px 8px', borderRadius: 'var(--radius-full)',
                      background: 'var(--color-primary)', color: '#fff',
                    }}>
                      Saat ini
                    </span>
                  )}
                </button>
              ))
            )}
          </div>
        </div>
      </div>
    )}
    </>
  )
}
