import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/auth.store'
import { hasAnyRole } from '@/types/auth.types'
import { departmentService } from '@/services/department.service'
import { courseBatchService } from '@/services/course-batch.service'
import { PageHeader } from '@/layouts/PageHeader/PageHeader'
import { DeptCard } from './components/DeptCard'
import type { DeptSummary } from './components/DeptCard'
import type { CourseSummary } from './components/CourseRow'
import type { BatchSummary } from './components/BatchChip'
import { StrukturTreeView } from './components/StrukturTreeView'
import styles from './StrukturPage.module.css'

const VIEW_KEY = 'struktur_view'
const CAN_ADD_DEPT: Parameters<typeof hasAnyRole>[1] = ['director', 'education_leader']

function normalizeStatus(raw: string): BatchSummary['status'] {
  if (raw === 'active') return 'active'
  if (raw === 'completed' || raw === 'done') return 'completed'
  return raw
}

function toBatchSummary(b: any): BatchSummary {
  return {
    id: b.id ?? b.batch_id ?? '',
    name: b.name ?? b.batch_name ?? '',
    status: normalizeStatus(b.status ?? ''),
    studentCount: b.student_count ?? b.studentCount ?? 0,
    sessionDone: b.session_done ?? b.sessionDone ?? 0,
    sessionTotal: b.session_total ?? b.sessionTotal ?? 0,
  }
}

export default function StrukturPage() {
  const navigate = useNavigate()
  const { user } = useAuthStore()
  const [view, setView] = useState<'card' | 'tree'>(() => {
    const saved = localStorage.getItem(VIEW_KEY)
    return saved === 'tree' ? 'tree' : 'card'
  })
  const [depts, setDepts] = useState<DeptSummary[]>([])
  const [loading, setLoading] = useState(true)

  const canAddDept = hasAnyRole(user, CAN_ADD_DEPT)

  useEffect(() => {
    const loadAll = async () => {
      setLoading(true)
      try {
        const deptsRaw = await departmentService.list({ limit: 100 })
        const deptList: any[] = deptsRaw.items ?? []

        const composed: DeptSummary[] = await Promise.all(
          deptList.map(async (dept) => {
            let courses: CourseSummary[] = []
            try {
              const rawCourses: any[] = await departmentService.getCourses(dept.id)
              courses = await Promise.all(
                rawCourses.map(async (c): Promise<CourseSummary> => {
                  let batches: BatchSummary[] = []
                  try {
                    const batchRes = await courseBatchService.list({ course_id: c.id, limit: 10 })
                    const batchList: any[] = (batchRes as any).data?.data
                      ?? (batchRes as any).data
                      ?? (batchRes as any).items
                      ?? []
                    batches = Array.isArray(batchList) ? batchList.map(toBatchSummary) : []
                  } catch {
                    batches = []
                  }
                  return { id: c.id, name: c.name, batches }
                })
              )
            } catch {
              courses = []
            }
            return { id: dept.id, name: dept.name, courses }
          })
        )
        setDepts(composed)
      } finally {
        setLoading(false)
      }
    }
    loadAll()
  }, [])

  const handleSetView = (v: 'card' | 'tree') => {
    setView(v)
    localStorage.setItem(VIEW_KEY, v)
  }

  const viewToggle = (
    <div className={styles.viewToggle}>
      <button
        className={`${styles.toggleBtn} ${view === 'card' ? styles.active : ''}`}
        onClick={() => handleSetView('card')}
      >
        ⊞ Card
      </button>
      <button
        className={`${styles.toggleBtn} ${view === 'tree' ? styles.active : ''}`}
        onClick={() => handleSetView('tree')}
      >
        ≡ Tree
      </button>
    </div>
  )

  return (
    <div className={styles.page}>
      <PageHeader
        title="Struktur Pendidikan"
        subtitle="Departemen → Course → Kelas aktif"
        actions={viewToggle}
      />

      <div className={styles.body}>
        {loading && (
          <>
            <div className={styles.loadingRow} />
            <div className={styles.loadingRow} />
          </>
        )}

        {!loading && depts.length === 0 && (
          <div className={styles.empty}>
            <p>Belum ada departemen.</p>
          </div>
        )}

        {!loading && view === 'card' && depts.map((dept, i) => (
          <DeptCard key={dept.id} dept={dept} user={user} defaultExpanded={i === 0} />
        ))}

        {!loading && view === 'tree' && (
          <StrukturTreeView depts={depts} />
        )}

        {!loading && canAddDept && (
          <button
            className={styles.addDeptBtn}
            onClick={() => navigate('/pengembangan/departments/new')}
          >
            + Tambah Departemen
          </button>
        )}
      </div>
    </div>
  )
}
