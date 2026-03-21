# Domain: Student

> Student list, student detail dashboard, and app access management.

---

## Overview

Students are VernonEdu's customers. Every student has permanent access to `app-student`. Some students get conditional, temporary access to supporting apps (e.g. `app-entrepreneur`, `app-blockcoding`) based on enrollment.

---

## App Access Model

| App | Access Type | Condition |
|-----|------------|-----------|
| `app-student` | Permanent | Every registered student |
| Supporting apps | Temporary | Granted on enrollment in batch with linked app |

### Access Revocation (supporting apps)
Access is automatically revoked when:
1. Course batch is completed
2. Student withdraws/retreats from the batch
3. Student fails to pay on schedule (for `scheduled` payment method)

---

## Student List

**Route:** `/students` → `StudentPage`
**Cubit:** `StudentCubit` — states: `StudentInitial | StudentLoading | StudentLoaded(students) | StudentError`

**Usecases:** `GetStudentsUseCase`, `CreateStudentUseCase`, `UpdateStudentUseCase`

**API endpoints:**
```
GET    /students         ?offset, limit
POST   /students         body: {name, email, phone?, studentCode?}
PUT    /students/:id
DELETE /students/:id
```

**StudentEntity fields:** `id, studentCode, name, email, phone, status (active|inactive|graduated), enrolledAt`

**UI note:** Student name cell is clickable — `MouseRegion` with hover underline effect, navigates to `/students/:id`.

---

## Student Detail (Dashboard)

**Route:** `/students/:studentId` → `StudentDashboardPage`
**Cubit:** `StudentDashboardCubit` — parallel loads: detail + enrollmentHistory + recommendations + notes + talentPool
**State:** `StudentDashboardInitial | StudentDashboardLoading | StudentDashboardLoaded | StudentDashboardError`

**Usecases:**
- `GetStudentDetailUseCase(studentId)`
- `GetStudentEnrollmentHistoryUseCase(studentId)`
- `GetStudentRecommendationsUseCase(studentId)`
- `GetStudentNotesUseCase(studentId)`
- `AddStudentNoteUseCase(studentId, content)` → returns `bool`
- `GetTalentPoolUseCase(participantId: studentId)` — reused from TalentPool domain

**API endpoints:**
```
GET  /students/:id
GET  /students/:id/enrollment-history
GET  /students/:id/recommendations
GET  /students/:id/notes
POST /students/:id/notes               body: {content}
```

**Entities:**

| Entity | Key Fields |
|--------|------------|
| StudentDetailEntity | id, studentCode, name, email, phone, nik?, gender?, address?, birthDate?, departmentId, departmentName, status, totalEnrollments, completedCourses, averageScore, enrolledAt |
| StudentEnrollmentHistoryEntity | id, batchCode, batchType, masterCourseName, enrolledAt, completedAt?, totalAttendance, totalSessions, finalScore?, grade?, status, paymentStatus |
| RecommendedCourseEntity | masterCourseId, courseName, courseCode, field, reason, hasActiveBatch |
| StudentNoteEntity | id, studentId, authorId, authorName, content, createdAt |

**Page layout:** Header card (full width) + 5 stat cards row + two-column 3:2 (left: enrollment history + recommendations; right: talent pool status + notes with inline add-note form)

---

## Status

✅ Functional — needs v2 updates: app access management system, payment-linked access revocation.
