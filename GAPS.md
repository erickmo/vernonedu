# Platform Domain Audit: Gaps Report

**Date:** 2026-04-27  
**Scope:** Align `backend/domains/platform` with `docs/domains/calendar/spec.md` + `docs/domains/notification/spec.md`

**Source-of-Truth Files Audited:**
- `docs/domains/calendar/spec.md`
- `docs/domains/notification/spec.md`
- `backend/migrations/000007_init_platform.up.sql`
- `backend/sqlc/platform.sql`
- `backend/internal/db/generated/platform.sql.go`
- `backend/domains/platform/{model,repository,service,handler,events,module}.go`

---

## 1. Entities/Types

### NotificationTemplate
- [x] ID (uuid) — PRESENT (model.go:27)
- [x] Key (string) — PRESENT (model.go:28)
- [x] Channel (enum: email, in_app, push) — PRESENT (model.go:9–15, model.go:29)
- [x] Subject (string, nullable) — PRESENT (model.go:30)
- [x] Body (string) — PRESENT (model.go:31)
- [x] IsActive (boolean) — PRESENT (model.go:32)
- [x] CreatedAt (datetime) — PRESENT (model.go:33)
- [x] UpdatedAt (datetime) — PRESENT (model.go:34)

### Notification
- [x] ID (uuid) — PRESENT (model.go:38)
- [x] RecipientID (uuid) — PRESENT (model.go:39)
- [x] TemplateID (uuid) — PRESENT (model.go:40)
- [x] Channel (enum) — PRESENT (model.go:41)
- [x] Variables (json) — PRESENT (model.go:42)
- [x] Status (enum: pending, sent, failed, read) — PRESENT (model.go:17–24, model.go:43)
- [x] SourceDomain (enum, nullable) — PRESENT (model.go:44)
- [x] SourceID (uuid, nullable) — PRESENT (model.go:45)
- [x] ScheduledAt (datetime, nullable) — PRESENT (model.go:46)
- [x] SentAt (datetime, nullable) — PRESENT (model.go:47)
- [x] ReadAt (datetime, nullable) — PRESENT (model.go:48)
- [x] RetryCount (integer) — PRESENT (model.go:49)
- [x] ErrorMessage (string, nullable) — PRESENT (model.go:50)
- [x] CreatedAt (datetime) — PRESENT (model.go:51)
- [x] UpdatedAt (datetime) — PRESENT (model.go:52)

### NotificationPreference
- [x] ID (uuid) — PRESENT (model.go:56)
- [x] UserID (uuid) — PRESENT (model.go:57)
- [x] TemplateKey (string) — PRESENT (model.go:58)
- [x] Channel (enum) — PRESENT (model.go:59)
- [x] Enabled (boolean) — PRESENT (model.go:60)
- [x] CreatedAt (datetime) — PRESENT (model.go:61)
- [x] UpdatedAt (datetime) — PRESENT (model.go:62)

### CalendarEvent
- [ ] id (uuid) — **MISSING** (not in model.go)
- [ ] title (string) — **MISSING**
- [ ] description (string, nullable) — **MISSING**
- [ ] event_type (enum: class_session, staff_meeting, admin_deadline, payment_due, facilitator_schedule, partner_meeting) — **MISSING**
- [ ] start_at (datetime) — **MISSING**
- [ ] end_at (datetime) — **MISSING**
- [ ] is_all_day (boolean) — **MISSING**
- [ ] recurrence_rule (string, nullable; iCal RRULE) — **MISSING**
- [ ] location (string, nullable) — **MISSING**
- [ ] source_domain (enum, nullable) — **MISSING**
- [ ] source_id (uuid, nullable) — **MISSING**
- [ ] partnership_agreement (PartnershipAgreement, nullable) — **MISSING**
- [ ] agenda (string, nullable; for partner_meeting) — **MISSING**
- [ ] meeting_notes (string, nullable; post-meeting) — **MISSING**
- [ ] created_by (User) — **MISSING**
- [ ] created_at (datetime) — **MISSING**

### CalendarAttendee
- [ ] id (uuid) — **MISSING**
- [ ] event (CalendarEvent) — **MISSING**
- [ ] user (User) — **MISSING**
- [ ] role (enum: organizer, attendee) — **MISSING**
- [ ] rsvp_status (enum: pending, accepted, declined) — **MISSING**

