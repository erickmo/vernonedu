# Design: Profit Split Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Revenue distribution between VernonEdu, Course Creator, Dept Leader; per-batch cost line items; period bonus

---

## Overview

Defines how revenue from a course is distributed between VernonEdu, the Course Creator, and the Department Leader. Split percentages configured globally; CEO can override per course.

---

## Split Parties

| Party | Receives |
|---|---|
| VernonEdu | Platform / operational share |
| Course Creator | Course owner share |
| Department Leader | Department share |

---

## Configuration

### Global Settings

| Key | Type |
|---|---|
| default_vernonedu_pct | decimal |
| default_course_creator_pct | decimal |
| default_dept_leader_pct | decimal |

Sum must equal 100%.

### Per-Course Override

| Field | Type | Notes |
|---|---|---|
| course | Course | |
| vernonedu_pct | decimal | |
| course_creator_pct | decimal | |
| dept_leader_pct | decimal | |
| overridden_by | User (ceo) | |
| overridden_at | datetime | |

---

## Profit Calculation

```
Net Profit = Course Revenue − Course Costs

Course Revenue = enrollment fees + approved extra revenue
Course Costs   = sum of active BatchCostLineItems (excluding is_removed)
```

### Negative Net Profit
- Not blocked
- Carries into Period Bonus calculation as deficit

---

## Entities

### ExtraRevenue
Finance-added non-enrollment revenue. CEO approval required.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | CourseBatch | |
| label | string | e.g., "Sponsorship" |
| amount | decimal | |
| added_by | User (finance) | |
| approval_status | enum | pending, approved, rejected |
| approved_by | User (ceo) | Nullable |
| approved_at | datetime | Nullable |
| created_at | datetime | |

Only `approved` extra revenue counts toward Course Revenue.

### BatchCostLineItem
Inherited from CourseCostTemplate at batch creation; editable per batch.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | CourseBatch | |
| template_ref | CourseCostTemplate | Nullable; set if inherited |
| label | string | Editable from template |
| amount | decimal | Editable from template |
| cost_type | enum | fixed, percentage_of_revenue |
| is_removed | boolean | Excluded from cost sum if true |
| reference_type | enum | manual, facilitator_fee, partner_split, other |
| reference_id | uuid | Nullable; FK to proposal/agreement if auto-generated |
| created_by | User | |
| created_at | datetime | |

### PeriodBonus
Aggregated profit share at period end (monthly).

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| period | string | YYYY-MM |
| period_type | enum | `monthly` |
| vernonedu_amount | decimal | |
| course_creator_amount | decimal | Aggregated per course creator |
| dept_leader_amount | decimal | Aggregated per dept leader |
| batch_refs | uuid[] | Batch IDs in period |
| calculated_at | datetime | |
| calculated_by | User | Admin |
| status | enum | `draft`, `finalized` |

---

## Inheritance Behavior

```
On batch creation:
  → Copy all CourseCostTemplate items → BatchCostLineItems
  → Each stores template_ref

Per batch user can:
  → Override label/amount of inherited
  → is_removed = true (excluded)
  → Add items not in template (template_ref = null)
```

### Cost Types

| Type | Behavior |
|---|---|
| fixed | Flat amount |
| percentage_of_revenue | % × gross revenue |

### Auto-generated vs Manual

| Source | How |
|---|---|
| Facilitator fee | Auto on `facilitator.approved` |
| Partner split | Auto on B2B enrollment confirmed |
| Template inheritance | Auto on batch creation |
| Other | Manual |

---

## Resolution Logic

```
if course.profit_split_override exists:
  use override
else:
  use global defaults
```

---

## Business Rules

1. Only CEO sets/modifies per-course overrides
2. Three percentages must sum to 100%
3. Override per course; doesn't cascade
4. Global defaults apply to courses without override
5. Split calculated on net profit
6. Negative net profit carries to period bonus — not blocked
7. ExtraRevenue requires CEO approval before counting
8. Split calculated on `course.batch.closed`
9. Period bonus aggregated monthly across all batches closed in period
10. Negative net profit from closed batch carries to next period bonus
11. On B2B enrollment confirmed, auto-create `partner_split` BatchCostLineItem (`reference_type = partner_split`, `reference_id = PartnershipAgreement.id`). Amount from `payment_model` and `bulk_price`.

---

## Background Jobs

- **Period bonus rollup** (monthly): aggregate all closed batches in the period → create draft PeriodBonus → admin finalizes

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `profit_split.calculated` | `{batch_id, course_id, period, split_amounts}` | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `course.batch.closed` | Course | Trigger profit-split calculation for closed batch |
| `facilitator.approved` | Team Member | Auto-create `facilitator_fee` BatchCostLineItem |
| `enrollment.confirmed` (B2B) | Enrollment | Auto-create `partner_split` BatchCostLineItem |
| `payment.confirmed` | Payment | Update batch revenue rollup |

---

## Related Domains

- [course](../course/course.md)
- [department](../department/department.md)
- [team-member](../team-member/team-member.md)
