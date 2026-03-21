# Domain: Batch & Enrollment

> CourseBatch lifecycle, scheduling with module-room mapping, enrollment, and payment methods.

---

## CourseBatch

A CourseBatch is a real class instance that students apply to and join.

### Key Properties

| Property | Description |
|----------|-------------|
| course_type | Links to CourseType (determines modules, pricing range, participant limits) |
| facilitator | Assigned facilitator for the batch |
| pricing | Set by Op Leader within normal–min price range; overridable by Dept Leader |
| payment_method | One of 5 methods (see below) |
| min/max students | From CourseType defaults; overridable by Dept Leader |
| website_visible | Toggle to show/hide on website (default: displayed) |
| budget | Spending + earning plan tracked against actuals |
| status | draft → pending_approval → approved → active → completed |

### Creation Flows

**From Operation:**
1. Operation Administrator creates batch
2. Course Creator approves content
3. Operational Leader approves schedule
4. Dept Leader gives final approval

**From Course Creator:**
1. Course Creator creates batch directly
2. Operational Leader confirms schedule
3. Dept Leader confirms everything (final approval)

Once approved → batch is available on website (if `website_visible = true`) and students can enroll.

---

## Schedule & Module Mapping

Each batch has class schedules. Each schedule entry maps to:
- **Module** — from the approved CourseVersion
- **Room** — from Location system (Building → Room)
- **Time slot** — date + start/end time

### Conflict Detection
- System checks for room overlap (same room, overlapping time)
- Overlap is **blocked by default**
- Can be approved by Operational Leader (approval workflow #9)

Schedules must cover all modules in the approved version.

---

## Payment Methods

| Method | Key | Description | Typical Use |
|--------|-----|-------------|-------------|
| All in advance | `upfront` | Full payment before class starts | Reguler, Privat |
| Scheduling | `scheduled` | Fixed installment schedule (e.g. 3x) | Program Karir, Reguler |
| Monthly according to sessions | `monthly` | Pay monthly based on sessions that month | Reguler, Kolaborasi |
| Batch (lump sum) | `batch_lump` | Single payment for entire batch by client/company | Inhouse Training |
| Per session attended | `per_session` | Pay only for sessions student actually attended | Privat, flexible |

Each batch has its own pricing (can differ from CourseType normal/min price, within range or overridden by Dept Leader).

### Payment → Access Link
If payment method is `scheduled` and student **fails to pay on time**, the student's:
- Enrollment status is flagged
- Access to supporting apps (e.g. app-entrepreneur) is **revoked**

---

## Enrollment

When a student enrolls in an approved batch:
1. Enrollment record is created
2. **Invoice is auto-generated** based on the batch's payment method
3. Student gains access to `app-student` view of the batch + supporting app (if applicable)
4. Enrollment + payment data flows to **Accounting** automatically

### Enrollment Status
`active | completed | dropped | suspended`

### Access Revocation Triggers
Student's supporting app access is revoked when:
- Course batch is completed
- Student withdraws/retreats
- Student fails to pay on schedule (for `scheduled` method)

---

## Budgeting (per Batch)

Each course batch includes a budget:
- Budget plan (expected spending + earning)
- Track actual spending against budget
- Track actual earning against budget
- All spending/earning mapped to budget line items
- Directly feeds into Accounting module

---

## Attendance

During the course, the facilitator takes attendance by **scanning the student's app** (QR-based).
- Each session has attendance records per enrolled student
- Status: `present | late | absent | excused`

---

## Routes

```
/course-batches                     → CourseBatchPage
/course-batches/:batchId            → CourseBatchDetailPage
/enrollments                        → EnrollmentPage
```

## Cubits

- `CourseBatchCubit` — batch list
- `CourseBatchDetailCubit` — detail page (parallel loads: batch detail + schedule + enrollments + budget)
- `EnrollmentCubit` — enrollment list + summary (parallel load)

## Usecases

### CourseBatch
- `GetCourseBatchesUseCase`, `CreateCourseBatchUseCase`, `GetCourseBatchDetailUseCase(batchId)`

### Enrollment
- `GetEnrollmentsUseCase`, `GetEnrollmentSummaryUseCase`, `EnrollStudentUseCase`

## API Endpoints

```
# CourseBatch
GET    /course-batches              ?offset, limit
GET    /course-batches/:id
GET    /course-batches/:id/detail
POST   /course-batches              body: {courseTypeId, code, startDate, endDate, facilitatorId?, pricing, paymentMethod, minStudents, maxStudents, websiteVisible, ...}
PUT    /course-batches/:id
DELETE /course-batches/:id
PUT    /course-batches/:id/facilitator   body: {facilitatorId}
GET    /course-batches/:id/sessions
GET    /course-batches/:id/budget

# Schedule
GET    /course-batches/:id/schedules
POST   /course-batches/:id/schedules     body: {moduleId, roomId, scheduledAt, duration}

# Attendance
GET    /course-batches/:batchId/sessions/:sessionId/attendance
POST   /course-batches/:batchId/sessions/:sessionId/attendance   body: {records: [{studentId, status, note?}]}

# Enrollment
GET    /enrollments                 ?offset, limit, student_id?, course_batch_id?
GET    /enrollments/summary
POST   /enrollments                 body: {studentId, courseBatchId}
```

## Entities

| Entity | Key Fields |
|--------|------------|
| CourseBatchEntity | id, code, courseTypeId, courseTypeName, masterCourseName, startDate, endDate, status, facilitatorName, pricing, paymentMethod, minStudents, maxStudents, websiteVisible, totalEnrolled |
| CourseBatchDetailEntity | (above) + modules[], enrollments[], attendanceSummary, budget |
| ScheduleEntity | id, batchId, moduleId, moduleTitle, roomId, roomName, buildingName, scheduledAt, duration |
| EnrollmentEntity | id, studentId, studentName, batchId, batchCode, masterCourseName, enrolledAt, status |
| EnrollmentBatchSummaryEntity | batchId, batchCode, totalEnrolled, totalCompleted, totalDropped |

---

## Status

✅ Functional (basic) — needs v2 updates: payment methods, pricing range, schedule-module-room mapping, budget tracking, QR attendance, approval workflows, auto-invoice generation, website visibility toggle.
