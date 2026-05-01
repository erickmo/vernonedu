# Design: Calendar Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Single source of truth for all internal scheduled events; supports auto-generation, Google Calendar sync, iCal export

---

## Overview

Internal-facing domain. Single source of truth for all scheduled events — class sessions, staff meetings, admin deadlines, facilitator schedules, partner meetings. Events auto-generated from other domains or created manually. Supports per-user Google Calendar sync (opt-in) and iCal export.

---

## Entities

### CalendarEvent

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| title | string | |
| description | string | Nullable |
| event_type | enum | `class_session`, `staff_meeting`, `admin_deadline`, `payment_due`, `facilitator_schedule`, `partner_meeting` |
| start_at | datetime | |
| end_at | datetime | |
| is_all_day | boolean | |
| recurrence_rule | string | Nullable; iCal RRULE |
| location | string | Nullable; venue or online link |
| source_domain | enum | Nullable; `course`, `enrollment`, `payment`, `team_member`, `partner`, `manual` |
| source_id | uuid | Nullable; FK to source entity |
| partnership_agreement | PartnershipAgreement | Nullable; for `partner_meeting` |
| agenda | string | Nullable; for `partner_meeting` |
| meeting_notes | string | Nullable; post-meeting notes |
| created_by | User | |
| created_at | datetime | |

### CalendarAttendee

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| event | CalendarEvent | |
| user | User | |
| role | enum | `organizer`, `attendee` |
| rsvp_status | enum | `pending`, `accepted`, `declined` |

### CalendarSync
Google OAuth credentials per user. One per user.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| user | User | |
| provider | enum | `google_calendar` |
| access_token | string | Encrypted at rest |
| refresh_token | string | Encrypted at rest |
| last_synced_at | datetime | Nullable |
| token_expires_at | datetime | Nullable; Google access tokens expire in 1 hour |

---

## Business Rules

1. Events with `source_domain` + `source_id` are auto-generated — read-only via Calendar UI
2. Manual events (`source_domain = null`) creatable by any internal user
3. Recurring events use iCal RRULE
4. Google Calendar sync per-user opt-in
5. iCal export per-user (all events) or per individual event
6. Class session events auto-created on Course Batch creation with Class schedule
7. Facilitator class assignment → CalendarAttendee added to existing class_session event
8. Auto-generated events updated (not replaced) on source entity change
9. Source entity deletion removes corresponding CalendarEvent

---

## Auto-Generated Events

| Trigger | event_type | source_domain | source_id |
|---|---|---|---|
| Course Batch created with Class schedule | `class_session` | `course` | `class.id` |
| Admin sets payment term due_date | `payment_due` | `payment` | `payment_term.id` |
| Partner meeting scheduled via PartnershipAgreement | `partner_meeting` | `partner` | `partnership_agreement.id` |

---

## Background Jobs

| — | — | — |

(Class reminder dispatch is event-driven — fired 1 hour before each `class_session` start_at by a scheduled scanner, treated as part of event delivery rather than a state-transition job.)

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `class.reminder` | `{event_id, class_id, start_at, attendee_ids}` | Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `course.batch.created` | Course | Auto-create class_session events |
| `course.class.facilitator_assigned` | Course | Add CalendarAttendee to class_session |
| `payment.term.due` | Payment | Auto-create payment_due event |
| `facilitator.approved` | Team Member | Add facilitator as CalendarAttendee |
| `course.class.rescheduled` | Course | Update existing class_session event |
| `course.class.cancelled` | Course | Delete class_session + attendees |

---

## Related Domains

- [course](../course/course.md)
- [payment](../payment/payment.md)
- [team-member](../team-member/team-member.md)
- [notification](../notification/notification.md)
- [partner](../partner/partner.md)
- [partnership-agreement](../partnership-agreement/partnership-agreement.md)
