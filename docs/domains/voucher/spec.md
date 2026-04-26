# Design: Voucher Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Discount vouchers issued per student or unrestricted; only mechanism for sub-floor pricing

---

## Overview

Vouchers give specific (or any) students a discounted price on enrollment. Issued by admin. Can bring final price below `course.min_price` — the only mechanism that allows sub-floor pricing.

---

## Entities

### Voucher
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| code | string | Unique |
| discount_type | enum | fixed_amount, percentage, fixed_final_price |
| discount_value | decimal | Interpretation depends on discount_type |
| assigned_to | Student | Nullable; only that student can use if set |
| course | Course | Nullable; restricts to course |
| course_batch | CourseBatch | Nullable; restricts to batch |
| valid_from | date | |
| valid_until | date | Nullable; no expiry if null |
| max_uses | integer | Nullable; unlimited if null |
| used_count | integer | Default 0 |
| is_active | boolean | |
| created_by | User | Admin |

### VoucherUsage
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| voucher | Voucher | |
| enrollment | Enrollment | |
| original_price | decimal | Batch price before discount |
| final_price | decimal | After voucher |
| used_at | datetime | |
| created_by | User | Authenticated user who triggered checkout |

---

## Discount Calculation

```
fixed_amount:
  final_price = batch.price - voucher.discount_value
  (floor: 0)

percentage:
  final_price = batch.price × (1 - discount_value / 100)

fixed_final_price:
  final_price = discount_value
  (admin sets exact amount student pays)
```

All three may go below `course.min_price` — intentional and allowed.

---

## Redemption Modes

| Mode | How |
|---|---|
| Code entry | Student types code at checkout |
| Admin-assigned | Admin assigns to student → appears in account; student applies at checkout |

Both use same Voucher entity. `assigned_to` determines eligibility:
- `null` → any student can redeem by code
- Set → only that student

---

## Business Rules

1. `assigned_to` set → only that student can apply
2. `assigned_to` null → any student by code
3. `course` set → restricted to course; null → any course
4. `course_batch` set → restricted to batch; null → any batch
5. One voucher per enrollment — no stacking
6. `used_count` incremented atomically; `max_uses` enforced if set
7. Expired or `is_active = false` vouchers rejected at checkout
8. `final_price` floor at 0 — never negative
9. Only admin creates and assigns vouchers
10. `percentage` discount_value in 0–100
11. Student dashboard shows assigned vouchers
12. Unique constraint on `VoucherUsage(enrollment)` — one usage per enrollment (DB-level race protection)

---

## Background Jobs

- **Expiry check** (daily, optional): vouchers with `valid_until < today` may be flagged for cleanup; checkout always re-validates regardless

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `enrollment.confirmed` | Enrollment | Mark voucher as used (consumed) |

---

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [student](../student/student.md)
- [course](../course/course.md)
