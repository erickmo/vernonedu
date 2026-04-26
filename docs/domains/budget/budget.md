# Domain: Budget

## Overview

Manages planned budget and actual realization for course batches and classes. Course defines a budget template with preset amounts and overridability flags. Each batch inherits the template and can map budget items to specific classes. Realization tracks actual spend against each budget item.

## Hierarchy

```
Course Budget Template Item (preset, with overridable flag)
  └── Batch Budget Item (inherited on batch creation, optional class mapping)
        └── Budget Realization (actual spend per class)
```

---

## Entities

### Course Budget Template Item
Defined at course level. Copied to every new batch on creation.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | Parent course |
| label | string | e.g., "Konsumsi", "Materi cetak", "Dekorasi" |
| category | string | Nullable; grouping label e.g., "Operasional", "Materi" |
| preset_amount | decimal | Default planned amount |
| overridable | boolean | If false, planned_amount on batch cannot be changed |

---

### Batch Budget Item
Copied from course template on batch creation. Can be mapped to a specific class or left as batch-level.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | Course Batch | Parent batch |
| template_ref | Course Budget Template Item | Nullable; set if inherited from template |
| label | string | Inherited from template; editable if overridable |
| category | string | Nullable |
| planned_amount | decimal | Inherited from template; editable only if overridable = true |
| overridable | boolean | Inherited from template |
| class | Class | Nullable; if set, this budget item is mapped to a specific class |
| created_by | User | |

Batch can also add budget items not in the template (`template_ref = null`, `overridable = true` by default).

---

### Budget Realization
Records actual spend against a batch budget item. One budget item can have multiple realization entries (e.g., multiple receipts).

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| batch_budget_item | Batch Budget Item | Which budget item this realizes |
| class | Class | Nullable; class this realization is for (must match item's class if set) |
| actual_amount | decimal | Amount actually spent |
| description | string | What was purchased/spent |
| spent_at | date | Date of actual spend |
| proof_url | string | Nullable; receipt or proof of payment |
| recorded_by | User (role: admin) | Admin only |
| created_at | datetime | |

---

## Business Rules

1. On batch creation, all Course Budget Template Items are copied → Batch Budget Items
2. `overridable = false` → `planned_amount` locked; cannot be changed on batch
3. `overridable = true` → `planned_amount` can be overridden per batch
4. Batch budget items can be mapped to a specific class (`class` field) or left batch-level (`class = null`)
5. Budget items not in template can be added per batch (`template_ref = null`)
6. Realization `class` must match the budget item's `class` if item is class-mapped; null item = batch-level realization
7. Multiple realizations per budget item allowed (summed for total actual)
8. No enforced cap — realization can exceed `planned_amount` (over-budget tracked, not blocked)
9. Only admin can create, edit, or delete Budget Realization entries

---

## Budget Summary (derived)

Per batch budget item:
```
planned_amount   = batch_budget_item.planned_amount
actual_amount    = SUM(budget_realization.actual_amount) where batch_budget_item = this
variance         = planned_amount - actual_amount
  positive → under budget
  negative → over budget
```

Per batch total:
```
total_planned  = SUM(batch_budget_item.planned_amount)
total_actual   = SUM(budget_realization.actual_amount)
total_variance = total_planned - total_actual
```

Per class:
```
Filter batch_budget_item WHERE class = this_class
Apply same summary formula
```

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

## Related Domains

- [course](../course/course.md)
- [enrollment](../enrollment/enrollment.md)
- [profit-split](../profit-split/profit-split.md)
