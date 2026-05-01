# Design: Budget Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Planned vs actual spend tracking per Course Batch and Class

---

## Overview

Manages planned budget and actual realization for course batches and classes. Course defines a budget template with preset amounts and overridability flags. Each batch inherits the template and can map budget items to specific classes. Realization tracks actual spend against each item.

> **Boundary note:** Budget tracks *planned vs actual spend* per batch/class (operational cost management). Profit Split tracks *BatchCostLineItem* for revenue calculation. Separate concerns — Budget does not feed Profit Split.

---

## Hierarchy

```
Course Budget Template Item (preset, with overridable flag)
  └── Batch Budget Item (inherited on batch creation, optional class mapping)
        └── Budget Realization (actual spend per class)
```

---

## Entities

### CourseBudgetTemplateItem
Defined at course level. Copied to every new batch on creation.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | Parent course |
| label | string | e.g., "Konsumsi", "Materi cetak", "Dekorasi" |
| category | string | Nullable; grouping label |
| preset_amount | decimal | Default planned amount |
| overridable | boolean | If false, planned_amount on batch cannot be changed |

### BatchBudgetItem
Copied from template on batch creation. Optional class mapping.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course_batch | Course Batch | Parent batch |
| template_ref | CourseBudgetTemplateItem | Nullable; set if inherited |
| label | string | Inherited; editable if overridable |
| category | string | Nullable |
| planned_amount | decimal | Inherited; editable only if overridable=true |
| overridable | boolean | Inherited |
| class | Class | Nullable; if set, mapped to specific class |
| created_by | User | |

Batch can add items not in template (`template_ref = null`, `overridable = true` default).

### BudgetRealization
Records actual spend. Multiple realizations allowed per item.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| batch_budget_item | BatchBudgetItem | |
| class | Class | Nullable; must match item's class if set |
| actual_amount | decimal | |
| description | string | |
| spent_at | date | |
| proof_url | string | Nullable |
| recorded_by | User (role: admin) | |
| created_at | datetime | |

---

## Business Rules

1. On batch creation, all CourseBudgetTemplateItems → BatchBudgetItems
2. `overridable = false` → planned_amount locked
3. `overridable = true` → planned_amount overridable per batch
4. Items mapped to class or batch-level (`class = null`)
5. Items not in template can be added per batch
6. Realization `class` must match item's class if class-mapped
7. Multiple realizations per item allowed (summed)
8. No cap — over-budget tracked, not blocked
9. Only admin creates/edits/deletes BudgetRealization

---

## Budget Summary (derived)

```
Per item:
  planned   = batch_budget_item.planned_amount
  actual    = SUM(realization.actual_amount)
  variance  = planned - actual  (positive=under, negative=over)

Per batch:
  total_planned  = SUM(item.planned_amount)
  total_actual   = SUM(realization.actual_amount)

Per class:
  Filter items WHERE class = this_class → same formula
```

---

## Background Jobs

| — | — | — |

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

---

## Related Domains

- [course](../course/course.md)
- [enrollment](../enrollment/enrollment.md)
- [profit-split](../profit-split/profit-split.md)
- [invoice](../invoice/invoice.md)
