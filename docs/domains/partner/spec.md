# Design: Partner Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Lightweight Partner profile entity; replaces former Institution domain

---

## Overview

External entities with formal or potential relationship with VernonEdu. Lightweight profile — agreement terms (pricing, payer, documents) live in PartnershipAgreement. B2B enrollments reference Partner.

---

## Entities

### Partner

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| name | string | |
| type | enum | `university`, `vendor`, `sponsor`, `franchise_candidate`, `community`, `other` |
| status | enum | `lead`, `active`, `inactive` |
| contact_name | string | Nullable |
| contact_email | string | Nullable |
| contact_phone | string | Nullable |
| address | string | Nullable |
| notes | string | Nullable; internal |
| created_at | datetime | |

---

## Business Rules

1. `status = lead` — no active agreement; early stage
2. `status = active` — has 1+ PartnershipAgreement with `status = active`
3. `status = inactive` — all agreements expired/terminated
4. B2B enrollment references Partner (renamed from `institution`)
5. All partner types support PartnershipAgreements — `type` doesn't restrict features
6. `type = franchise_candidate` — potential franchisee. If converts, Franchisee record created in Franchise domain. Partner record retained for contact history.

---

## Background Jobs

| — | — | — |

(Partner status transitions are derived from PartnershipAgreement state — no time-based jobs owned here.)

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `partner.status_changed` | `{partner_id, old_status, new_status}` | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

---

## Related Domains

- [partnership-agreement](../partnership-agreement/partnership-agreement.md)
- [enrollment](../enrollment/enrollment.md)
- [calendar](../calendar/calendar.md)
- [franchise](../franchise/franchise.md)
