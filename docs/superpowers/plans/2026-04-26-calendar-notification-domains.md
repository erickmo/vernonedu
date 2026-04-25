# Calendar & Notification Domains Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Calendar and Notification domain documentation to VernonEdu, following the same format as existing domain docs, and update cross-references in all related domains.

**Architecture:** Two new domain folders under `docs/domains/`. Calendar owns scheduled event entities and Google Calendar sync. Notification owns centralized delivery (email, in-app, push) with template management and user preferences. All existing domains that fire notifications or generate calendar events gain a Related Domains entry pointing to these new domains.

**Tech Stack:** Markdown documentation only — no code changes in this plan.

**Spec:** `docs/superpowers/specs/2026-04-26-calendar-notification-design.md`

---

### Task 1: Create Calendar domain doc

**Files:**
- Create: `docs/domains/calendar/calendar.md`

- [ ] **Step 1: Create the file**

Create `docs/domains/calendar/calendar.md` with this exact content:

```markdown
# Domain: Calendar

## Overview

Internal-facing domain. Single source of truth for all scheduled events in VernonEdu — class sessions, staff meetings, admin deadlines, and facilitator schedules. Events can be auto-generated from other domains (course batches, payment terms) or created manually by staff. Supports Google Calendar sync (per-user opt-in) and iCal export.

## Entities

### CalendarEvent

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| title | string | |
| description | string | Nullable |
| event_type | enum | `class_session`, `staff_meeting`, `admin_deadline`, `facilitator_schedule` |
| start_at | datetime | |
| end_at | datetime | |
| is_all_day | boolean | |
| recurrence_rule | string | Nullable; iCal RRULE format (e.g. `FREQ=WEEKLY;BYDAY=MO`) |
| location | string | Nullable; venue address or online meeting link |
| source_domain | enum | Nullable; `course`, `enrollment`, `payment`, `facilitator`, `manual` |
| source_id | uuid | Nullable; FK to originating entity in source domain |
| created_by | User | |
| created_at | datetime | |

### CalendarAttendee

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| event | CalendarEvent | |
| user | User | Internal staff or facilitator |
| role | enum | `organizer`, `attendee` |
| rsvp_status | enum | `pending`, `accepted`, `declined` |

### CalendarSync

Stores Google Calendar OAuth credentials per user. One record per user.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| user | User | |
| provider | enum | `google_calendar` |
| access_token | string | Encrypted at rest |
| refresh_token | string | Encrypted at rest |
| last_synced_at | datetime | Nullable |

## Business Rules

1. Events with `source_domain` + `source_id` are auto-generated from another domain — read-only via Calendar UI
2. Manual events (`source_domain = null`) can be created directly in Calendar by any internal user
3. Recurring events use RRULE standard (iCal format); e.g. a weekly class = `FREQ=WEEKLY`
4. Google Calendar sync is per-user opt-in — not a global toggle
5. iCal export available per-user (all events) or per individual event
6. Class session events auto-created when a Course Batch is created with a Class schedule
7. When a facilitator is assigned to a class, a CalendarAttendee record is added to the existing `class_session` event for that class
8. Auto-generated events are updated (not replaced) if the source entity changes (e.g. class reschedule)
9. Deleting the source entity (e.g. dropping a class) removes the corresponding CalendarEvent

## Auto-Generated Events

| Trigger | event_type | source_domain | source_id |
|---|---|---|---|
| Course Batch created with Class schedule | `class_session` | `course` | `class.id` |
| Admin sets payment term due_date | `admin_deadline` | `payment` | `payment_term.id` |

## Integration

Calendar fires a `class.reminder` notification event to the Notification domain 1 hour before each `class_session` event. Recipients: all CalendarAttendees for that event.

## Related Domains

- [course](../course/course.md)
- [payment](../payment/payment.md)
- [facilitator](../facilitator/facilitator.md)
- [notification](../notification/notification.md)
```

- [ ] **Step 2: Verify file structure matches existing domain docs**

Check that the file has: Overview, Entities (with field tables), Business Rules (numbered list), Related Domains.
Compare against `docs/domains/enrollment/enrollment.md` — structure must be consistent.

- [ ] **Step 3: Commit**

```bash
git add docs/domains/calendar/calendar.md
git commit -m "docs: add calendar domain"
```

---

### Task 2: Create Notification domain doc

**Files:**
- Create: `docs/domains/notification/notification.md`

- [ ] **Step 1: Create the file**

Create `docs/domains/notification/notification.md` with this exact content:

```markdown
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

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [payment](../payment/payment.md)
- [facilitator](../facilitator/facilitator.md)
- [calendar](../calendar/calendar.md)
- [certificate](../certificate/certificate.md)
```

