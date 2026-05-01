# Design: Calendar & Notification Domains

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Two new domains — Calendar (internal scheduling) and Notification (centralized delivery)

---

## Overview

VernonEdu needs two new domains:

- **Calendar** — manages all scheduled events for internal team: class sessions, staff meetings, admin deadlines, facilitator schedules. Supports Google Calendar sync and iCal export.
- **Notification** — centralized notification service. All domains fire events here. Owns delivery via Email, In-App, and Push.

Both domains are independent. Calendar fires events to Notification; they do not share a dependency in the other direction.

---

## Domain: Calendar

### Purpose

Internal-facing. Single source of truth for all scheduled events in VernonEdu. Events can be auto-generated from other domains (course batches, payment terms) or created manually by staff.

### Entities

#### CalendarEvent

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| title | string | |
| description | string | Nullable |
| event_type | enum | `class_session`, `staff_meeting`, `admin_deadline`, `facilitator_schedule` |
| start_at | datetime | |
| end_at | datetime | |
| is_all_day | boolean | |
| recurrence_rule | string | Nullable; iCal RRULE format |
| location | string | Nullable; venue or online link |
| source_domain | enum | Nullable; `course`, `enrollment`, `payment`, `facilitator`, `manual` |
| source_id | uuid | Nullable; FK to originating entity |
| created_by | User | |
| created_at | datetime | |

#### CalendarAttendee

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| event | CalendarEvent | |
| user | User | Internal staff or facilitator |
| role | enum | `organizer`, `attendee` |
| rsvp_status | enum | `pending`, `accepted`, `declined` |

#### CalendarSync

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| user | User | |
| provider | enum | `google_calendar` |
| access_token | string | Encrypted |
| refresh_token | string | Encrypted |
| last_synced_at | datetime | Nullable |

### Business Rules

1. Events with `source_domain` + `source_id` = auto-generated from another domain — read-only via Calendar UI
2. Manual events (`source_domain = null`) can be created directly in Calendar
3. Recurring events use RRULE standard (iCal format), e.g. weekly classes
4. Google Calendar sync is per-user opt-in — not global
5. iCal export available per-user or per-event
6. Class session events auto-created when a Course Batch is created with a Class schedule
7. When a facilitator is assigned to a class, a CalendarAttendee record is added to the existing class_session event

### Auto-Generated Events

| Trigger | Event Type | source_domain | source_id |
|---|---|---|---|
| Course Batch created with Class schedule | `class_session` | `course` | `class.id` |
| Admin sets payment term due_date | `admin_deadline` | `payment` | `payment_term.id` |

---

## Domain: Notification

### Purpose

Centralized delivery service. All domains fire notification triggers here by key. Notification domain owns template management, channel delivery (Email, In-App, Push), user preferences, and delivery logging.

### Entities

#### NotificationTemplate

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| key | string | Unique slug, e.g. `payment.term.due` |
| channel | enum | `email`, `in_app`, `push` |
| subject | string | Nullable; email subject line |
| body | string | Handlebars/Mustache template |
| is_active | boolean | |

#### Notification

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| recipient | User | |
| template | NotificationTemplate | |
| channel | enum | `email`, `in_app`, `push` |
| variables | json | Template variables captured at send time |
| status | enum | `pending`, `sent`, `failed`, `read` |
| source_domain | enum | `payment`, `enrollment`, `facilitator`, `calendar`, `manual` |
| source_id | uuid | Nullable |
| scheduled_at | datetime | Nullable; for scheduled sends |
| sent_at | datetime | Nullable |
| read_at | datetime | Nullable; in_app only |
| error_message | string | Nullable; last delivery error |
| created_at | datetime | |

#### NotificationPreference

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| user | User | |
| template_key | string | e.g. `payment.term.due` |
| channel | enum | `email`, `in_app`, `push` |
| enabled | boolean | |

### Delivery Flow

```
Domain event fires (e.g. payment term due)
  → Notification domain receives trigger with key + variables + recipient
  → Resolves NotificationTemplate by key + channel
  → Checks recipient's NotificationPreference
  → If enabled → creates Notification record (status: pending)
  → Delivery worker sends via channel
  → Updates status: sent / failed
  → Retry on failure (max 3x)
  → After 3 failures → status: failed, alert admin
```

### Business Rules

1. Every notification type has a `key` — domain lain reference by key only, not hardcoded messages
2. Recipient can disable any notification type per channel via NotificationPreference
3. In-app notifications: `status → read` when user opens the notification
4. Push notification requires device token stored on User
5. Scheduled notifications (e.g. "1 day before payment due") use `scheduled_at` field
6. Failed delivery after 3 retries → status `failed`, admin alerted
7. Template variables validated at send time — missing variable blocks delivery and logs error
8. Each template key can have up to 3 NotificationTemplate records (one per channel)

### Trigger Keys (initial set)

| Key | Triggered by | Recipients |
|---|---|---|
| `enrollment.confirmed` | Enrollment domain | Student |
| `payment.term.due` | Payment domain | Student, Admin |
| `payment.term.overdue` | Payment domain | Student, Admin |
| `payment.confirmed` | Payment domain | Student |
| `facilitator.proposed` | Facilitator domain | Dept Leader |
| `facilitator.approved` | Facilitator domain | Course Creator, Facilitator |
| `class.reminder` | Calendar domain | Facilitator, Attendees |
| `certificate.issued` | Certificate domain | Student |

---

## Inter-domain Integration

### How Domains Trigger Notifications

Domains do not import the Notification domain. They fire domain events; Notification domain subscribes.

```
Payment domain
  → on term due_date approaching (T-1 day) → fire "payment.term.due"
  → on term overdue → fire "payment.term.overdue"
  → on transaction confirmed → fire "payment.confirmed"

Enrollment domain
  → on enrollment created → fire "enrollment.confirmed"

Facilitator domain
  → on facilitator proposed → fire "facilitator.proposed"
  → on facilitator approved → fire "facilitator.approved"

Certificate domain
  → on certificate issued → fire "certificate.issued"

Calendar domain
  → on class_session event T-1 hour → fire "class.reminder"
```

### Dependency Map

```
Calendar ──depends on──► Course, Payment (reads schedules to auto-create events)
Notification ──depends on──► All domains (receives triggers)
All domains ──fire events to──► Notification
Calendar ──fires events to──► Notification (class.reminder)
```

Calendar and Notification do not depend on each other — Calendar only fires events to Notification.

---

## Related Domains

- [course](../domains/course/course.md)
- [payment](../domains/payment/payment.md)
- [enrollment](../domains/enrollment/enrollment.md)
- [facilitator](../domains/facilitator/facilitator.md)
- [certificate](../domains/certificate/certificate.md)
