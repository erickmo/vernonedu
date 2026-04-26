# Partner, PartnershipAgreement & Invoice Domains — Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans.
> Steps use `- [ ]` syntax for tracking.

**Goal:** Rename Institution → Partner, extract PartnershipAgreement as standalone domain, add Invoice domain, expand CalendarEvent for partner meetings, and update all cross-references.

**Tech Stack:** Markdown documentation only — no code changes in this plan.

**Specs:**
- `docs/shared/spec/partner-partnership-agreement.md`
- `docs/domains/invoice/spec.md`

---

### Task 1: Create Partner domain doc

**Files:**
- Create: `docs/domains/partner/partner.md`

- [ ] **Step 1: Create the file**

Create `docs/domains/partner/partner.md` with this exact content:

```markdown
# Domain: Partner

## Overview

External entities that have or may have a formal relationship with VernonEdu. Replaces the former Institution domain. Lightweight profile entity — all formal agreement terms (pricing, payer, documents) live in PartnershipAgreement. B2B enrollments reference Partner instead of Institution.

## Entities

### Partner

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| name | string | |
| type | enum | `university`, `vendor`, `sponsor`, `franchise_candidate`, `community`, `other` |
| status | enum | `lead`, `active`, `inactive` |
| contact_name | string | Nullable; primary contact person |
| contact_email | string | Nullable |
| contact_phone | string | Nullable |
| address | string | Nullable |
| notes | string | Nullable; internal notes |
| created_at | datetime | |

## Business Rules

1. `status = lead` — no active agreement yet; relationship in early stage
2. `status = active` — has at least one PartnershipAgreement with `status = active`
3. `status = inactive` — all agreements expired or terminated
4. B2B enrollment references Partner (field renamed from `institution` → `partner`)
5. All partner types can have PartnershipAgreements — `type` does not restrict features

## Related Domains

- [partnership-agreement](../partnership-agreement/partnership-agreement.md)
- [enrollment](../enrollment/enrollment.md)
- [calendar](../calendar/calendar.md)
```

- [ ] **Step 2: Commit**

```bash
git add docs/domains/partner/partner.md
git commit -m "docs: add partner domain (renamed from institution)"
```

---

### Task 2: Create PartnershipAgreement domain doc

**Files:**
- Create: `docs/domains/partnership-agreement/partnership-agreement.md`

- [ ] **Step 1: Create the file**

Create `docs/domains/partnership-agreement/partnership-agreement.md` with this exact content:

```markdown
# Domain: PartnershipAgreement

## Overview

Tracks formal agreements between VernonEdu and a Partner. One Partner can have multiple agreements over time (e.g. annual renewal cycles). Owns expiry tracking, uploaded documents, and B2B payment terms previously embedded in the Institution domain.

## Entities

### PartnershipAgreement

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| partner | Partner | |
| title | string | e.g. "MOU 2025–2026" |
| status | enum | `draft`, `active`, `expired`, `terminated` |
| start_date | date | |
| end_date | date | Nullable; null = open-ended agreement |
| payment_model | enum | Nullable; `per_visit`, `per_course`, `per_student` — B2B only |
| payer | enum | Nullable; `institution`, `student` — B2B only |
| bulk_price | decimal | Nullable; B2B bulk override price for all covered batches |
| signed_at | date | Nullable |
| terminated_at | date | Nullable |
| termination_reason | string | Nullable |
| created_by | User | |
| created_at | datetime | |

### PartnerDocument

Uploaded documents associated with an agreement (MOU, proposals, etc.).

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| agreement | PartnershipAgreement | |
| type | enum | `mou`, `proposal` |
| title | string | |
| file_url | string | |
| uploaded_by | User | |
| uploaded_at | datetime | |

## Payment Models

| Model | Description |
|---|---|
| per_visit | Partner pays per session/visit delivered |
| per_course | Fixed fee per course regardless of student count |
| per_student | Fee × number of enrolled students |

## Business Rules

1. One Partner can have multiple PartnershipAgreements — only one can be `active` at a time
2. `status = expired` auto-set when `end_date < today` and current status was `active`
3. `status = terminated` requires `termination_reason`
4. B2B enrollment resolves `payment_model`, `payer`, `bulk_price` from the partner's `active` agreement
5. Agreement with `status = draft` cannot be referenced by B2B enrollment
6. `end_date = null` = open-ended; never auto-expires
7. Documents can be uploaded at any agreement status
8. Bulk price resolution per enrollment: `batch_bulk_price` (if set on batch) → `agreement.bulk_price` → `course_batch.price`

## Related Domains

- [partner](../partner/partner.md)
- [enrollment](../enrollment/enrollment.md)
- [calendar](../calendar/calendar.md)
```

