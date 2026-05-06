# Struktur Pendidikan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tambah halaman "Struktur" di seksi Pendidikan yang menampilkan hirarki Departemen → Course → Batch summary secara visual Card Tree, dengan role-based CTAs.

**Architecture:** Page-level fetch (depts + courses + batches parallel on mount) → compose data → render card tree. Toggle Card/Tree via localStorage. Role-based CTA visibility via `hasAnyRole` helper. Sub-components: DeptCard, CourseRow, BatchChip, StrukturTreeView.

**Tech Stack:** React 18, TypeScript, CSS Modules, React Query (via `useQuery`), React Router navigate, `useAuthStore`, Lucide icons.

---

## File Map

| File | Action |
|------|--------|
| `src/pages/Course/StrukturPage.tsx` | Create — halaman utama, data fetch + compose + toggle state |
| `src/pages/Course/StrukturPage.module.css` | Create — styles |
| `src/pages/Course/components/DeptCard.tsx` | Create — card 1 departemen |
| `src/pages/Course/components/DeptCard.module.css` | Create |
| `src/pages/Course/components/CourseRow.tsx` | Create — 1 row course + batch chips |
| `src/pages/Course/components/CourseRow.module.css` | Create |
| `src/pages/Course/components/BatchChip.tsx` | Create — 1 chip batch (status + siswa + progress) |
| `src/pages/Course/components/BatchChip.module.css` | Create |
| `src/pages/Course/components/StrukturTreeView.tsx` | Create — tree/accordion view |
| `src/pages/Course/components/StrukturTreeView.module.css` | Create |
| `src/app/routes.tsx` | Modify — tambah lazy import + route `pendidikan/struktur` |
| `src/layouts/AppSidebar/navItems.ts` | Modify — tambah nav item + update slice |
| `src/pages/Course/__tests__/StrukturPage.test.tsx` | Create — unit tests |

---

## Task 1: BatchChip component

**Files:**
- Create: `src/pages/Course/components/BatchChip.tsx`
- Create: `src/pages/Course/components/BatchChip.module.css`

- [ ] **Step 1: Create BatchChip CSS**

```css
/* BatchChip.module.css */
.chip {
  background: var(--color-surface-elevated);
  border: 1px solid var(--color-border);
  border-radius: 7px;
  padding: 5px 9px;
  font-size: var(--font-xs);
  min-width: 140px;
  flex-shrink: 0;
}

.chip.done {
  opacity: 0.65;
}

.header {
  display: flex;
  align-items: center;
  gap: 5px;
  margin-bottom: 4px;
}

.dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  flex-shrink: 0;
}

.dot.active {
  background: var(--color-success);
}

.dot.done {
  background: var(--color-text-tertiary);
}

.name {
  font-weight: 600;
  color: var(--color-text);
}

.meta {
  color: var(--color-text-secondary);
}

.progressBar {
  height: 4px;
  background: var(--color-border);
  border-radius: 2px;
  overflow: hidden;
  margin-bottom: 3px;
}

.progressFill {
  height: 100%;
  border-radius: 2px;
  background: var(--color-success);
  transition: width 0.3s ease;
}

.progressFill.done {
  background: var(--color-text-tertiary);
}

.progressLabel {
  font-size: 10px;
  color: var(--color-text-tertiary);
}
```

- [ ] **Step 2: Create BatchChip component**

