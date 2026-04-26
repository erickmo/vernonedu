# Domain: Course

## Overview

Core educational product unit in VernonEdu. A course belongs to a department, is owned by a Course Creator, and runs through one or more Course Batches.

## Hierarchy

```
Department
  └── Course (has one Course Creator)
        └── Course Batch (students enroll here)
              └── Class (individual sessions)
```

## Entities

### Course
| Field | Type | Notes |
|---|---|---|
| name | string | |
| department | Department | Parent department |
| course_creator | User (role: course_creator) | Owns and responsible for course content |
| base_price | decimal | Standard/default price |
| min_price | decimal | Floor price — batch price cannot go below this |
| profit_split_override | JSON | Optional CEO override for this course's profit split |

### Course Format Config
Each enabled format has its own config. A course can have multiple format configs.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | |
| format | enum | regular, private, inhouse_training, inschool_program |
| is_enabled | boolean | |
| min_students | integer | Nullable; minimum enrollment required |
| max_students | integer | Nullable; maximum enrollment allowed |
| mode_online | boolean | Whether this format is available online |
| mode_offline | boolean | Whether this format is available offline |

Formats:
- **regular**: group class, standard pricing
- **private**: 1-on-1 or small group, premium pricing
- **inhouse_training**: delivered at client/institution premises
- **inschool_program**: program run within a school setting

### Course Batch
| Field | Type | Notes |
|---|---|---|
| course | Course | Parent course |
| name / label | string | e.g., "Batch 3 - April 2026" |
| start_date | date | |
| end_date | date | |
| price | decimal | Must be within [min_price, base_price] |
| status | enum | draft, open, ongoing, closed |
| web_registration_open | boolean | If true, students can self-enroll via web; if false, admin-only enrollment |
| registration_open_at | datetime | Nullable; when registration opens |
| registration_close_at | datetime | Nullable; when registration closes |

### Class
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | Course Batch | Parent batch |
| title | string | Optional label e.g., "Session 1 — Introduction" |
| session_date | date | |
| start_time | time | |
| end_time | time | |
| mode | enum | online, offline |
| location | string | Nullable; venue name/address for offline |
| online_link | string | Nullable; meeting URL for online |
| instructor | User | Course Creator or approved/assigned Facilitator |
| instructor_type | enum | course_creator, facilitator |
| assigned_by | enum | course_creator_self, dept_leader | Who set the instructor |

### Course Cost Template
Default cost items defined at course level. Inherited by every new Course Batch. Batch can override or remove any item.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | Parent course |
| label | string | e.g., "Bahan ajar", "Venue", "Admin fee" |
| amount | decimal | Default amount |
| cost_type | enum | fixed, percentage_of_revenue |

### Batch Cost Line Item
Actual costs per batch. Copied from template on batch creation; each item can be overridden or removed.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | Course Batch | Parent batch |
| template_ref | Course Cost Template | Nullable; set if inherited from template |
| label | string | Overridable |
| amount | decimal | Overridable |
| cost_type | enum | fixed, percentage_of_revenue |
| is_removed | boolean | Exclude from cost sum if true |
| reference_type | enum | manual, facilitator_fee, partner_split, other |
| reference_id | uuid | Nullable; links to auto-generated source |
| created_by | User | |
| created_at | datetime | |

### Course Budget Template Item
Default budget items for every batch created from this course. See [budget domain](../budget/budget.md) for full detail.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | Parent course |
| label | string | e.g., "Konsumsi", "Materi cetak" |
| category | string | Nullable grouping label |
| preset_amount | decimal | Default planned amount |
| overridable | boolean | If false, batch cannot change the amount |

### Certificate Config
Defines which certificates this course can issue. One course can have multiple configs.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | Parent course |
| type | enum | vernonedu_competence, vernonedu_participation, partner |
| partner_name | string | Nullable; e.g., "BNSP", "CompTIA" |
| issued_on | enum | completion, manual |

## Business Rules

1. Students enroll at **Course Batch** level, not course level
2. At least one Course Format Config must be enabled before a batch can open
3. Enrollment validates format and mode against Course Format Config for the batch's course
4. Enrollment blocked if batch `web_registration_open = false` for web (student-initiated) enrollments
5. Enrollment blocked if current datetime is outside `registration_open_at` to `registration_close_at` window (if set)
6. Enrollment blocked if batch student count for that format has reached `max_students` (if set)
7. Batch cannot move to `ongoing` status if enrolled count < `min_students` for any active format config
8. Each course has exactly one Course Creator
9. Classes can be taught by Course Creator or approved/assigned Facilitator (see facilitator domain)
9a. Dept Leader can directly assign an approved facilitator to any class — overrides or supplements Course Creator's choice
9b. Each class has exactly one instructor at a time; `assigned_by` tracks who set it
9c. `location` required if mode = offline; `online_link` required if mode = online
10. Course Cost Template is the default; copied to Batch Cost Line Items on batch creation
11. Batch can override label/amount of any inherited cost item, or soft-delete it (`is_removed = true`)
12. Batch can add cost items not in the template (`template_ref = null`)
13. Facilitator fees and partner splits auto-create Batch Cost Line Items when approved/confirmed
14. Batch `price` must be within `[min_price, base_price]` — system enforces this on save
15. Price below `min_price` is only achievable via voucher applied at enrollment
16. Certificate configs define which certificates students receive on completion or manual issuance

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `course.batch.created` | `{batch_id, course_id, schedule}` | Calendar |
| `course.class.facilitator_assigned` | `{class_id, batch_id, facilitator_id}` | Calendar |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

## Related Domains

- [department](../department/department.md)
- [enrollment](../enrollment/enrollment.md)
- [facilitator](../facilitator/facilitator.md)
- [profit-split](../profit-split/profit-split.md)
- [certificate](../certificate/certificate.md)
- [budget](../budget/budget.md)
- [module](../module/module.md)
- [calendar](../calendar/calendar.md)
