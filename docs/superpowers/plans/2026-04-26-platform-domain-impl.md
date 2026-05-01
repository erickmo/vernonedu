# Platform Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bring `backend/domains/platform` to full alignment with `docs/domains/calendar/spec.md` + `docs/domains/notification/spec.md`.

**Architecture:** Single `platform` package owns CalendarEvent, CalendarAttendee, CalendarSync, NotificationTemplate, Notification, NotificationPreference. Listens to many cross-domain events (see specs). Background workers: pending-notification dispatcher (already wired), scheduled-trigger scanner, class-reminder scanner.

**Tech Stack:** Go 1.22, chi, pgx, sqlc, fx, zap.

---

## Source-of-truth

- `docs/domains/calendar/spec.md`, `docs/domains/notification/spec.md`
- `backend/migrations/000007_init_platform.up.sql`
- `backend/sqlc/platform.sql`

## File Structure

| File | Responsibility |
|---|---|
| `backend/domains/platform/model.go` | EventType, RsvpStatus, NotificationStatus, NotificationChannel enums |
| `backend/domains/platform/repository.go` | CRUD |
| `backend/domains/platform/service.go` | Business rules, template render, dispatch |
| `backend/domains/platform/handler.go` | HTTP routes |
| `backend/domains/platform/events.go` | Cross-domain listeners |
| `backend/domains/platform/template.go` | Mustache/Handlebars-style render (use `text/template` for stdlib-only or pick library) |
| `backend/domains/platform/sender.go` | Channel adapters: EmailSender, InAppSender, PushSender (interfaces + stubs) |
| `backend/domains/platform/module.go` | fx wiring |

---

## Task 1: Audit gaps

- [ ] List entities/methods. Write `GAPS.md`. Commit.

---

## Task 2: NotificationTemplate CRUD

**Files:**
- Modify: `service.go`, `repository.go`, `handler.go`
- Create: `service_template_test.go`

- [ ] **Step 1: Failing tests**

- CreateTemplate (vernonedu_admin only at handler) requires `(key, channel)` unique
- DeactivateTemplate sets is_active=false (not deleted)
- GetActiveTemplate(key, channel) returns nil if missing or inactive (not error — silent skip per spec rule 2/3)

- [ ] **Step 2: Migration if missing**

```sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_template_key_channel
  ON notification_templates (key, channel);
```

- [ ] **Step 3: FAIL**

- [ ] **Step 4: Implement**

- [ ] **Step 5: PASS**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(platform): notification template CRUD"
```

---

## Task 3: Template render

**Files:**
- Create: `backend/domains/platform/template.go`
- Create: `backend/domains/platform/template_test.go`

- [ ] **Step 1: Failing tests**

- Render(`Hi {{.name}}, your code is {{.code}}`, {name: "Alice", code: "X1"}) → "Hi Alice, your code is X1"
- Missing variable required by template → returns ErrMissingVariable
- Unknown helper → error

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** using `text/template`:

```go
package platform

import (
	"bytes"
	"text/template"
)

func Render(body string, vars map[string]any) (string, error) {
	t, err := template.New("n").Option("missingkey=error").Parse(body)
	if err != nil {
		return "", err
	}
	var buf bytes.Buffer
	if err := t.Execute(&buf, vars); err != nil {
		return "", err
	}
	return buf.String(), nil
}
```

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(platform): template render"
```

---

## Task 4: Notification creation with preference + variable validation

**Files:**
- Modify: `service.go`
- Create: `service_create_notification_test.go`

- [ ] **Step 1: Failing tests**

