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

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `class.reminder` | `{event_id, class_id, start_at, attendee_ids}` | Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `course.batch.created` | Course | Auto-create `class_session` CalendarEvent for each class |
| `course.class.facilitator_assigned` | Course | Add CalendarAttendee to existing `class_session` event |
| `payment.term.due` | Payment | Auto-create `admin_deadline` CalendarEvent |
| `facilitator.approved` | Facilitator | Add CalendarAttendee (facilitator) to `class_session` event |

## Related Domains

- [course](../course/course.md)
- [payment](../payment/payment.md)
- [facilitator](../facilitator/facilitator.md)
- [notification](../notification/notification.md)