### CalendarSync
- [ ] id (uuid) — **MISSING**
- [ ] user (User) — **MISSING**
- [ ] provider (enum: google_calendar) — **MISSING**
- [ ] access_token (string, encrypted at rest) — **MISSING**
- [ ] refresh_token (string, encrypted at rest) — **MISSING**
- [ ] last_synced_at (datetime, nullable) — **MISSING**
- [ ] token_expires_at (datetime, nullable) — **MISSING**

---

## 2. Repository Methods

### NotificationTemplate operations
- [x] GetTemplateByKeyAndChannel(key, channel) → NotificationTemplate — PRESENT (repository.go:37–51)
- [ ] CreateTemplate(id, key, channel, subject, body, is_active) → NotificationTemplate — **MISSING**
- [ ] UpdateTemplate(id, subject, body, is_active) — **MISSING**
- [ ] ListTemplatesByKey(key) → []NotificationTemplate — **MISSING**
- [ ] DeactivateTemplate(key, channel) — **MISSING**

### Notification operations
- [x] CreateNotification(n) → error — PRESENT (repository.go:54–68)
- [x] GetNotificationByID(id) → Notification — PRESENT (repository.go:71–88)
- [x] UpdateNotificationStatus(id, status) — PRESENT (repository.go:91–100)
- [x] ListPendingNotifications(limit) → []Notification — PRESENT (repository.go:103–127)
- [x] ListNotificationsByRecipient(recipientID, limit, offset) → []Notification — PRESENT (repository.go:130–153)
- [x] MarkNotificationRead(id) — PRESENT (repository.go:156–162)
- [ ] UpdateNotificationRetryCount(id, retryCount, errorMessage) — **MISSING** (needed for retry logic)
- [ ] ListNotificationsBySourceDomain(sourceDomain, sourceID) → []Notification — **MISSING**
- [ ] DeleteNotificationsBySourceID(sourceDomain, sourceID) — **MISSING** (for source entity deletion cleanup)

### NotificationPreference operations
- [x] GetPreference(userID, templateKey, channel) → NotificationPreference — PRESENT (repository.go:165–179)
- [x] UpsertPreference(pref) — PRESENT (repository.go:182–194)
- [ ] GetPreferencesByUser(userID) → []NotificationPreference — **MISSING**
- [ ] DeletePreference(userID, templateKey, channel) — **MISSING**

### CalendarEvent operations (entire set missing)
- [ ] CreateCalendarEvent(event) — **MISSING**
- [ ] GetCalendarEventByID(id) — **MISSING**
- [ ] ListCalendarEventsBySourceDomain(sourceDomain, sourceID) — **MISSING**
- [ ] UpdateCalendarEvent(id, ...) — **MISSING**
- [ ] DeleteCalendarEventByID(id) — **MISSING**
- [ ] ListCalendarEventsByDateRange(start, end, userID) — **MISSING**
- [ ] ListCalendarEventsByType(eventType) — **MISSING**

### CalendarAttendee operations (entire set missing)
- [ ] AddCalendarAttendee(eventID, userID, role) — **MISSING**
- [ ] GetAttendeesByEventID(eventID) — **MISSING**
- [ ] RemoveAttendee(eventID, userID) — **MISSING**
- [ ] UpdateRSVPStatus(eventID, userID, status) — **MISSING**

### CalendarSync operations (entire set missing)
- [ ] UpsertCalendarSync(userID, provider, accessToken, refreshToken, expiresAt) — **MISSING**
- [ ] GetCalendarSyncByUser(userID, provider) — **MISSING**
- [ ] UpdateCalendarSyncTokens(userID, provider, accessToken, refreshToken, expiresAt) — **MISSING**
- [ ] UpdateCalendarSyncLastSynced(userID, provider, lastSyncedAt) — **MISSING**
- [ ] DeleteCalendarSync(userID, provider) — **MISSING**

---

## 3. Service Methods

### Notification delivery
- [x] Send(ctx, SendInput) → *Notification — PRESENT (service.go:34–59)
  - ✓ Resolves template by key+channel
  - ✓ Checks NotificationPreference
  - ✓ Creates pending Notification
  - ✗ Missing: Does NOT check NotificationPreference before creating (should skip if disabled per spec rule 4)