- [ ] **Step 2: Commit**

```bash
git add docs/domains/partnership-agreement/partnership-agreement.md
git commit -m "docs: add partnership-agreement domain"
```

---

### Task 3: Create Invoice domain doc

**Files:**
- Create: `docs/domains/invoice/invoice.md`

- [ ] **Step 1: Create the file**

Create `docs/domains/invoice/invoice.md` with this exact content:

```markdown
# Domain: Invoice

## Overview

Formal billing document linked to an Enrollment and its Payment. Addressable to a Partner (B2B) or Student (B2C). Admin generates invoices and can add custom line items. Invoice number is auto-generated and unique.

## Entities

### Invoice

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| invoice_number | string | Auto-generated, unique |
| enrollment | Enrollment | |
| payment | Payment | |
| billed_to | enum | `partner`, `student` |
| partner | Partner | Nullable; set if `billed_to = partner` |
| student | Student | Nullable; set if `billed_to = student` |
| status | enum | `draft`, `sent`, `paid`, `overdue`, `cancelled` |
| issued_date | date | |
| due_date | date | Nullable |
| subtotal | decimal | Sum of line items before discount |
| discount_amount | decimal | Default 0 |
| total_amount | decimal | subtotal - discount_amount |
| notes | string | Nullable; admin notes printed on invoice |
| created_by | User | |
| created_at | datetime | |

### InvoiceLineItem

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| invoice | Invoice | |
| label | string | e.g. "Tuition Fee", "Admin Fee", "Discount" |
| amount | decimal | Positive = charge, negative = deduction |
| sort_order | integer | Display order |

## Business Rules

1. `billed_to = partner` requires `partner` field set; `student` field null
2. `billed_to = student` requires `student` field set; `partner` field null
3. For B2B enrollments (`payer = institution`): `billed_to` defaults to `partner`
4. For B2C enrollments: `billed_to` defaults to `student`
5. Admin can override `billed_to` — default is not enforced
6. `total_amount` = sum of all InvoiceLineItem amounts (negative items = deductions)
7. Line items editable only when `status = draft`
8. `status = paid` auto-set when linked Payment `status = paid`
9. `status = overdue` auto-set when `due_date < today` and `status != paid`
10. One invoice per enrollment — admin reissues by cancelling and creating a new draft

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [payment](../payment/payment.md)
- [partner](../partner/partner.md)
- [student](../student/student.md)
```

- [ ] **Step 2: Commit**

```bash
git add docs/domains/invoice/invoice.md
git commit -m "docs: add invoice domain"
```

---

### Task 4: Delete Institution domain doc

**Files:**
- Delete: `docs/domains/institution/institution.md`
- Delete dir: `docs/domains/institution/`

- [ ] **Step 1: Delete the file and directory**

```bash
rm -rf docs/domains/institution/
```

- [ ] **Step 2: Commit**

```bash
git add -A docs/domains/institution/
git commit -m "docs: remove institution domain (replaced by partner + partnership-agreement)"
```

---

### Task 5: Update Enrollment domain doc

**Files:**
- Modify: `docs/domains/enrollment/enrollment.md`

- [ ] **Step 1: Rename `institution` field → `partner` in the Enrollment entity table**

Find:
```
| institution | Institution | Nullable; set for B2B enrollments |
```
Replace with:
```
| partner | Partner | Nullable; set for B2B enrollments |
```

- [ ] **Step 2: Update Business Rule 6**

Find:
```
6. `institution` field only set for B2B enrollments
```
Replace with:
```
6. `partner` field only set for B2B enrollments
```

- [ ] **Step 3: Update Related Domains — replace institution with partner + partnership-agreement**

Find:
```
- [institution](../institution/institution.md)
```
Replace with:
```
- [partner](../partner/partner.md)
- [partnership-agreement](../partnership-agreement/partnership-agreement.md)
```

- [ ] **Step 4: Commit**

```bash
git add docs/domains/enrollment/enrollment.md
git commit -m "docs: update enrollment domain — institution renamed to partner"
```

---

### Task 6: Update Payment domain doc