```tsx
// BatchChip.tsx
import styles from './BatchChip.module.css'

export interface BatchSummary {
  id: string
  name: string
  status: 'active' | 'completed' | 'draft' | string
  studentCount: number
  sessionDone: number
  sessionTotal: number
}

interface Props {
  batch: BatchSummary
}

export function BatchChip({ batch }: Props) {
  const isActive = batch.status === 'active'
  const isDone = batch.status === 'completed'
  const progress = batch.sessionTotal > 0
    ? Math.round((batch.sessionDone / batch.sessionTotal) * 100)
    : 0

  return (
    <div className={`${styles.chip} ${isDone ? styles.done : ''}`}>
      <div className={styles.header}>
        <span className={`${styles.dot} ${isActive ? styles.active : styles.done}`} />
        <span className={styles.name}>{batch.name}</span>
        <span className={styles.meta}>· {batch.studentCount} siswa</span>
      </div>
      <div className={styles.progressBar}>
        <div
          className={`${styles.progressFill} ${isDone ? styles.done : ''}`}
          style={{ width: `${progress}%` }}
        />
      </div>
      <div className={styles.progressLabel}>
        {isDone ? 'Selesai' : `${batch.sessionDone}/${batch.sessionTotal} sesi · ${progress}%`}
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
git add src/pages/Course/components/BatchChip.tsx src/pages/Course/components/BatchChip.module.css
git commit -m "feat(struktur): add BatchChip component"
```

---

## Task 2: CourseRow component

**Files:**
- Create: `src/pages/Course/components/CourseRow.tsx`
- Create: `src/pages/Course/components/CourseRow.module.css`

- [ ] **Step 1: Create CourseRow CSS**

```css
/* CourseRow.module.css */
.row {
  background: var(--color-surface-alt);
  border: 1px solid rgba(77, 41, 117, 0.15);
  border-radius: 8px;
  padding: 10px 12px;
}

.rowHeader {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.rowHeaderCollapsed {
  margin-bottom: 0;
}

.courseInfo {
  display: flex;
  align-items: center;
  gap: 6px;
}

.courseName {
  font-weight: 600;
  font-size: var(--font-sm);
  color: var(--color-primary);
}

.badge {
  padding: 1px 7px;
  border-radius: var(--radius-full);
  font-size: 10px;
  font-weight: 600;
}

.badgeActive {
  background: var(--color-success-light);
  color: var(--color-success-dark);
}

.badgeDone {
  background: var(--color-border);
  color: var(--color-text-secondary);
}

.badgeEmpty {
  background: var(--color-border);
  color: var(--color-text-tertiary);
}

.rowActions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.detailLink {
  font-size: var(--font-xs);
  color: var(--color-text-secondary);
  text-decoration: none;
  cursor: pointer;
  background: none;
  border: none;
  padding: 0;
}

.detailLink:hover {
  color: var(--color-primary);
}

.addBatchBtn {
  font-size: var(--font-xs);
  color: var(--color-primary);
  border: 1px solid rgba(77, 41, 117, 0.2);
  background: none;
  padding: 2px 8px;
  border-radius: var(--radius-sm);
  cursor: pointer;
}

.addBatchBtn:hover {
  background: var(--color-primary-subtle);
}

.batchList {
  display: flex;
  gap: 8px;
  flex-wrap: nowrap;
  overflow-x: auto;
  padding-bottom: 2px;
  align-items: stretch;
}

.batchList::-webkit-scrollbar {
  height: 3px;
}

.batchList::-webkit-scrollbar-thumb {
  background: var(--color-border);
  border-radius: 2px;
}

.addBatchChip {
  display: flex;
  align-items: center;
  background: var(--color-surface-elevated);
  border: 1px dashed var(--color-primary);
  border-radius: 7px;
  padding: 5px 12px;
  font-size: var(--font-xs);
  color: var(--color-primary);
  cursor: pointer;
  white-space: nowrap;
  flex-shrink: 0;
}

.addBatchChip:hover {
  background: var(--color-primary-subtle);
}

.toggleBtn {
  background: none;
  border: none;
  padding: 0 4px;
  cursor: pointer;
  color: var(--color-text-secondary);
  font-size: 12px;
}
```

- [ ] **Step 2: Create CourseRow component**

```tsx
// CourseRow.tsx
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
```

- [ ] **Step 3: Commit**