- [x] MarkRead(ctx, id) — PRESENT (service.go:62–64)
- [x] ListMyNotifications(ctx, recipientID, limit, offset) — PRESENT (service.go:67–72)
- [x] ProcessPending(ctx, batchSize) — PRESENT (service.go:75–87)
  - ✗ **BUG**: Does NOT actually send notifications; only marks as sent. Missing delivery logic (Email/In-App/Push channels).
  - ✗ Missing: Retry logic (max 3 retries per spec)
  - ✗ Missing: Error handling and error_message updates
  - ✗ Missing: sent_at timestamp updates (partially fixed in repository UPDATE query)

### Calendar event management
- [ ] CreateCalendarEvent(ctx, event) — **MISSING**
- [ ] UpdateCalendarEvent(ctx, id, event) — **MISSING**
- [ ] DeleteCalendarEvent(ctx, id) — **MISSING**
- [ ] GetCalendarEventByID(ctx, id) — **MISSING**
- [ ] ListCalendarEventsByDateRange(ctx, start, end, userID) — **MISSING**

### Calendar attendee management
- [ ] AddAttendeeToEvent(ctx, eventID, userID, role) — **MISSING**
- [ ] RemoveAttendeeFromEvent(ctx, eventID, userID) — **MISSING**
- [ ] UpdateRSVPStatus(ctx, eventID, userID, status) — **MISSING**

### Calendar sync
- [ ] SyncGoogleCalendar(ctx, userID) — **MISSING** (scheduled scanner)
- [ ] RefreshGoogleOAuthToken(ctx, userID) — **MISSING**

### Notification preference management
- [ ] SetPreference(ctx, userID, templateKey, channel, enabled) — **MISSING**
- [ ] GetUserPreferences(ctx, userID) → []NotificationPreference — **MISSING**

---

## 4. HTTP Routes

### Defined in handler.go
- [x] ListMyNotifications — PRESENT (handler.go:24–42, routes at /api/v1/notifications GET)
- [x] MarkRead — PRESENT (handler.go:44–56, routes at /api/v1/notifications/{id}/read POST)

### Missing routes (per spec, no explicit HTTP routes but implied CRUD)
- [ ] POST /api/v1/calendar-events — Create CalendarEvent
- [ ] GET /api/v1/calendar-events/{id} — Get CalendarEvent
- [ ] PUT /api/v1/calendar-events/{id} — Update CalendarEvent
- [ ] DELETE /api/v1/calendar-events/{id} — Delete CalendarEvent
- [ ] GET /api/v1/calendar-events — List (query by date range, type)
- [ ] POST /api/v1/calendar-events/{id}/attendees — Add attendee
- [ ] DELETE /api/v1/calendar-events/{id}/attendees/{user_id} — Remove attendee
- [ ] PUT /api/v1/calendar-events/{id}/attendees/{user_id} — Update RSVP status
- [ ] GET /api/v1/calendar/sync — Get user's calendar sync status
- [ ] POST /api/v1/calendar/sync/{provider} — Authorize calendar sync
- [ ] DELETE /api/v1/calendar/sync/{provider} — Revoke calendar sync
- [ ] GET /api/v1/notification-preferences — List user's preferences
- [ ] PUT /api/v1/notification-preferences/{template_key}/{channel} — Set preference

---

## 5. Cross-Domain Events (Calendar)

### Events fired by Calendar (platform fires these)
- [ ] `class.reminder` — **MISSING HANDLER**
  - Payload: `{event_id, class_id, start_at, attendee_ids}`
  - Known listener: Notification

### Events listened by Calendar (platform reacts to these)
- [ ] `course.batch.created` — **MISSING HANDLER** (subscription stub in events.go but no impl)
  - Action: Auto-create class_session events
- [ ] `course.class.facilitator_assigned` — **MISSING HANDLER**
  - Action: Add CalendarAttendee to class_session
- [ ] `course.class.rescheduled` — **MISSING HANDLER**
  - Action: Update existing class_session event
- [ ] `course.class.cancelled` — **MISSING HANDLER**
  - Action: Delete class_session + attendees
- [ ] `facilitator.approved` (from team_member) — **MISSING HANDLER**
  - Action: Add facilitator as CalendarAttendee to class sessions

---

## 6. Cross-Domain Events (Notification)

