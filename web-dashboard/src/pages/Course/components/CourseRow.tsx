import { useNavigate } from 'react-router-dom'
import { useState } from 'react'
import type { VernonEduUser } from '@/types/auth.types'
import { hasAnyRole } from '@/types/auth.types'
import { BatchChip } from './BatchChip'
import type { BatchSummary } from './BatchChip'
import styles from './CourseRow.module.css'

export interface CourseSummary {
  id: string
  name: string
  batches: BatchSummary[]
}

const CAN_ADD_BATCH: Parameters<typeof hasAnyRole>[1] = [
  'director', 'education_leader', 'dept_leader', 'course_owner', 'operation_admin',
]

interface Props {
  course: CourseSummary
  user: VernonEduUser | null
  defaultExpanded?: boolean
}

export function CourseRow({ course, user, defaultExpanded = true }: Props) {
  const navigate = useNavigate()
  const [expanded, setExpanded] = useState(defaultExpanded)
  const canAddBatch = hasAnyRole(user, CAN_ADD_BATCH)

  const activeBatches = course.batches.filter(b => b.status === 'active')
  const doneBatches = course.batches.filter(b => b.status === 'completed')

  const handleAddBatch = () => navigate(`/course-batches/new?course_id=${course.id}`)

  if (!expanded) {
    return (
      <div className={styles.row}>
        <div className={`${styles.rowHeader} ${styles.rowHeaderCollapsed}`}>
          <div className={styles.courseInfo}>
            <span>📚</span>
            <span className={styles.courseName}>{course.name}</span>
            {activeBatches.length > 0 && (
              <span className={`${styles.badge} ${styles.badgeActive}`}>
                {activeBatches.length} aktif
              </span>
            )}
            {doneBatches.length > 0 && (
              <span className={`${styles.badge} ${styles.badgeDone}`}>
                {doneBatches.length} selesai
              </span>
            )}
            {course.batches.length === 0 && (
              <span className={`${styles.badge} ${styles.badgeEmpty}`}>Belum ada batch</span>
            )}
          </div>
          <div className={styles.rowActions}>
            {canAddBatch && (
              <button className={styles.addBatchBtn} onClick={handleAddBatch}>+ Batch</button>
            )}
            <button className={styles.toggleBtn} onClick={() => setExpanded(true)}>▸</button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className={styles.row}>
      <div className={styles.rowHeader}>
        <div className={styles.courseInfo}>
          <span>📚</span>
          <span className={styles.courseName}>{course.name}</span>
        </div>
        <div className={styles.rowActions}>
          <button className={styles.detailLink} onClick={() => navigate(`/course/${course.id}`)}>
            Lihat detail →
          </button>
          <button className={styles.toggleBtn} onClick={() => setExpanded(false)}>▾</button>
        </div>
      </div>

      <div className={styles.batchList}>
        {course.batches.map(batch => (
          <BatchChip key={batch.id} batch={batch} />
        ))}
        {canAddBatch && (
          <button className={styles.addBatchChip} onClick={handleAddBatch}>+ Batch</button>
        )}
        {!canAddBatch && course.batches.length === 0 && (
          <span style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)' }}>
            Belum ada batch
          </span>
        )}
      </div>
    </div>
  )
}