```bash
git add src/pages/Course/components/CourseRow.tsx src/pages/Course/components/CourseRow.module.css
git commit -m "feat(struktur): add CourseRow component"
```

---

## Task 3: DeptCard component

**Files:**
- Create: `src/pages/Course/components/DeptCard.tsx`
- Create: `src/pages/Course/components/DeptCard.module.css`

- [ ] **Step 1: Create DeptCard CSS**

```css
/* DeptCard.module.css */
.card {
  background: var(--color-surface-elevated);
  border: 1px solid var(--color-border);
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(77, 41, 117, 0.06);
}

.header {
  background: var(--color-primary);
  color: var(--color-text-on-primary);
  padding: 10px 14px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  user-select: none;
}

.headerCollapsed {
  background: var(--color-primary-hover);
}

.headerLeft {
  display: flex;
  align-items: center;
  gap: 8px;
}

.headerName {
  font-weight: 700;
  font-size: var(--font-sm);
}

.headerRight {
  display: flex;
  align-items: center;
  gap: 8px;
}

.countBadge {
  background: rgba(255, 255, 255, 0.18);
  padding: 2px 8px;
  border-radius: var(--radius-full);
  font-size: 11px;
}

.addCourseBtn {
  background: var(--color-secondary);
  color: var(--color-secondary-text);
  border: none;
  padding: 2px 10px;
  border-radius: var(--radius-full);
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
}

.addCourseBtn:hover {
  background: var(--color-secondary-hover);
}

.toggleIcon {
  color: rgba(255, 255, 255, 0.7);
  font-size: 12px;
}

.body {
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
```

- [ ] **Step 2: Create DeptCard component**

```tsx
// DeptCard.tsx
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
```

- [ ] **Step 3: Commit**

```bash
git add src/pages/Course/components/DeptCard.tsx src/pages/Course/components/DeptCard.module.css
git commit -m "feat(struktur): add DeptCard component"
```

---

## Task 4: StrukturTreeView component

**Files:**
- Create: `src/pages/Course/components/StrukturTreeView.tsx`
- Create: `src/pages/Course/components/StrukturTreeView.module.css`

- [ ] **Step 1: Create StrukturTreeView CSS**

```css
/* StrukturTreeView.module.css */
.tree {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.deptRow {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px 12px;
  background: var(--color-primary-subtle);
  border-radius: 7px;
  cursor: pointer;
  user-select: none;
}

.deptRow:hover {
  background: rgba(77, 41, 117, 0.12);
}

.deptLabel {
  font-weight: 700;
  font-size: var(--font-sm);
  color: var(--color-primary);
  flex: 1;
}

.courseIndent {
  margin-left: 20px;
  display: flex;
  flex-direction: column;
  gap: 3px;
  margin-top: 3px;
}

.courseRow {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 5px 10px;
  background: var(--color-surface-alt);
  border-radius: 6px;
  cursor: pointer;
}

.courseRow:hover {
  background: rgba(77, 41, 117, 0.08);
}

.courseLabel {
  font-weight: 600;
  font-size: var(--font-sm);
  color: var(--color-primary);
  flex: 1;
}

.batchIndent {
  margin-left: 20px;
  display: flex;
  flex-direction: column;
  gap: 3px;
  margin-top: 3px;
}

.batchRow {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 10px;
  background: var(--color-surface-elevated);
  border: 1px solid var(--color-border);
  border-radius: 5px;
  font-size: var(--font-xs);
}

.statusDot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
}

.dotActive { background: var(--color-success); }
.dotDone { background: var(--color-text-tertiary); }

.batchMeta {
  color: var(--color-text-secondary);
}

.badge {
  padding: 1px 7px;
  border-radius: var(--radius-full);
  font-size: 10px;
  font-weight: 600;
}

.toggleIcon {
  color: var(--color-text-secondary);
  font-size: 12px;
}
```

- [ ] **Step 2: Create StrukturTreeView component**

```tsx
// StrukturTreeView.tsx
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
```