- CreateNotification(key, recipient, vars) → respects NotificationPreference (skip if disabled)
- Absence of preference = enabled by default
- Missing required template variable → ErrMissingVariable, no record created
- Inactive template → silent skip
- Missing template → silent skip
- Push channel without device_token → silent skip
- Successful creation → status=pending, variables JSON stored

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(platform): create notifications with preference checks"
```

---

## Task 5: Pending dispatcher (worker)

**Files:**
- Modify: `service.go` (`ProcessPending` likely exists)
- Create: `service_dispatch_test.go`

- [ ] **Step 1: Failing tests**

- ProcessPending picks up `status=pending` AND `(scheduled_at IS NULL OR scheduled_at <= now())`
- Skips records with `scheduled_at > now()`
- Calls correct sender per channel
- Success → status=sent, sent_at=now()
- Failure → retry_count++; if retry_count<3 stays pending; if =3 → status=failed
- Batch limit honored (notificationBatchSize)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** with sender interface dispatched per channel.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(platform): notification dispatcher with retry"
```

---

## Task 6: Cross-domain listeners

**Files:**
- Modify: `events.go`
- Create: `events_listener_test.go`

Spec lists 14 trigger keys. Implement subscriptions:

| Source Event | Action |
|---|---|
| `enrollment.confirmed` | CreateNotification key=enrollment.confirmed → student |
| `payment.confirmed` | key=payment.confirmed → student |
| `payment.term.due` | key=payment.term.due → student, admin |
| `payment.term.overdue` | key=payment.term.overdue → student, admin |
| `auth.user.created` | key=user.welcome → user |
| `facilitator.proposed` | key=facilitator.proposed → dept_leader |
| `facilitator.approved` | key=facilitator.approved → course_creator, facilitator |
| `facilitator.rejected` | key=facilitator.rejected → course_creator, facilitator |
| `invoice.sent` | key=invoice.sent → billed party |
| `invoice.overdue` | key=invoice.overdue → billed party + admin |
| `team_member.created` | key=team_member.created → member + dept_leader |
| `team_member.status_changed` | key=team_member.status_changed → member + dept_leader |
| `class.reminder` | key=class.reminder → facilitator + attendees |
| `certificate.issued` | key=certificate.issued → student |

- [ ] **Step 1: Failing tests** for at least 3 representative listeners (cover idempotency, recipient resolution, variable assembly).

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement Subscribe block** in events.go iterating registrations.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(platform): cross-domain notification listeners"
```

---

## Task 7: CalendarEvent + Attendee CRUD

**Files:**
- Modify: `service.go`, `repository.go`
- Create: `service_calendar_test.go`

- [ ] **Step 1: Failing tests**

- CreateManualEvent (any internal staff)
- AddAttendee(event, user, role)
- ListEventsByUser returns events where user is attendee or organizer
- DeleteEvent removes attendees in cascade (FK ON DELETE CASCADE)
- AutoCreatedEvent (`source_id != null`) cannot be edited via manual API

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(platform): calendar event CRUD"
```

---

## Task 8: Calendar listeners (course/payment/partnerships)

**Files:**
- Modify: `events.go`
- Create: `events_calendar_test.go`

| Source Event | Action |
|---|---|
| `course.batch.created` | Create class_session events for each Class |
| `course.class.facilitator_assigned` | Add CalendarAttendee to existing class_session |
| `course.class.rescheduled` | Update class_session start/end |
| `course.class.cancelled` | Delete class_session + attendees |
| `payment.term.due` | Create payment_due event (one-time, source_id=term_id) |
| `partnership_agreement.meeting_scheduled` | Create partner_meeting event with agenda |
| `facilitator.approved` | Add facilitator as CalendarAttendee to all class_session events for relevant batch |

- [ ] **Step 1: Failing tests** for at least 3 representative listeners.

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(platform): calendar cross-domain listeners"
```

---

## Task 9: Class reminder scanner (publisher)

**Files:**
- Modify: `service.go`, `cmd/worker/main.go`

- [ ] **Step 1: Failing test**

- ScanClassReminders runs every minute; finds class_session events where `now() ∈ [start_at - 65min, start_at - 60min]` AND no reminder already fired
- Fires `class.reminder` once per event (idempotent: track in `class_reminders_fired` table OR mark a flag on event)

- [ ] **Step 2: Migration**

```sql
ALTER TABLE calendar_events ADD COLUMN IF NOT EXISTS reminder_fired_at TIMESTAMPTZ;
```

- [ ] **Step 3: FAIL**

- [ ] **Step 4: Implement scanner** using `reminder_fired_at IS NULL` predicate; UPDATE SET reminder_fired_at=now() before publishing.

- [ ] **Step 5: PASS**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(platform): class.reminder scanner with idempotency"
```