### Event subscriptions registered in events.go
- [x] PaymentTermOverdue — PRESENT (stub at events.go:11–12, no implementation)
- [x] InvoiceOverdue — PRESENT (stub at events.go:14–15, no implementation)
- [x] CertificateIssued — PRESENT (stub at events.go:17–18, no implementation)
- [x] EnrollmentConfirmed — PRESENT (stub at events.go:20–21, no implementation)

### Missing notification event subscriptions (per spec Trigger Keys)
- [ ] `enrollment.confirmed` — Should send to Student
- [ ] `payment.term.due` — Should send to Student, Admin
- [ ] `payment.term.overdue` — Should send to Student, Admin
- [ ] `payment.confirmed` — Should send to Student
- [ ] `facilitator.proposed` — Should send to Dept Leader
- [ ] `facilitator.approved` — Should send to Course Creator, Facilitator
- [ ] `facilitator.rejected` — Should send to Course Creator, Facilitator
- [ ] `user.welcome` — Should send to New user
- [ ] `invoice.sent` — Should send to Partner (B2B) or Student (B2C)
- [ ] `invoice.overdue` — Should send to Partner/Student, Admin
- [ ] `team_member.created` — Should send to new member + Dept Leader
- [ ] `team_member.status_changed` — Should send to member + Dept Leader
- [ ] `class.reminder` — Should send to Facilitator + Attendees
- [ ] `certificate.issued` — Should send to Student

**Status:** All subscriptions are empty stubs (no business logic).

---

## 7. Background Workers

### Notification pending processor
- [x] **Wired:** Present in cmd/worker/main.go:63–76
- [x] **Interval:** 30 seconds (notificationInterval)
- [x] **Batch size:** 50 (notificationBatchSize)
- [x] **Service method:** platformSvc.ProcessPending()
- ✗ **Implementation gap:** ProcessPending only marks as sent; does NOT:
  - Actually send via Email/In-App/Push channels
  - Implement retry logic (max 3)
  - Update error_message on failure

### Class reminder scanner (1 hour before each class_session start_at)
- [ ] **NOT WIRED** in cmd/worker/main.go
- [ ] **Service method:** Missing (would be ScanClassReminders or similar)
- [ ] **Action:** Should emit `class.reminder` event for Notification domain to pick up

### Scheduled-trigger scanner (wake pending notifications with scheduled_at <= now)
- [ ] **NOT WIRED** in cmd/worker/main.go
- [ ] **Service method:** Missing (would be ScanScheduledNotifications or similar)
- [ ] **Note:** Migration includes scheduled_at field and index; logic not implemented

### Google Calendar sync scanner
- [ ] **NOT WIRED** in cmd/worker/main.go
- [ ] **Service method:** Missing (would be SyncUserCalendars or similar)
- [ ] **Per-user sync:** Required per spec

---

## 8. Database Queries (sqlc)

### Present in platform.sql
- [x] GetTemplateByKeyAndChannel — PRESENT
- [x] CreateNotification — PRESENT
- [x] ListPendingNotifications — PRESENT
- [x] UpdateNotificationStatus — PRESENT
- [x] ListNotificationsByRecipient — PRESENT
- [x] MarkNotificationRead — PRESENT

### Missing queries
- [ ] CreateNotificationTemplate
- [ ] UpdateNotificationTemplate
- [ ] ListNotificationTemplates
- [ ] DeactivateNotificationTemplate
- [ ] GetPreferencesByUser
- [ ] DeletePreference
- [ ] CreateCalendarEvent
- [ ] UpdateCalendarEvent
- [ ] GetCalendarEventByID
- [ ] ListCalendarEventsByDateRange
- [ ] ListCalendarEventsBySourceDomain
- [ ] DeleteCalendarEvent
- [ ] AddCalendarAttendee
- [ ] GetAttendeesByEventID
- [ ] UpdateRSVPStatus
- [ ] RemoveAttendee
- [ ] DeleteAttendeesByEventID
- [ ] UpsertCalendarSync
- [ ] GetCalendarSyncByUser
- [ ] UpdateCalendarSyncTokens
- [ ] UpdateCalendarSyncLastSynced
- [ ] DeleteCalendarSync
- [ ] UpdateNotificationRetryCount (for retry logic)

---

## 9. Migration Schema