- [ ] **Step 3: Commit**

```bash
git add src/pages/Course/components/StrukturTreeView.tsx src/pages/Course/components/StrukturTreeView.module.css
git commit -m "feat(struktur): add StrukturTreeView component"
```

---

## Task 5: StrukturPage (main page)

**Files:**
- Create: `src/pages/Course/StrukturPage.tsx`
- Create: `src/pages/Course/StrukturPage.module.css`

- [ ] **Step 1: Create StrukturPage CSS**

```css
/* StrukturPage.module.css */
.page {
  display: flex;
  flex-direction: column;
  gap: 0;
  min-height: 100%;
}

.header {
  padding: 16px 20px;
  background: var(--color-surface-elevated);
  border-bottom: 1px solid var(--color-border);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.headerLeft {}

.title {
  font-size: 18px;
  font-weight: 700;
  color: var(--color-text);
  margin: 0;
}

.subtitle {
  font-size: var(--font-xs);
  color: var(--color-text-secondary);
  margin: 2px 0 0;
}

.viewToggle {
  display: flex;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  overflow: hidden;
  background: var(--color-surface-elevated);
}

.toggleBtn {
  padding: 6px 14px;
  font-size: var(--font-xs);
  font-weight: 600;
  border: none;
  cursor: pointer;
  background: transparent;
  color: var(--color-text-secondary);
  transition: background 0.15s, color 0.15s;
}

.toggleBtn + .toggleBtn {
  border-left: 1px solid var(--color-border);
}

.toggleBtn.active {
  background: var(--color-primary);
  color: var(--color-text-on-primary);
}

.body {
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.addDeptBtn {
  border: 1.5px dashed var(--color-primary);
  border-radius: 10px;
  padding: 10px 14px;
  text-align: center;
  color: var(--color-primary);
  font-size: var(--font-sm);
  cursor: pointer;
  background: var(--color-primary-subtle);
  font-weight: 600;
  transition: background 0.15s;
}

.addDeptBtn:hover {
  background: rgba(77, 41, 117, 0.12);
}

.empty {
  text-align: center;
  padding: 40px 20px;
  color: var(--color-text-tertiary);
}

.loadingRow {
  height: 80px;
  background: var(--color-surface-alt);
  border-radius: 10px;
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
```

- [ ] **Step 2: Create StrukturPage**

```tsx
// StrukturPage.tsx
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/auth.store'
import { hasAnyRole } from '@/types/auth.types'
import { departmentService } from '@/services/department.service'
import { courseBatchService } from '@/services/course-batch.service'
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

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <div className={styles.headerLeft}>
          <h1 className={styles.title}>Struktur Pendidikan</h1>
          <p className={styles.subtitle}>Departemen → Course → Kelas aktif</p>
        </div>
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
      </div>

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
```

- [ ] **Step 3: Commit**

```bash
git add src/pages/Course/StrukturPage.tsx src/pages/Course/StrukturPage.module.css
git commit -m "feat(struktur): add StrukturPage main component"
```

---

## Task 6: Wire up routes and nav

**Files:**
- Modify: `src/app/routes.tsx`
- Modify: `src/layouts/AppSidebar/navItems.ts`

- [ ] **Step 1: Add lazy import to routes.tsx**

After line 32 (`const CourseDashboardPage = ...`), add:

```tsx
const StrukturPage = lazy(() => import('@/pages/Course/StrukturPage'))
```

- [ ] **Step 2: Add route entry in routes.tsx**

After `{ path: 'course', element: ... }` (line 184), add:

```tsx
{ path: 'pendidikan/struktur', element: <S><StrukturPage /></S> },
```

- [ ] **Step 3: Add nav item to navItems.ts**

In navItems.ts, add `Network` to Lucide imports at the top, then insert nav item after the `course` item (after line 181):

