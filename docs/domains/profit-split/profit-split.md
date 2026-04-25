# Domain: Profit Split

## Overview

Defines how revenue from a course is distributed between VernonEdu, the Course Creator, and the Department Leader. Split percentages are configured globally in settings but can be overridden per course by the CEO.

## Split Parties

| Party | Receives |
|---|---|
| VernonEdu | Platform/operational share |
| Course Creator | Creator's share for owning and delivering the course |
| Department Leader | Leadership share for the department |

## Configuration

### Global Settings (default)
Stored in VernonEdu system settings:

| Key | Type |
|---|---|
| default_vernonedu_pct | decimal |
| default_course_creator_pct | decimal |
| default_dept_leader_pct | decimal |

Sum must equal 100%.

### Per-Course Override
CEO can override split for any individual course:

| Field | Type | Notes |
|---|---|---|
| course | Course | Which course |
| vernonedu_pct | decimal | |
| course_creator_pct | decimal | |
| dept_leader_pct | decimal | |
| overridden_by | User (role: ceo) | |
| overridden_at | datetime | |

## Profit Calculation

```
Net Profit = Course Revenue − Course Costs

Course Revenue = enrollment fees + approved extra revenue entries
Course Costs   = sum of all active batch cost line items
```

Split parties receive their % of Net Profit.

### Negative Net Profit
If Net Profit < 0 (costs exceed revenue):
- Split is **not blocked** — recorded as negative
- Negative amount carries over into **period bonus calculation**
- Parties' period bonus is reduced by their share of the deficit

### Extra Revenue (Finance-Added)
Finance can add non-enrollment revenue to a batch (e.g., sponsorship, grants). Requires CEO approval.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | Course Batch | Which batch |
| label | string | e.g., "Sponsorship", "Government grant" |
| amount | decimal | |
| added_by | User (role: finance) | |
| approval_status | enum | pending, approved, rejected |
| approved_by | User (role: ceo) | Nullable |
| approved_at | datetime | Nullable |
| created_at | datetime | |

Extra revenue only included in Course Revenue calculation after `approval_status = approved`.

## Course Cost Line Items

Costs are dynamic line items. Two levels:

1. **Course Cost Template** — default costs defined on the Course; inherited by every new batch
2. **Batch Cost Line Item** — actual costs on a Course Batch; copied from template but can be overridden or removed per batch

### Course Cost Template (on Course)
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | Template belongs to course |
| label | string | e.g., "Bahan ajar", "Venue", "Admin fee" |
| amount | decimal | Default amount |
| cost_type | enum | fixed, percentage_of_revenue |

### Batch Cost Line Item (on Course Batch)
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | Course Batch | Which batch |
| template_ref | Course Cost Template | Nullable; set if inherited from template |
| label | string | Can be changed from template label |
| amount | decimal | Can be changed from template amount |
| cost_type | enum | fixed, percentage_of_revenue |
| is_removed | boolean | True if template item was removed for this batch |
| reference_type | enum | manual, facilitator_fee, partner_split, other |
| reference_id | uuid | Nullable; links to facilitator proposal or partnership if auto-generated |
| created_by | User | |
| created_at | datetime | |

### Inheritance Behavior
```
When Course Batch is created:
  → Copy all Course Cost Template items → Batch Cost Line Items
  → Each item stores template_ref for traceability

Per batch, user can:
  → Override label or amount of any inherited item
  → Mark item as removed (is_removed = true) — excluded from cost sum
  → Add new items not in template (template_ref = null)
```

### Cost Types
| Type | Behavior |
|---|---|
| fixed | Flat amount deducted from revenue |
| percentage_of_revenue | Calculated as % × gross revenue |

### Auto-generated vs Manual
| Source | How created |
|---|---|
| Facilitator fee | Auto-created on batch when facilitator proposal approved |
| Partner/institution split | Auto-created from B2B partnership agreement |
| Template inheritance | Auto-copied from course template on batch creation |
| Everything else | Manually added per batch |

## Resolution Logic

```
if course.profit_split_override exists:
  use course-level override
else:
  use global settings defaults
```

## Business Rules

1. Only CEO can set or modify per-course overrides
2. All three percentages must sum to 100%
3. Override is per course — does not cascade to other courses in same department
4. Global defaults apply to all courses without an override
5. Profit split calculated on net profit (not gross revenue)
6. Negative net profit carries over to period bonus — not blocked
7. Extra revenue added by Finance requires CEO approval before included in calculation
8. Split calculated when batch status → `closed`; triggered on batch close event
9. Period bonus aggregated across all closed batches within the period (monthly/quarterly — TBD)
10. Negative net profit from a closed batch carries into next period bonus calculation

## Related Domains

- [course](../course/course.md)
- [department](../department/department.md)
- [facilitator](../facilitator/facilitator.md)
