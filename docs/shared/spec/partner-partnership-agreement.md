# Design: Partner & PartnershipAgreement Domains

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Rename Institution → Partner, new PartnershipAgreement domain, CalendarEvent expansion, cross-reference updates

---

## Overview

Three changes:

1. **Partner domain** — rename `institution` → `partner`, add `type` and `status` fields, keep entity lightweight
2. **PartnershipAgreement domain** — new domain; owns agreement lifecycle, expiry, documents, and B2B payment terms (moved from Institution)
3. **CalendarEvent expansion** — new `partner_meeting` event type, 3 optional fields for agenda/notes/agreement link

---

## Domain: Partner (renamed from Institution)

### Overview

External entities that have or may have a relationship with VernonEdu. Lightweight entity — formal terms live in PartnershipAgreement. B2B enrollment references Partner (replaces Institution).

### Entities

#### Partner

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

### Business Rules

1. `status = lead` — no active agreement yet; relationship in early stage
2. `status = active` — has at least one PartnershipAgreement with `status = active`
3. `status = inactive` — all agreements expired or terminated
4. B2B enrollment references Partner (field renamed from `institution` → `partner`)
5. All partner types can have PartnershipAgreements — `type` does not restrict features

---

## Domain: PartnershipAgreement

### Overview

Tracks formal agreements between VernonEdu and a Partner. One Partner can have multiple agreements over time (renewal cycles). Owns expiry tracking, documents, and B2B payment terms previously held by Institution.

### Entities

#### PartnershipAgreement

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
| bulk_price | decimal | Nullable; B2B bulk override price |
| signed_at | date | Nullable |
| terminated_at | date | Nullable |
| termination_reason | string | Nullable |
| created_by | User | |
| created_at | datetime | |

#### PartnerDocument

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| agreement | PartnershipAgreement | |
| type | enum | `mou`, `proposal` |
| title | string | |
| file_url | string | |
| uploaded_by | User | |
| uploaded_at | datetime | |

### Business Rules

1. One Partner can have multiple PartnershipAgreements — only one can be `active` at a time
2. `status = expired` auto-set when `end_date < today` and current status was `active`
3. `status = terminated` requires `termination_reason`
4. B2B enrollment resolves `payment_model`, `payer`, `bulk_price` from partner's `active` agreement
5. Agreement with `status = draft` cannot be referenced by B2B enrollment
6. `end_date = null` = open-ended; never auto-expires
7. Documents can be uploaded at any agreement status

---

## CalendarEvent Expansion

### New event_type

Add `partner_meeting` to the `event_type` enum:

```
class_session
staff_meeting
admin_deadline
facilitator_schedule
partner_meeting          ← new
```

### New optional fields on CalendarEvent

| Field | Type | Notes |
|---|---|---|
| partnership_agreement | PartnershipAgreement | Nullable |
| agenda | string | Nullable |
| meeting_notes | string | Nullable; filled post-meeting |

### Business Rules

1. `agenda` and `meeting_notes` can be set on any `event_type` — not restricted to `partner_meeting`
2. Partner meeting auto-creates CalendarAttendee for all tagged Users — same as other event types
3. `partnership_agreement` can be null — meeting can be created before an agreement exists (e.g. lead stage)

---

## Cross-reference Updates

### Files to rename / rewrite

| Current | New |
|---|---|
| `docs/domains/institution/institution.md` | `docs/domains/partner/partner.md` |

### New files

| File | Description |
|---|---|
| `docs/domains/partnership-agreement/partnership-agreement.md` | New domain doc |

### Files to update

| File | Change |
|---|---|
| `docs/domains/enrollment/enrollment.md` | `institution` field → `partner` (type: Partner); Related Domains: institution → partner |
| `docs/domains/payment/payment.md` | B2B payment terms note → resolved via PartnershipAgreement; Related Domains: add partnership-agreement |
| `docs/domains/calendar/calendar.md` | Add `partner_meeting` to event_type enum; add 3 new fields; add partnership-agreement to Related Domains |
| `docs/domains/notification/notification.md` | Add `partner` to `source_domain` enum on Notification entity |
| `docs/README.md` | Update Institution → Partner in Key Entities and Business Model sections |

---

## Related Domains

- [enrollment](../domains/enrollment/enrollment.md)
- [payment](../domains/payment/payment.md)
- [calendar](../domains/calendar/calendar.md)
- [notification](../domains/notification/notification.md)