```ts
  {
    key: 'struktur',
    label: 'Struktur',
    icon: Network,
    path: '/pendidikan/struktur',
    hasAccess: (ctx) => canManageCourse(ctx) || hasRole(ctx, 'facilitator'),
  },
```

- [ ] **Step 4: Update Pendidikan section slice**

Find the `pendidikan` section in `NAV_SECTIONS` (currently `ALL_ITEMS.slice(1, 7)`).

The new `struktur` item is inserted at index 2 (after `course`), pushing the rest. Change the slice to include the new item count — update the slice from `ALL_ITEMS.slice(1, 7)` to `ALL_ITEMS.slice(1, 8)`:

```ts
  {
    key: 'pendidikan',
    label: 'Pendidikan',
    icon: BookOpen,
    items: ALL_ITEMS.slice(1, 8), // Kurikulum, Struktur, Kelas..Sertifikat
  },
```

**Important:** All other slice references (`operasi`, `marketing`, `pengembangan`, `sistem`) reference by index. After inserting at position 2, all subsequent items shift by 1. Audit and update all slices:

- `operasi: [ALL_ITEMS[8], ALL_ITEMS[10]]` → becomes `[ALL_ITEMS[9], ALL_ITEMS[11]]`
- `marketing: ALL_ITEMS.slice(11, 14)` → becomes `ALL_ITEMS.slice(12, 15)`
- `pengembangan: [ALL_ITEMS[7], ALL_ITEMS[9], ...ALL_ITEMS.slice(16, 18)]` → becomes `[ALL_ITEMS[8], ALL_ITEMS[10], ...ALL_ITEMS.slice(17, 19)]`
- `sistem: ALL_ITEMS.slice(18)` → becomes `ALL_ITEMS.slice(19)`

- [ ] **Step 5: Commit**

```bash
git add src/app/routes.tsx src/layouts/AppSidebar/navItems.ts
git commit -m "feat(struktur): wire route and nav item for Struktur page"
```

---

## Task 7: Unit tests

**Files:**
- Create: `src/pages/Course/__tests__/StrukturPage.test.tsx`

- [ ] **Step 1: Write tests**

```tsx
// StrukturPage.test.tsx
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import StrukturPage from '../StrukturPage'
import { departmentService } from '@/services/department.service'
import { courseBatchService } from '@/services/course-batch.service'
import { useAuthStore } from '@/stores/auth.store'

vi.mock('@/services/department.service')
vi.mock('@/services/course-batch.service')
vi.mock('@/stores/auth.store')

const mockDepts = {
  items: [
    { id: 'd1', name: 'Dept Digital' },
    { id: 'd2', name: 'Dept Bisnis' },
  ],
  total: 2, limit: 100, offset: 0,
}

const mockCourses = [{ id: 'c1', name: 'Web Dev' }, { id: 'c2', name: 'UI/UX' }]

const mockBatches = {
  data: {
    data: [
      { id: 'b1', name: 'Batch Jun 2026', status: 'active', student_count: 18, session_done: 4, session_total: 10 },
      { id: 'b2', name: 'Batch Jan 2026', status: 'completed', student_count: 12, session_done: 10, session_total: 10 },
    ],
  },
}

function renderPage(roles: string[] = ['education_leader']) {
  vi.mocked(useAuthStore).mockReturnValue({ user: { id: 'u1', name: 'Test', email: 'x@x.com', roles } } as any)
  vi.mocked(departmentService.list).mockResolvedValue(mockDepts as any)
  vi.mocked(departmentService.getCourses).mockResolvedValue(mockCourses as any)
  vi.mocked(courseBatchService.list).mockResolvedValue(mockBatches as any)
  return render(<MemoryRouter><StrukturPage /></MemoryRouter>)
}

describe('StrukturPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('renders page title', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByText('Struktur Pendidikan')).toBeInTheDocument())
  })

  it('shows dept cards after loading', async () => {
    renderPage()
    await waitFor(() => {
      expect(screen.getByText('Dept Digital')).toBeInTheDocument()
      expect(screen.getByText('Dept Bisnis')).toBeInTheDocument()
    })
  })

  it('shows course names inside expanded dept', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByText('Web Dev')).toBeInTheDocument())
  })

  it('shows batch info', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByText('Batch Jun 2026')).toBeInTheDocument())
  })

  it('shows Add Dept button for education_leader', async () => {
    renderPage(['education_leader'])
    await waitFor(() => expect(screen.getByText('+ Tambah Departemen')).toBeInTheDocument())
  })

  it('hides Add Dept button for facilitator', async () => {
    renderPage(['facilitator'])
    await waitFor(() => expect(screen.queryByText('+ Tambah Departemen')).not.toBeInTheDocument())
  })

  it('shows Add Batch button for course_owner', async () => {
    renderPage(['course_owner'])
    await waitFor(() => expect(screen.getAllByText('+ Batch').length).toBeGreaterThan(0))
  })

  it('hides Add Batch button for facilitator', async () => {
    renderPage(['facilitator'])
    await waitFor(() => expect(screen.queryByText('+ Batch')).not.toBeInTheDocument())
  })

  it('toggles to tree view when Tree button clicked', async () => {
    renderPage()
    await waitFor(() => screen.getByText('≡ Tree'))
    await userEvent.click(screen.getByText('≡ Tree'))
    expect(localStorage.getItem('struktur_view')).toBe('tree')
  })

  it('shows empty state when no depts', async () => {
    vi.mocked(departmentService.list).mockResolvedValue({ items: [], total: 0, limit: 100, offset: 0 } as any)
    renderPage()
    await waitFor(() => expect(screen.getByText(/Belum ada departemen/)).toBeInTheDocument())
  })
})
```

