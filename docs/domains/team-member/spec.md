# Design: Team Member Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Single source of truth for internal employees, including facilitator specialization, fee tiers, and approval flow

---

## Overview

Single source of truth for all internal VernonEdu employees. Covers profile, employment status, role-specific data. Facilitators are a specialization (`is_facilitator = true`) — proposal flow, fee tiers, and class assignments live here.

> **Migration note:** Replaces deprecated `facilitator` domain. All `Facilitator` references → `TeamMember` with `is_facilitator = true`.

---

## Entities

### TeamMember
| Field | Type | Notes |
|---|---|---|
| user | User | 1:1 with Auth account |
| full_name | string | |
| phone | string | |
| department | Department | Nullable; not all roles dept-scoped |
| role | enum (Auth) | `ceo`, `finance`, `academic_leader`, `dept_leader`, `course_creator`, `vernonedu_admin`, `admin` |
| employment_status | enum | `active`, `inactive`, `on_leave` |
| joined_at | date | |
| is_facilitator | boolean | True if can teach |

### FacilitatorProfile
Exists only when `is_facilitator = true`.

| Field | Type | Notes |
|---|---|---|
| team_member | TeamMember | |
| specialization | string | |
| bio | text | Shown to students |

> Availability governed by `employment_status`. `on_leave` or `inactive` cannot be assigned to new classes.

### FacilitatorProposal
| Field | Type | Notes |
|---|---|---|
| course | Course | |
| proposed_by | TeamMember | Must have role `course_creator` |
| facilitator | TeamMember | Must have `is_facilitator = true` |
| fee_tier | FeeTier | |
| fee_basis | enum | `per_class`, `per_course`, `both` |
| dept_leader_status | enum | `pending`, `approved`, `rejected` |
| dept_leader_reviewed_at | datetime | |
| dept_leader_note | string | Nullable |
| academic_leader_status | enum | `pending`, `approved`, `rejected` |
| academic_leader_reviewed_at | datetime | |
| academic_leader_note | string | Nullable |
| final_status | enum | `pending`, `approved`, `rejected` |

### FeeTier
| Field | Type | Notes |
|---|---|---|
| name | string | e.g., "Tier A", "Senior" |
| amount_per_class | decimal | Nullable |
| amount_per_course | decimal | Nullable |
| created_by | TeamMember | role `vernonedu_admin` |
| is_active | boolean | Inactive hidden from new proposals |

---

## Approval Flow (Facilitator Proposal)

```
Course Creator selects facilitator + fee tier for course
  ▼
Dept Leader reviews
  ├── Rejected → closed
  └── Approved
        ▼
      Academic Leader reviews
        ├── Rejected → closed
        └── Approved → facilitator active for that course
```

Sequential — Academic Leader cannot review until Dept Leader approves.

---

## Fee Tier Rules

| Who | Action |
|---|---|
| VernonEdu Admin | Define tier table |
| Course Creator | Select tier per proposal |
| Dept Leader | Approves/rejects selected tier as part of proposal |

Course Creator selects only — no custom amounts. Fee basis set per proposal, not per tier.

**Fee Basis Calculation:**
| fee_basis | Formula |
|---|---|
| per_class | `amount_per_class × number_of_classes_assigned` |
| per_course | `amount_per_course` |
| both | `(amount_per_class × N_classes) + amount_per_course` |

For `both`: per-class fee counts only sessions where this facilitator is assigned instructor.

---

## Class-Level Assignment

After proposal-approved for a course, Dept Leader assigns to specific classes.

| Action | Who |
|---|---|
| Assign facilitator to class | Dept Leader |
| Set instructor to Course Creator | Dept Leader or Course Creator |

Dept Leader assignment overrides Course Creator's choice for that class.

---

## Business Rules

1. Every internal employee (non-student, non-franchisee, non-partner) has TeamMember record
2. Can become facilitator at any time by setting `is_facilitator = true` and creating FacilitatorProfile
3. Facilitator approval is **per course** — does not carry over
4. Dept Leader approves first; Academic Leader second — strict order
5. Either rejection closes proposal
6. Course Creator can propose multiple facilitators per course
7. Course Creator can only propose for own courses
8. Tier table managed by VernonEdu Admin only
9. Inactive tiers cannot be selected for new proposals; existing proposals using them remain valid
10. On `facilitator.approved`, auto-create `facilitator_fee` BatchCostLineItem (`reference_type = facilitator_fee`, `reference_id = FacilitatorProposal.id`); amount from FeeTier + fee_basis at approval time

---

## Background Jobs

| — | — | — |

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `team_member.created` | `{team_member_id, role}` | Notification |
| `team_member.status_changed` | `{team_member_id, old_status, new_status}` | Notification |
| `facilitator.proposed` | `{facilitator_id, course_id, proposed_by}` | Notification |
| `facilitator.approved` | `{facilitator_id, course_id, approved_by}` | Notification, Calendar, Profit-split |
| `facilitator.rejected` | `{facilitator_id, course_id, rejected_by, stage}` | Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

---

## Related Domains

- [auth](../auth/auth.md) — roles live there
- [course](../course/course.md)
- [department](../department/department.md)
- [notification](../notification/notification.md)
- [calendar](../calendar/calendar.md)
