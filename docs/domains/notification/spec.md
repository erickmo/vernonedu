# Design: Notification Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Centralized notification delivery via Email, In-App, Push with templates and per-user preferences

---

## Overview

Centralized notification delivery service. All domains fire triggers by key. Notification owns templates, delivery (Email, In-App, Push), per-user preferences, delivery logging, and retry.

---

## Entities

### NotificationTemplate
One per key+channel.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| key | string | Unique slug per trigger, e.g. `payment.term.due` |
| channel | enum | `email`, `in_app`, `push` |
| subject | string | Nullable; email subject |
| body | string | Handlebars/Mustache; `{{variable}}` |
| is_active | boolean | Inactive skipped |

### Notification
One per delivery attempt per recipient per channel.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| recipient | User | |
| template | NotificationTemplate | |
| channel | enum | `email`, `in_app`, `push` |
| variables | json | Frozen at send time |
| status | enum | `pending`, `sent`, `failed`, `read` |
| source_domain | enum | `payment`, `enrollment`, `team_member`, `calendar`, `partner`, `manual` |
| source_id | uuid | Nullable |
| scheduled_at | datetime | Nullable; deferred delivery |
| sent_at | datetime | Nullable |
| read_at | datetime | Nullable; in_app only |
| retry_count | integer | Default 0 |
| error_message | string | Nullable |
| created_at | datetime | |

### NotificationPreference
Per user per template_key per channel. Absence = enabled by default.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| user | User | |
| template_key | string | Matches template key |
| channel | enum | `email`, `in_app`, `push` |
| enabled | boolean | |

---

## Delivery Flow

```
Domain event (key + variables + recipients)
  → Resolve NotificationTemplate by key + channel
  → For each recipient:
      → Check NotificationPreference (skip if disabled)
      → Create Notification (pending)
  → Worker processes pending
  → Send via channel
  → Success → status: sent, sent_at = now
  → Failure → retry_count++
      → < 3 → requeue
      → = 3 → status: failed, alert admin
```

---

## Trigger Keys

| Key | Triggered by | Default Recipients |
|---|---|---|
| `enrollment.confirmed` | Enrollment | Student |
| `payment.term.due` | Payment | Student, Admin |
| `payment.term.overdue` | Payment | Student, Admin |
| `payment.confirmed` | Payment | Student |
| `facilitator.proposed` | Team Member | Dept Leader |
| `facilitator.approved` | Team Member | Course Creator, Facilitator |
| `facilitator.rejected` | Team Member | Course Creator, Facilitator |
| `user.welcome` | Auth | New user |
| `invoice.sent` | Invoice | Partner (B2B) or Student (B2C) |
| `invoice.overdue` | Invoice | Partner/Student, Admin |
| `team_member.created` | Team Member | New member, Dept Leader |
| `team_member.status_changed` | Team Member | Member, Dept Leader |
| `class.reminder` | Calendar | Facilitator, Class Attendees |
| `certificate.issued` | Certificate | Student |

---

## Business Rules

1. All domains trigger by key — no embedded message content
2. Missing template for key+channel → skipped silently
3. Inactive template → skipped silently
4. NotificationPreference absent = enabled
5. `variables` frozen at creation — template changes don't affect sent records
6. `status → read` only for `in_app`
7. Push requires device token; missing token = skipped (not error)
8. `scheduled_at` set → worker holds until then
9. Retry max = 3; after 3 failures admin alerted
10. Required template variables validated before record creation; missing = blocked + logged

---

## Background Jobs

- **Pending delivery worker** (continuous): pick up `status = pending` Notifications past `scheduled_at`, deliver, retry on failure (max 3)
- **Scheduled-trigger scanner** (e.g., per minute): wake up scheduled Notifications whose `scheduled_at <= now`

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `enrollment.confirmed` | Enrollment | Send `enrollment.confirmed` to Student |
| `payment.confirmed` | Payment | Send `payment.confirmed` to Student |
| `payment.term.due` | Payment | Send to Student, Admin |
| `payment.term.overdue` | Payment | Send to Student, Admin |
| `auth.user.created` | Auth | Send `user.welcome` |
| `facilitator.proposed` | Team Member | Send to Dept Leader |
| `facilitator.approved` | Team Member | Send to Course Creator, Facilitator |
| `facilitator.rejected` | Team Member | Send to Course Creator, Facilitator |
| `invoice.sent` | Invoice | Send to billed party |
| `invoice.overdue` | Invoice | Send to billed party + Admin |
| `team_member.created` | Team Member | Send to new member + Dept Leader |
| `team_member.status_changed` | Team Member | Send to member + Dept Leader |
| `class.reminder` | Calendar | Send to Facilitator + Attendees |
| `certificate.issued` | Certificate | Send to Student |

---

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [payment](../payment/payment.md)
- [team-member](../team-member/team-member.md)
- [calendar](../calendar/calendar.md)
- [certificate](../certificate/certificate.md)
