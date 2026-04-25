# Domain: Facilitator

## Overview

Facilitators are instructors who teach classes on behalf of a Course Creator. They must be proposed by the Course Creator and approved sequentially by the Department Leader then the Academic Leader.

## Entities

### Facilitator
| Field | Type | Notes |
|---|---|---|
| user | User | The facilitator's account |
| status | enum | active, inactive |

### Facilitator Proposal
| Field | Type | Notes |
|---|---|---|
| course | Course | Which course this facilitator is proposed for |
| course_creator | User | Who proposed |
| facilitator | Facilitator | |
| fee_tier | FeeTier | Tier selected by Course Creator |
| fee_basis | enum | per_class, per_course, both |
| dept_leader_status | enum | pending, approved, rejected |
| dept_leader_reviewed_at | datetime | |
| academic_leader_status | enum | pending, approved, rejected |
| academic_leader_reviewed_at | datetime | |
| final_status | enum | pending, approved, rejected |

### Fee Tier
| Field | Type | Notes |
|---|---|---|
| name | string | e.g., "Tier A", "Senior", etc. |
| amount_per_class | decimal | Nullable |
| amount_per_course | decimal | Nullable |
| created_by | User (role: vernonedu_admin) | |

## Approval Flow

```
Course Creator selects facilitator + fee tier for a course
  │
  ▼
Dept Leader reviews
  ├── Rejected → proposal closed
  └── Approved
        │
        ▼
      Academic Leader reviews
        ├── Rejected → proposal closed
        └── Approved → facilitator active for that course
```

**Sequential:** Academic Leader cannot review until Dept Leader approves.

## Fee Tier Rules

| Who | Action |
|---|---|
| VernonEdu Admin | Defines tier table (names + amounts per class and/or per course) |
| Course Creator | Selects a tier for each facilitator per course |
| Dept Leader | Approves or rejects the selected tier as part of proposal approval |

- Course Creator cannot set custom amounts — selection only from predefined tiers
- Fee basis (per_class / per_course / both) set per facilitator proposal

## Class-Level Assignment (by Dept Leader)

Beyond the course-level approval flow, Dept Leader can directly assign an approved facilitator to a specific class:

| Action | Who |
|---|---|
| Assign facilitator to class | Dept Leader |
| Set instructor to Course Creator | Dept Leader or Course Creator |

- Facilitator must already be approved for the course (via proposal flow) before Dept Leader can assign them to a class
- Dept Leader assignment takes precedence over Course Creator's class instructor choice

## Business Rules

1. Facilitator must be approved per course — approval does not carry over to other courses
2. Dept Leader approves first; Academic Leader second (strict order)
3. Either rejection terminates the proposal
4. Course Creator can propose multiple facilitators per course
5. Class instructor can be Course Creator (no approval needed) or an approved Facilitator
6. Dept Leader can assign any course-approved facilitator to any class in that course
7. Dept Leader class assignment overrides Course Creator's instructor choice for that class
8. Tier table is managed by VernonEdu Admin only
9. Course Creator can only propose facilitators and assign tiers for courses where they are the assigned Course Creator

## Related Domains

- [course](../course/course.md)
- [department](../department/department.md)
- [notification](../notification/notification.md)
- [calendar](../calendar/calendar.md)