- [ ] **Step 2: Run tests**

```bash
cd web-dashboard && npx vitest run src/pages/Course/__tests__/StrukturPage.test.tsx
```

Expected: All 10 tests pass.

- [ ] **Step 3: Commit**

```bash
git add src/pages/Course/__tests__/StrukturPage.test.tsx
git commit -m "test(struktur): add StrukturPage unit tests"
```

---

## Task 8: Update wolf files

- [ ] **Step 1: Update anatomy.md** — tambah entri untuk semua file baru:

Append ke `.wolf/anatomy.md`:
```
## web-dashboard/src/pages/Course/

- `StrukturPage.tsx` — Halaman Struktur Pendidikan: fetch depts+courses+batches, toggle Card/Tree view (~250 tok)
- `StrukturPage.module.css` — Styles untuk StrukturPage (~80 tok)
- `components/BatchChip.tsx` — Chip batch: status dot, nama, siswa count, progress bar (~80 tok)
- `components/BatchChip.module.css` — Styles BatchChip (~60 tok)
- `components/CourseRow.tsx` — Row course + batch chips horizontal scroll, role-gated + Batch CTA (~120 tok)
- `components/CourseRow.module.css` — Styles CourseRow (~80 tok)
- `components/DeptCard.tsx` — Card departemen: header ungu, expand/collapse, list CourseRow, role-gated + Course CTA (~100 tok)
- `components/DeptCard.module.css` — Styles DeptCard (~70 tok)
- `components/StrukturTreeView.tsx` — Tree/accordion view alternatif: Dept→Course→Batch nested collapse (~100 tok)
- `components/StrukturTreeView.module.css` — Styles StrukturTreeView (~60 tok)
```

- [ ] **Step 2: Append to memory.md**

```
| [time] | Implement Struktur Pendidikan page: DeptCard+CourseRow+BatchChip+TreeView+StrukturPage+route+nav | 10 files | completed | ~800 tok |
```

- [ ] **Step 3: Final commit**

```bash
git add .wolf/anatomy.md .wolf/memory.md
git commit -m "docs(wolf): update anatomy and memory for Struktur feature"
```
