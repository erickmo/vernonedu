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
6. `type = franchise_candidate` — a potential franchisee being evaluated. If the relationship converts to a franchise, a `Franchisee` record is created in the Franchise domain. The Partner record remains for contact history.

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `partner.status_changed` | `{partner_id, old_status, new_status}` | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

## Related Domains

- [partnership-agreement](../partnership-agreement/partnership-agreement.md)
- [enrollment](../enrollment/enrollment.md)
- [calendar](../calendar/calendar.md)
- [franchise](../franchise/franchise.md)
