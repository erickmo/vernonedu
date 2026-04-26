# Domain: Voucher

## Overview

Vouchers give specific students a discounted price on enrollment. Issued per user by admin. Can bring the final price below `course.min_price` — the only mechanism that allows sub-floor pricing.

## Entities

### Voucher
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| code | string | Unique voucher code |
| discount_type | enum | fixed_amount, percentage, fixed_final_price |
| discount_value | decimal | Amount off / % / final price — interpretation depends on discount_type |
| assigned_to | Student | Nullable; if set, only this student can use it |
| course | Course | Nullable; if set, only valid for this course |
| course_batch | Course Batch | Nullable; if set, only valid for this batch |
| valid_from | date | |
| valid_until | date | Nullable; no expiry if null |
| max_uses | integer | Nullable; unlimited if null |
| used_count | integer | Default 0 |
| is_active | boolean | Admin can deactivate |
| created_by | User | Admin who created the voucher |

### Voucher Usage
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| voucher | Voucher | |
| enrollment | Enrollment | |
| original_price | decimal | Batch price before discount |
| final_price | decimal | Price after voucher applied |
| used_at | datetime | |

## Discount Calculation

```
fixed_amount:
  final_price = batch.price - voucher.discount_value
  (minimum: 0 — cannot go negative)

percentage:
  final_price = batch.price × (1 - voucher.discount_value / 100)

fixed_final_price:
  final_price = voucher.discount_value
  (admin sets exact amount student pays)
```

All three types can result in a price below `course.min_price` — this is intentional and allowed via voucher.

## Redemption Modes

| Mode | How |
|---|---|
| Code entry | Student types voucher code at checkout — works for any voucher if eligible |
| Admin-assigned | Admin assigns voucher to specific student → appears in student's account automatically; student applies at checkout |

Both modes use the same Voucher entity. `assigned_to` determines eligibility:
- `assigned_to = null` → any student can redeem by code
- `assigned_to = Student` → only that student can redeem (by code or via their assigned voucher list)

## Business Rules

1. If `assigned_to` set → only that student can apply it
2. If `assigned_to` null → any student can apply by code
3. If `course` set → only valid for that course; if null → valid for any course
4. If `course_batch` set → only valid for that batch; if null → valid for any batch
5. One voucher per enrollment — cannot stack multiple vouchers
6. `used_count` incremented atomically on successful use; `max_uses` enforced if set
7. Expired (`valid_until < today`) or `is_active = false` vouchers rejected at checkout
8. `final_price` floor at 0 — cannot go negative
9. Only admin can create and assign vouchers
10. `percentage` discount_value must be 0–100
11. Student dashboard shows all vouchers assigned to them (`assigned_to = this student`)

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `enrollment.confirmed` | Enrollment | Mark voucher as used (consumed) |

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [student](../student/student.md)
- [course](../course/course.md)
