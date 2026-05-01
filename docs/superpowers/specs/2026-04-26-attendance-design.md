# Design: Attendance Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** New Attendance domain — class attendance tracking, final test, retake slots, completion path determination

---

## Overview

New domain managing student progress toward course completion. Tracks per-student per-class attendance, configures completion thresholds, records external final test results, and determines which completion path a student achieves (attendance-based or test-based). Completion path determines which certificate is issued.

---

## Entities

### CourseCompletionConfig
Default completion config per course. Inherited by every new batch unless overridden.

| Field | Type | Notes |
|---|---|---|
| course | Course | |
| attendance_threshold_pct | decimal | Minimum % kehadiran, e.g. 80.0 |
| has_final_test | boolean | Whether this course has a final test |
| set_by | User | Course Creator or Admin |

---

### BatchCompletionConfig
Optional override per batch. Overrides CourseCompletionConfig values when present.

| Field | Type | Notes |
|---|---|---|
| course_batch | Course Batch | |
| attendance_threshold_pct | decimal | Override from course config |
| has_final_test | boolean | Override |
| set_by | User | Admin |

---

### AttendanceRecord
Per student per class session.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| student | Student | |
| class | Class | |
| status | enum | `present`, `absent`, `excused` |
| marked_by | User | Instructor or Admin |
| marked_by_role | enum | `instructor`, `admin` |
| overridden_by | User | Nullable; admin who overrode original mark |
| overridden_at | datetime | Nullable |
| notes | string | Nullable |
| created_at | datetime | |

---

### FinalTest
One record per batch. Only created if `has_final_test = true` in config.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | Course Batch | |
| test_date | date | Nullable; external test — for record only |
| created_by | User | Admin |
| created_at | datetime | |

---

### FinalTestResult
Per student per attempt. Admin records externally-conducted test results.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| final_test | FinalTest | |
| student | Student | |
| attempt_number | integer | 1 = first attempt; 2+ = retake |
| result | enum | `pass`, `fail` |
| recorded_by | User | Admin |
| recorded_at | datetime | |
| notes | string | Nullable |

---

### RetakeSlot
Admin must explicitly open a retake slot before recording a second+ attempt.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| final_test | FinalTest | |
| student | Student | |
| created_by | User | Admin |
| created_at | datetime | |

---

## Threshold Resolution

```
if BatchCompletionConfig exists for batch:
  use BatchCompletionConfig.attendance_threshold_pct
  use BatchCompletionConfig.has_final_test
else:
  use CourseCompletionConfig.attendance_threshold_pct
  use CourseCompletionConfig.has_final_test
```

---

## Completion Logic (OR Conditions)

### Path 1 — Attendance-based
```
All classes in batch are done (past session_date)
AND student attendance_pct >= threshold_pct
AND (has_final_test = false OR student has no FinalTestResult yet)
```
→ fire `attendance.completion_eligible` with `completion_path = attendance_based`

### Path 2 — Test-based
```
Admin records FinalTestResult.result = pass
```
→ fire `attendance.completion_eligible` with `completion_path = test_based`

### Attendance Percentage Formula
```
attendance_pct = COUNT(status IN [present, excused]) / total_classes_in_batch × 100
```
`excused` counts as present for threshold calculation.

### Both Conditions Met
If student meets attendance threshold AND later passes the test: completion path is whichever occurred first. `completion_status` cannot be set twice — second trigger is ignored.

---

## Business Rules

1. `CourseCompletionConfig` is required when creating a course — a course cannot be saved without it
2. `AttendanceRecord` can only be created after `class.session_date` — no pre-marking
2. Instructor can only mark attendance for classes where they are the assigned `instructor`
4. Admin can mark or override attendance for any class in any batch
5. `FinalTest` record can only be created if `has_final_test = true` in resolved config
6. `RetakeSlot` required before admin can record `FinalTestResult` with `attempt_number > 1`
7. No maximum retake limit — admin controls access by opening/not opening RetakeSlot
8. If enrollment already `completed` (any path), new FinalTestResult is ignored — completion_path does not change
9. Dropped enrollments cannot receive new AttendanceRecord or FinalTestResult

---

## Cross-Domain Changes Required

### Enrollment domain
Add field to `Enrollment` entity:

| Field | Type | Notes |
|---|---|---|
| completion_path | enum | `attendance_based`, `test_based` — nullable; set when completion_status → completed |

### Certificate domain
Add field to `CertificateConfig` entity:

| Field | Type | Notes |
|---|---|---|
| completion_path | enum | `attendance_based`, `test_based`, `any` — which completion path triggers this cert |

`enrollment.completed` handler: filter CertificateConfig by `completion_path` — only issue certs where `completion_path` matches enrollment's path OR `completion_path = any`.

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Listeners |
|---|---|---|
| `attendance.completion_eligible` | `{enrollment_id, student_id, batch_id, completion_path}` | Enrollment |

### Listens (I react to these)
| Event | Source | My action |
|---|---|---|
| `course.class.cancelled` | Course | Delete AttendanceRecord for that class |

---

## Related Domains

- [course](../../domains/course/course.md)
- [enrollment](../../domains/enrollment/enrollment.md)
- [certificate](../../domains/certificate/certificate.md)
- [team-member](../../domains/team-member/team-member.md)
