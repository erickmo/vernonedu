import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import type { VernonEduUser } from '@/types/auth.types'
import { hasAnyRole } from '@/types/auth.types'
import { CourseRow } from './CourseRow'
import type { CourseSummary } from './CourseRow'
import styles from './DeptCard.module.css'

export interface DeptSummary {
  id: string
  name: string
  courses: CourseSummary[]
}

const CAN_ADD_COURSE: Parameters<typeof hasAnyRole>[1] = [
  'director', 'education_leader', 'dept_leader',
]

interface Props {
  dept: DeptSummary
  user: VernonEduUser | null
  defaultExpanded?: boolean
}

export function DeptCard({ dept, user, defaultExpanded = true }: Props) {
  const navigate = useNavigate()
  const [expanded, setExpanded] = useState(defaultExpanded)
  const canAddCourse = hasAnyRole(user, CAN_ADD_COURSE)

  const activeBatchCount = dept.courses.reduce(
    (sum, c) => sum + c.batches.filter(b => b.status === 'active').length,
    0,
  )

  return (
    <div className={styles.card}>
      <div
        className={`${styles.header} ${!expanded ? styles.headerCollapsed : ''}`}
        onClick={() => setExpanded(e => !e)}
      >
        <div className={styles.headerLeft}>
          <span>📁</span>
          <span className={styles.headerName}>{dept.name}</span>
        </div>
        <div className={styles.headerRight} onClick={e => e.stopPropagation()}>
          {expanded ? (
            <>
              <span className={styles.countBadge}>{dept.courses.length} course</span>
              {canAddCourse && (
                <button
                  className={styles.addCourseBtn}
                  onClick={() => navigate('/course/new')}
                >
                  + Course
                </button>
              )}
            </>
          ) : (
            <span className={styles.countBadge}>
              {dept.courses.length} course · {activeBatchCount} aktif
            </span>
          )}
          <span className={styles.toggleIcon}>{expanded ? '▾' : '▸'}</span>
        </div>
      </div>

      {expanded && (
        <div className={styles.body}>
          {dept.courses.map((course, i) => (
            <CourseRow
              key={course.id}
              course={course}
              user={user}
              defaultExpanded={i === 0}
            />
          ))}
          {dept.courses.length === 0 && (
            <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)', margin: 0 }}>
              Belum ada course di departemen ini.
            </p>
          )}
        </div>
      )}
    </div>
  )
}