---

## Task 10: CalendarSync (Google OAuth)

**Files:**
- Modify: `service.go`, `handler.go`
- Create: `service_sync_test.go`

- [ ] **Step 1: Failing tests**

- StartOAuthFlow returns Google OAuth URL with state token
- HandleOAuthCallback exchanges code → access_token + refresh_token, stores encrypted, returns CalendarSync
- RefreshTokenIfExpired uses refresh_token if access_token expired (token_expires_at < now())
- Encryption: tokens stored encrypted at rest (use AES-GCM with key from env)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** using `google.golang.org/api/calendar/v3` (add to go.mod) — keep at-rest encryption stub if library lift too heavy: log "TODO encrypt" but ensure interface boundary in place for future swap.

> Pragmatic note: full Google OAuth is large. Initial step may stub `oauth2.Config` and accept tokens via test fixture. Real client integration goes in a follow-up plan if scope explodes.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(platform): calendar sync skeleton (Google OAuth)"
```

---

## Task 11: iCal export

**Files:**
- Modify: `service.go`, `handler.go`
- Create: `service_ical_test.go`

- [ ] **Step 1: Failing tests**

- ExportICalForUser returns valid iCalendar (RFC 5545) text with all events where user is attendee
- ExportSingleEvent returns single VEVENT
- RRULE field passes through unchanged for recurring events

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** with library `github.com/arran4/golang-ical` (add to go.mod).

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(platform): iCal export"
```

---

## Task 12: Wire HTTP routes

**Files:**
- Modify: `handler.go`, `module.go`

- [ ] **Step 1: Mount routes**

```
# Notification
POST   /notification-templates                  [vernonedu_admin]
PATCH  /notification-templates/{id}             [vernonedu_admin]
GET    /notifications/me                        [authenticated]
POST   /notifications/{id}/read                 [authenticated (own)]
GET    /notification-preferences/me             [authenticated]
PUT    /notification-preferences/me             [authenticated]

# Calendar
POST   /calendar/events                         [authenticated internal staff]
GET    /calendar/events                         [authenticated]
PATCH  /calendar/events/{id}                    [creator, admin]
DELETE /calendar/events/{id}                    [creator, admin]
POST   /calendar/events/{id}/attendees          [admin, dept_leader]
GET    /calendar/export/me.ics                  [authenticated]
GET    /calendar/events/{id}/export.ics         [authenticated attendee]
GET    /calendar/sync/google/authorize          [authenticated]
GET    /calendar/sync/google/callback           [public — OAuth redirect]
```

- [ ] **Step 2: Implement handlers**

- [ ] **Step 3: Smoke test**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(platform): mount HTTP routes"
```

---

## Task 13: Verify + lint

- [ ] `cd backend && go test -race ./domains/platform/...`
- [ ] `cd backend && golangci-lint run ./domains/platform/...`
- [ ] Remove `GAPS.md`. Commit.

---

## Verification

1. Create NotificationTemplate(key=`enrollment.confirmed`, channel=email)
2. Fire `enrollment.confirmed` via test bus → expect Notification record created (status=pending)
3. Run worker → expect status=sent + EmailSender called once
4. Disable preference for that key+channel → fire again → expect no Notification created
5. Create CourseBatch with classes → fire `course.batch.created` → expect calendar class_session events
6. Schedule class 65 min in future → run reminder scanner → expect `class.reminder` fired exactly once
7. iCal export endpoint returns parseable .ics