**Files:**
- Modify: `docs/domains/payment/payment.md`

- [ ] **Step 1: Add note that B2B payment terms resolve via PartnershipAgreement**

In the Overview or Business Rules section, add or update any reference to B2B pricing to note:
> B2B payment terms (`payment_model`, `payer`, `bulk_price`) are resolved from the partner's active PartnershipAgreement.

- [ ] **Step 2: Add PartnershipAgreement to Related Domains**

In `docs/domains/payment/payment.md`, add to Related Domains:
```
- [partnership-agreement](../partnership-agreement/partnership-agreement.md)
```

- [ ] **Step 3: Commit**

```bash
git add docs/domains/payment/payment.md
git commit -m "docs: link payment domain to partnership-agreement"
```

---

### Task 7: Update Calendar domain doc — add partner_meeting

**Files:**
- Modify: `docs/domains/calendar/calendar.md`

- [ ] **Step 1: Add `partner_meeting` to event_type enum in CalendarEvent table**

Find the `event_type` row in the CalendarEvent table:
```
| event_type | enum | `class_session`, `staff_meeting`, `admin_deadline`, `facilitator_schedule` |
```
Replace with:
```
| event_type | enum | `class_session`, `staff_meeting`, `admin_deadline`, `facilitator_schedule`, `partner_meeting` |
```

- [ ] **Step 2: Add 3 new optional fields to CalendarEvent table**

After the `created_at` row, add:
```
| partnership_agreement | PartnershipAgreement | Nullable; linked agreement for partner meetings |
| agenda | string | Nullable; pre-meeting agenda |
| meeting_notes | string | Nullable; filled post-meeting |
```

- [ ] **Step 3: Add business rules for new fields**

Append to Business Rules:
```
10. `agenda` and `meeting_notes` can be set on any `event_type` — not restricted to `partner_meeting`
11. `partnership_agreement` can be null on a `partner_meeting` — meeting may be created before an agreement exists (e.g. lead stage)
```

- [ ] **Step 4: Add partner and partnership-agreement to Related Domains**

Append to Related Domains:
```
- [partner](../partner/partner.md)
- [partnership-agreement](../partnership-agreement/partnership-agreement.md)
```

- [ ] **Step 5: Commit**

```bash
git add docs/domains/calendar/calendar.md
git commit -m "docs: add partner_meeting event type and partner fields to calendar domain"
```

---

### Task 8: Update Notification domain doc — add partner source

**Files:**
- Modify: `docs/domains/notification/notification.md`

- [ ] **Step 1: Add `partner` to source_domain enum on Notification entity**

Find the `source_domain` row in the Notification table:
```
| source_domain | enum | `payment`, `enrollment`, `facilitator`, `calendar`, `manual` |
```
Replace with:
```
| source_domain | enum | `payment`, `enrollment`, `facilitator`, `calendar`, `partner`, `manual` |
```

- [ ] **Step 2: Commit**

```bash
git add docs/domains/notification/notification.md
git commit -m "docs: add partner to notification source_domain enum"
```

---

### Task 9: Update docs/README.md — Institution → Partner

**Files:**
- Modify: `docs/README.md`

- [ ] **Step 1: Replace all references to Institution with Partner**

Read `docs/README.md` and replace:
- "Institution" → "Partner" in entity/domain lists
- "institution" → "partner" in field names or links
- Update the B2B business model description to reference PartnershipAgreement

- [ ] **Step 2: Commit**

```bash
git add docs/README.md
git commit -m "docs: update README — institution renamed to partner"
```

---

## Self-Review Checklist

| Spec requirement | Task |
|---|---|
| Partner entity (new fields: type, status, contact_name) | Task 1 |
| Partner business rules (lead/active/inactive status) | Task 1 |
| PartnershipAgreement entity | Task 2 |
| PartnerDocument entity | Task 2 |
| PartnershipAgreement business rules (one active, auto-expire, etc.) | Task 2 |
| Invoice entity | Task 3 |
| InvoiceLineItem entity | Task 3 |
| Invoice business rules (billed_to, auto-status, one per enrollment) | Task 3 |
| Institution domain deleted | Task 4 |
| Enrollment `institution` field → `partner` | Task 5 |
| Calendar `partner_meeting` event_type | Task 7 |
| Calendar new fields (partnership_agreement, agenda, meeting_notes) | Task 7 |
| Notification `partner` source_domain | Task 8 |
| README updated | Task 9 |