- [ ] **Step 2: Verify file structure**

Check that the file has: Overview, Entities (with field tables), Business Rules (numbered list), Trigger Keys table, Related Domains.
Compare against `docs/domains/payment/payment.md` — section depth and table formatting must match.

- [ ] **Step 3: Commit**

```bash
git add docs/domains/notification/notification.md
git commit -m "docs: add notification domain"
```

---

### Task 3: Update cross-references in Payment domain

**Files:**
- Modify: `docs/domains/payment/payment.md`

The payment domain mentions email/WhatsApp notifications in Business Rule 7. Update to reflect centralized Notification domain, and add Related Domains entry.

- [ ] **Step 1: Update Business Rule 7**

In `docs/domains/payment/payment.md`, find:
```
7. Student notified on each term due date (email/WhatsApp)
```

Replace with:
```
7. Student notified on each term due date — triggers `payment.term.due` via Notification domain
```

- [ ] **Step 2: Add notification and calendar to Related Domains**

In `docs/domains/payment/payment.md`, the Related Domains section currently ends with:
```
- [student](../student/student.md)
```

Append:
```
- [notification](../notification/notification.md)
- [calendar](../calendar/calendar.md)
```

- [ ] **Step 3: Commit**

```bash
git add docs/domains/payment/payment.md
git commit -m "docs: link payment domain to notification and calendar"
```

---

### Task 4: Update cross-references in Enrollment domain

**Files:**
- Modify: `docs/domains/enrollment/enrollment.md`

- [ ] **Step 1: Add notification to Related Domains**

In `docs/domains/enrollment/enrollment.md`, the Related Domains section currently ends with:
```
- [certificate](../certificate/certificate.md)
```

Append:
```
- [notification](../notification/notification.md)
```

- [ ] **Step 2: Commit**

```bash
git add docs/domains/enrollment/enrollment.md
git commit -m "docs: link enrollment domain to notification"
```

---

### Task 5: Update cross-references in Facilitator domain

**Files:**
- Modify: `docs/domains/facilitator/facilitator.md`

- [ ] **Step 1: Add notification and calendar to Related Domains**

In `docs/domains/facilitator/facilitator.md`, the Related Domains section currently ends with:
```
- [department](../department/department.md)
```

Append:
```
- [notification](../notification/notification.md)
- [calendar](../calendar/calendar.md)
```

- [ ] **Step 2: Commit**

```bash
git add docs/domains/facilitator/facilitator.md
git commit -m "docs: link facilitator domain to notification and calendar"
```

---

### Task 6: Update cross-references in Certificate domain

**Files:**
- Modify: `docs/domains/certificate/certificate.md`

- [ ] **Step 1: Add notification to Related Domains**

In `docs/domains/certificate/certificate.md`, locate the Related Domains section (or add one at the end if absent). Add:
```
## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [notification](../notification/notification.md)
```

If a Related Domains section already exists, append only the missing entries.

- [ ] **Step 2: Commit**

```bash
git add docs/domains/certificate/certificate.md
git commit -m "docs: link certificate domain to notification"
```

---

### Task 7: Update cross-references in Course domain

**Files:**
- Modify: `docs/domains/course/course.md`

- [ ] **Step 1: Add calendar to Related Domains**

In `docs/domains/course/course.md`, locate the Related Domains section. Add:
```
- [calendar](../calendar/calendar.md)
```

- [ ] **Step 2: Commit**

```bash
git add docs/domains/course/course.md
git commit -m "docs: link course domain to calendar"
```

---

## Self-Review Checklist

### Spec Coverage

| Spec requirement | Task |
|---|---|
| CalendarEvent entity | Task 1 |
| CalendarAttendee entity | Task 1 |
| CalendarSync entity (Google Calendar) | Task 1 |
| Calendar business rules (all 9) | Task 1 |
| Auto-generated events table | Task 1 |
| iCal export mentioned | Task 1 |
| Calendar → Notification integration (class.reminder) | Task 1 |
| NotificationTemplate entity | Task 2 |
| Notification entity | Task 2 |
| NotificationPreference entity | Task 2 |
| Delivery flow | Task 2 |
| Notification business rules (all 10) | Task 2 |
| All 8 trigger keys | Task 2 |
| Payment domain cross-ref | Task 3 |
| Payment Business Rule 7 updated | Task 3 |
| Enrollment domain cross-ref | Task 4 |
| Facilitator domain cross-ref | Task 5 |
| Certificate domain cross-ref | Task 6 |
| Course domain cross-ref | Task 7 |

All spec requirements covered. No gaps.
