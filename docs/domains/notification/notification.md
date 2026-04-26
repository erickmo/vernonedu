# Domain: Notification

## Overview

Centralized notification delivery service. All domains fire notification triggers here by key. Notification domain owns template management, delivery via Email, In-App, and Push channels, user delivery preferences, and delivery logging with retry.

## Entities

### NotificationTemplate

One record per key+channel combination. Each trigger key can have up to 3 templates (one per channel).

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| key | string | Unique slug per trigger, e.g. `payment.term.due` |
| channel | enum | `email`, `in_app`, `push` |
| subject | string | Nullable; used for email subject line |
| body | string | Handlebars/Mustache template; supports `{{variable}}` syntax |
| is_active | boolean | Inactive templates are skipped during delivery |

### Notification

One record per delivery attempt per recipient per channel.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| recipient | User | |
| template | NotificationTemplate | |
| channel | enum | `email`, `in_app`, `push` |
| variables | json | Template variables captured at send time (immutable after creation) |
| status | enum | `pending`, `sent`, `failed`, `read` |
| source_domain | enum | `payment`, `enrollment`, `facilitator`, `calendar`, `manual` |
| source_id | uuid | Nullable; originating entity in source domain |
| scheduled_at | datetime | Nullable; if set, delivery deferred until this time |
| sent_at | datetime | Nullable |
| read_at | datetime | Nullable; in_app channel only |
| retry_count | integer | Default 0; incremented on each failed delivery attempt |
| error_message | string | Nullable; last delivery error detail |
| created_at | datetime | |

### NotificationPreference

User opt-in/opt-out per notification type per channel. Defaults to enabled if no preference record exists.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| user | User | |
| template_key | string | Matches a NotificationTemplate key |
| channel | enum | `email`, `in_app`, `push` |
| enabled | boolean | |

## Delivery Flow

```
Domain event fires (key + variables + recipient list)
  → Resolve NotificationTemplate by key + channel
  → For each recipient:
      → Check NotificationPreference — skip if disabled
      → Create Notification record (status: pending)
  → Delivery worker processes pending Notifications
  → Send via channel
  → On success → status: sent, sent_at = now
  → On failure → retry_count++
      → If retry_count < 3 → requeue
      → If retry_count = 3 → status: failed, alert admin
```

## Business Rules

1. All domains trigger notifications via key — no domain embeds message content directly
2. Missing template for a key+channel → notification skipped silently (not an error)
3. Inactive template (`is_active = false`) → notification skipped silently
4. `NotificationPreference` absence = enabled by default
5. `variables` JSON is frozen at creation time — template changes do not affect sent records
6. `status → read` only for `in_app` channel, set when user opens the notification
7. Push delivery requires a device token stored on the User; missing token = notification skipped, not errored
8. `scheduled_at` set → delivery worker holds until that datetime before processing
9. Retry max = 3 attempts; after 3 failures admin is alerted
10. Template variables are validated before creating the Notification record — missing required variable blocks creation and logs an error

## Trigger Keys

| Key | Triggered by | Default Recipients |
|---|---|---|
| `enrollment.confirmed` | Enrollment | Student |
| `payment.term.due` | Payment | Student, Admin |
| `payment.term.overdue` | Payment | Student, Admin |
| `payment.confirmed` | Payment | Student |
| `facilitator.proposed` | Facilitator | Dept Leader |
| `facilitator.approved` | Facilitator | Course Creator, Facilitator |
| `class.reminder` | Calendar | Facilitator, Class Attendees |
| `certificate.issued` | Certificate | Student |

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `enrollment.confirmed` | Enrollment | Send `enrollment.confirmed` notification to Student |
| `payment.confirmed` | Payment | Send `payment.confirmed` notification to Student |
| `payment.term.due` | Payment | Send `payment.term.due` notification to Student, Admin |
| `payment.term.overdue` | Payment | Send `payment.term.overdue` notification to Student, Admin |
| `facilitator.proposed` | Facilitator | Send `facilitator.proposed` notification to Dept Leader |
| `facilitator.approved` | Facilitator | Send `facilitator.approved` notification to Course Creator, Facilitator |
| `class.reminder` | Calendar | Send `class.reminder` notification to Facilitator, Attendees |
| `certificate.issued` | Certificate | Send `certificate.issued` notification to Student |

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [payment](../payment/payment.md)
- [facilitator](../facilitator/facilitator.md)
- [calendar](../calendar/calendar.md)
- [certificate](../certificate/certificate.md)