### Notification tables (present)
- [x] platform.notification_templates — PRESENT (migration lines 13–25)
- [x] platform.notifications — PRESENT (migration lines 27–48)
- [x] platform.notification_preferences — PRESENT (migration lines 50–61)

### Calendar tables (MISSING)
- [ ] platform.calendar_events — **NOT IN MIGRATION**
- [ ] platform.calendar_attendees — **NOT IN MIGRATION**
- [ ] platform.calendar_sync — **NOT IN MIGRATION**

### Enum types missing from migration
- [ ] platform.calendar_event_type — MISSING
- [ ] platform.calendar_attendee_role — MISSING
- [ ] platform.calendar_rsvp_status — MISSING
- [ ] platform.calendar_sync_provider — MISSING

---

## 10. Module Wiring

### Present (module.go)
- [x] Repository provider — PRESENT (fx.Provide(NewRepository))
- [x] Service provider — PRESENT (fx.Provide(NewService))
- [x] Handler provider — PRESENT (fx.Provide(NewHandler))
- [x] RegisterRoutes — PRESENT (fx.Invoke)
- [x] RegisterSubscriptions — PRESENT (fx.Invoke)

### Missing
- [ ] Event listener implementations for calendar domain events
- [ ] Event listener implementations for notification trigger events
- [ ] Worker wiring (handled in cmd/worker/main.go; no special wiring needed here)

---

## 11. Key Implementation Gaps Summary

### Critical
1. **Calendar entities not modeled:** CalendarEvent, CalendarAttendee, CalendarSync (no types, no repository methods, no database tables)
2. **Calendar database schema missing:** No migration creates calendar tables
3. **Calendar event handlers missing:** No logic to listen to course/team-member domain events
4. **Notification delivery broken:** ProcessPending marks as sent but doesn't actually send (Email/In-App/Push)
5. **Notification retry logic missing:** No max-3 retry implementation

### High Priority
6. **NotificationPreference check missing:** Send() should check preference before creating notification (spec rule 4)
7. **Calendar reminder scanner missing:** No background job to emit `class.reminder` 1 hour before events
8. **Scheduled-trigger scanner missing:** No background job to wake pending notifications with scheduled_at
9. **Calendar sync missing:** No Google OAuth flow, no sync logic, no RefreshToken refresh logic
10. **RSVP status tracking:** Attendee role + RSVP status not implemented

### Medium Priority
11. **Event subscription stubs:** All event subscriptions in events.go are empty (payload not used, no dispatch logic)
12. **Handler routes incomplete:** No CRUD routes for calendar events, attendees, preferences, sync
13. **Missing service methods:** 15+ service methods for calendar CRUD, sync, preference management
14. **Missing repository methods:** 20+ repository methods for calendar and advanced notification queries

### Low Priority
15. **Error message handling:** Notification.ErrorMessage not updated during ProcessPending failures
16. **Bulk operations:** No batch create/update for notifications or preferences
17. **Soft delete:** Calendar entities may need soft delete (vs hard delete for cleanup)

---

## Checklist for Implementation (next tasks)

- [ ] Task 2: Add CalendarEvent, CalendarAttendee, CalendarSync to migration
- [ ] Task 2: Generate sqlc code
- [ ] Task 3: Model types for calendar entities
- [ ] Task 4: Repository CRUD for calendar + advanced notification queries
- [ ] Task 5: Service methods for calendar + sync
- [ ] Task 6: Event handlers (calendar domain listeners)
- [ ] Task 7: Event handlers (notification trigger subscriptions)
- [ ] Task 8: HTTP routes for calendar CRUD + preferences
- [ ] Task 9: Notification delivery logic (Email/In-App/Push)
- [ ] Task 10: Background worker: class reminder scanner
- [ ] Task 11: Background worker: scheduled trigger scanner
- [ ] Task 12: Background worker: calendar sync
- [ ] Task 13: Tests for all domain logic

---

## References

- Calendar spec: docs/domains/calendar/spec.md
- Notification spec: docs/domains/notification/spec.md
- Migration: backend/migrations/000007_init_platform.up.sql
- sqlc queries: backend/sqlc/platform.sql
- Implementation: backend/domains/platform/{model,repository,service,handler,events,module}.go
- Worker: backend/cmd/worker/main.go
