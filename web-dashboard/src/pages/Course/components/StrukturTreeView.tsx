import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import type { DeptSummary } from './DeptCard'
import styles from './StrukturTreeView.module.css'

interface Props {
  depts: DeptSummary[]
}

export function StrukturTreeView({ depts }: Props) {
  const navigate = useNavigate()
  const [expandedDepts, setExpandedDepts] = useState<Set<string>>(new Set(depts.map(d => d.id)))
  const [expandedCourses, setExpandedCourses] = useState<Set<string>>(new Set())

  const toggleDept = (id: string) => {
    setExpandedDepts(prev => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })
  }

  const toggleCourse = (id: string) => {
    setExpandedCourses(prev => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })
  }

  return (
    <div className={styles.tree}>
      {depts.map(dept => {
        const deptExpanded = expandedDepts.has(dept.id)
        return (
          <div key={dept.id}>
            <div className={styles.deptRow} onClick={() => toggleDept(dept.id)}>
              <span>📁</span>
              <span className={styles.deptLabel}>{dept.name}</span>
              <span className={styles.badge} style={{ background: 'var(--color-primary-subtle)', color: 'var(--color-primary)' }}>
                {dept.courses.length} course
              </span>
              <span className={styles.toggleIcon}>{deptExpanded ? '▾' : '▸'}</span>
            </div>

            {deptExpanded && (
              <div className={styles.courseIndent}>
                {dept.courses.map(course => {
                  const courseExpanded = expandedCourses.has(course.id)
                  return (
                    <div key={course.id}>
                      <div className={styles.courseRow} onClick={() => toggleCourse(course.id)}>
                        <span>📚</span>
                        <span className={styles.courseLabel}>{course.name}</span>
                        <span
                          className={styles.badge}
                          style={{ background: 'var(--color-border)', color: 'var(--color-text-secondary)', cursor: 'pointer' }}
                          onClick={e => { e.stopPropagation(); navigate(`/course/${course.id}`) }}
                        >
                          detail →
                        </span>
                        <span className={styles.toggleIcon}>{courseExpanded ? '▾' : '▸'}</span>
                      </div>

                      {courseExpanded && (
                        <div className={styles.batchIndent}>
                          {course.batches.map(batch => (
                            <div key={batch.id} className={styles.batchRow}>
                              <span className={`${styles.statusDot} ${batch.status === 'active' ? styles.dotActive : styles.dotDone}`} />
                              <span style={{ fontWeight: 600, color: 'var(--color-text)' }}>{batch.name}</span>
                              <span className={styles.batchMeta}>· {batch.studentCount} siswa</span>
                              {batch.status !== 'active' && (
                                <span className={styles.batchMeta}>· Selesai</span>
                              )}
                              {batch.status === 'active' && batch.sessionTotal > 0 && (
                                <span className={styles.batchMeta}>
                                  · {batch.sessionDone}/{batch.sessionTotal} sesi
                                </span>
                              )}
                            </div>
                          ))}
                          {course.batches.length === 0 && (
                            <div className={styles.batchRow} style={{ color: 'var(--color-text-tertiary)' }}>
                              Belum ada batch
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        )
      })}
    </div>
  )
}
