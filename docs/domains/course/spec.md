# Design: Course Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Course, Course Batch, Class hierarchy with format configs and cost templates

---

## Overview

Core educational product unit. A course belongs to a department, owned by a Course Creator, runs through one or more Course Batches. Students enroll at batch level, not course level.

---

## Hierarchy

```
Department
  └── Course (one Course Creator)
        └── Course Batch (students enroll here)
              └── Class (individual sessions)
```

---

## Entities

### Course
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| name | string | |
| department | Department | |
| course_creator | User (course_creator) | |
| base_price | decimal | Standard price |
| min_price | decimal | Floor; batch price >= this |
| profit_split_override | JSON | Optional CEO override |
| created_by | User | |
| created_at | datetime | |

### CourseFormatConfig
One per enabled format per course.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | |
| format | enum | regular, private, inhouse_training, inschool_program |
| is_enabled | boolean | |
| min_students | integer | Nullable |
| max_students | integer | Nullable |
| mode_online | boolean | |
| mode_offline | boolean | |

Formats:
- **regular** — group class, standard pricing
- **private** — 1-on-1 / small group, premium
- **inhouse_training** — at client premises
- **inschool_program** — within school setting

### CourseBatch
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | |
| label | string | e.g., "Batch 3 - April 2026" |
| start_date | date | |
| end_date | date | |
| price | decimal | In `[min_price, base_price]` |
| batch_bulk_price | decimal | Nullable; B2B per-batch override |
| status | enum | draft, open, ongoing, closed |
| web_registration_open | boolean | |
| registration_open_at | datetime | Nullable |
| registration_close_at | datetime | Nullable |
| created_by | User | |
| created_at | datetime | |

### Class
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | CourseBatch | |
| title | string | Optional |
| session_date | date | |
| start_time | time | |
| end_time | time | |
| mode | enum | online, offline |
| location | string | Nullable; required if offline |
| online_link | string | Nullable; required if online |
| instructor | User | Course Creator or approved Facilitator |
| instructor_type | enum | course_creator, facilitator |
| assigned_by | enum | course_creator_self, dept_leader |

### CourseCostTemplate
Default cost items at course level. Inherited by every new batch as Batch Cost Line Items.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | |
| label | string | |
| amount | decimal | |
| cost_type | enum | fixed, percentage_of_revenue |

> **BatchCostLineItem** is owned by [Profit Split domain](../profit-split/profit-split.md).

### CourseBudgetTemplateItem
> Owned by [Budget domain](../budget/budget.md).

### CertificateConfig
> Owned by [Certificate domain](../certificate/certificate.md).

---

## Business Rules

1. Students enroll at Course Batch level, not course level
2. At least one CourseFormatConfig must be enabled before batch can open
3. Enrollment validates format and mode against CourseFormatConfig
4. Enrollment blocked if `web_registration_open = false` for web enrollments
5. Enrollment blocked outside `registration_open_at` to `registration_close_at` if set
6. Enrollment blocked if format's `max_students` reached
7. Batch cannot move to `ongoing` if enrolled count < `min_students` for any active format
8. Each course has exactly one Course Creator
9. Class instructor = Course Creator or approved Facilitator
   - Dept Leader can directly assign — overrides Course Creator's choice
   - One instructor at a time; `assigned_by` tracks setter
   - `location` required if mode=offline; `online_link` required if mode=online
10. CourseCostTemplate copied to BatchCostLineItems on batch creation
11. Batch can override label/amount or soft-delete (`is_removed = true`)
12. Batch can add cost items not in template
13. Facilitator fees and partner splits auto-create BatchCostLineItems on approval/confirmation
14. Batch `price` enforced in `[min_price, base_price]` on save
15. Sub-floor pricing only via voucher at enrollment
16. Certificate configs define which certificates issue on completion or manual
17. Unique `(course, format)` in CourseFormatConfig
18. Enrollment supports all four formats; `inhouse_training` and `inschool_program` admin-managed (not web)

---

## Background Jobs

| — | — | — |

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `course.batch.created` | `{batch_id, course_id, schedule}` | Calendar |
| `course.batch.closed` | `{batch_id, course_id}` | Profit Split |
| `course.class.facilitator_assigned` | `{class_id, batch_id, facilitator_id}` | Calendar |
| `course.class.rescheduled` | `{class_id, batch_id, new_date, new_start_time, new_end_time}` | Calendar |
| `course.class.cancelled` | `{class_id, batch_id}` | Calendar |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

---

## Related Domains

- [department](../department/department.md)
- [enrollment](../enrollment/enrollment.md)
- [student](../student/student.md)
- [team-member](../team-member/team-member.md)
- [profit-split](../profit-split/profit-split.md)
- [certificate](../certificate/certificate.md)
- [budget](../budget/budget.md)
- [module](../module/module.md)
- [calendar](../calendar/calendar.md)
