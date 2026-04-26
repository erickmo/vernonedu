# Domain: Team Member

## Overview

Single source of truth for all internal VernonEdu employees. Covers profile, employment status, and role-specific data. Facilitators (instructors who teach classes) are a specialization of TeamMember — their proposal flow, fee tiers, and class assignments live here.

> **Migration note:** This domain replaces the former `facilitator` domain. All references to `Facilitator` entity should now point to `TeamMember` with `is_facilitator = true`.

---

## Entities

### TeamMember
| Field | Type | Notes |
|---|---|---|
| user | User | The employee's account (1:1) |
| full_name | string | |
| phone | string | |
| department | Department | Nullable — not all roles are dept-scoped |
| role | enum (from Auth) | `ceo`, `finance`, `academic_leader`, `dept_leader`, `course_creator`, `vernonedu_admin`, `admin` |
| employment_status | enum | `active`, `inactive`, `on_leave` |
| joined_at | date | |
| is_facilitator | boolean | True if this member can teach classes |

### FacilitatorProfile
Exists only when `TeamMember.is_facilitator = true`.

| Field | Type | Notes |
|---|---|---|
| team_member | TeamMember | |
| specialization | string | Subject / skill area |
| bio | text | Shown to students |

> Facilitator availability is governed by `TeamMember.employment_status`. An `on_leave` or `inactive` team member cannot be assigned to new classes.

### FacilitatorProposal
| Field | Type | Notes |
|---|---|---|
| course | Course | Which course the facilitator is proposed for |
| proposed_by | TeamMember | Must have role `course_creator` |
| facilitator | TeamMember | Must have `is_facilitator = true` |
| fee_tier | FeeTier | Tier selected by proposer |
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
| created_by | TeamMember | Must have role `vernonedu_admin` |
| is_active | boolean | Inactive tiers hidden from new proposals |

---

## Approval Flow (Facilitator Proposal)

```
Course Creator selects facilitator (TeamMember) + fee tier for a course
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

---

## Fee Tier Rules

| Who | Action |
|---|---|
| VernonEdu Admin | Define tier table (names + amounts) |
| Course Creator | Select a tier per proposal |
| Dept Leader | Approves or rejects selected tier as part of proposal |

- Course Creator selects only — no custom amounts
- Fee basis set per proposal, not per tier

**Fee Basis Calculation:**
| fee_basis | Formula |
|---|---|
| per_class | `amount_per_class × number_of_classes_assigned` |
| per_course | `amount_per_course` (flat fee for the batch) |
| both | `(amount_per_class × number_of_classes_assigned) + amount_per_course` |

For `fee_basis = both`: per-class fee counts only sessions where this facilitator is the assigned instructor. Per-course is a flat bonus on top.

---

## Class-Level Assignment

After a facilitator is proposal-approved for a course, Dept Leader can assign them to specific classes:

| Action | Who |
|---|---|
| Assign facilitator to class | Dept Leader |
| Set instructor to Course Creator | Dept Leader or Course Creator |

- Dept Leader assignment overrides Course Creator's instructor choice for that class

---

## Business Rules

1. Every internal employee (any non-student, non-franchisee, non-partner user) must have a `TeamMember` record
2. A TeamMember can become a facilitator at any time by setting `is_facilitator = true` and creating a `FacilitatorProfile`
3. Facilitator approval is **per course** — does not carry over to other courses
4. Dept Leader approves first; Academic Leader second — strict order
5. Either rejection closes the proposal
6. Course Creator can propose multiple facilitators per course
7. Course Creator can only propose for courses where they are the assigned creator
8. Tier table managed by VernonEdu Admin only
9. Inactive fee tiers cannot be selected for new proposals but existing proposals using them remain valid
10. On `facilitator.approved` (final_status → approved), a `facilitator_fee` Batch Cost Line Item is auto-created on the relevant Course Batch: `reference_type = facilitator_fee`, `reference_id = FacilitatorProposal.id`. Amount calculated using the FeeTier and fee_basis at proposal approval time.

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `team_member.created` | `{team_member_id, role}` | Notification |
| `team_member.status_changed` | `{team_member_id, old_status, new_status}` | Notification |
| `facilitator.proposed` | `{facilitator_id, course_id, proposed_by}` | Notification |
| `facilitator.approved` | `{facilitator_id, course_id, approved_by}` | Notification, Calendar |
| `facilitator.rejected` | `{facilitator_id, course_id, rejected_by, stage}` | Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

---

## Related Domains

- [auth](../auth/auth.md) — roles live there; TeamMember references them
- [course](../course/course.md)
- [department](../department/department.md)
- [notification](../notification/notification.md)
- [calendar](../calendar/calendar.md)
