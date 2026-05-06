# Design: Calendar Domain — API + Frontend

**Date:** 2026-05-06
**Status:** Approved
**Branch:** feat/sort-api (implementation will branch from here)
**Scope:** Full CRUD calendar domain — Go API + React frontend. No CalendarAttendee. No auto-generation from other domains. Phase 2 covers those.

---

## Overview

Single source of truth for internal scheduled events. Staff can create manual events (staff meetings, admin deadlines, etc.). Auto-generated events (class sessions, payment due dates) are reserved for Phase 2. Frontend shows a full-width monthly grid with color-coded dots per event type; clicking a cell opens a sidebar with that day's events and CRUD actions.

---

## Decisions

| Question | Decision |
|---|---|
| Scope | CRUD manual events only — no CalendarAttendee, no auto-gen listeners |
| Frontend layout | Full-width monthly grid + right sidebar on cell click |
| Visual style | Color-coded dots per event_type (no labels) |
| Authorization | All internal staff — any role except student/partner |
| Auto-generated events | Read-only if present; 403 on edit/delete (Phase 2 only) |

---

## Section 1: API (Backend Go)

### Domain Entity

**File:** `internal/domain/calendar/calendar.go`

```go
type EventType string

const (
    EventTypeClassSession        EventType = "class_session"
    EventTypeStaffMeeting        EventType = "staff_meeting"
    EventTypeAdminDeadline       EventType = "admin_deadline"
    EventTypePaymentDue          EventType = "payment_due"
    EventTypeFacilitatorSchedule EventType = "facilitator_schedule"
    EventTypePartnerMeeting      EventType = "partner_meeting"
)

type CalendarEvent struct {
    ID             uuid.UUID
    Title          string
    Description    *string
    EventType      EventType
    StartAt        time.Time
    EndAt          time.Time
    IsAllDay       bool
    RecurrenceRule *string    // iCal RRULE format, nullable
    Location       *string
    SourceDomain   *string    // nil = manual event
    SourceID       *uuid.UUID // nil = manual event
    CreatedBy      uuid.UUID
    CreatedAt      time.Time
}
```

**Repository interfaces** (same file):
```go
type WriteRepository interface {
    Create(ctx context.Context, e *CalendarEvent) error
    Update(ctx context.Context, e *CalendarEvent) error
    Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
    ListByMonth(ctx context.Context, year, month int) ([]*CalendarEvent, error)
    GetByID(ctx context.Context, id uuid.UUID) (*CalendarEvent, error)
}
```

### Endpoints

```
GET    /api/v1/calendar/events         ?month=5&year=2026
GET    /api/v1/calendar/events/{id}
POST   /api/v1/calendar/events
PUT    /api/v1/calendar/events/{id}
DELETE /api/v1/calendar/events/{id}
```

**GET list:** returns all events where `start_at` falls within the given month (first day 00:00:00 → last day 23:59:59 UTC).

**POST body:**
```json
{
  "title": "string (required)",
  "description": "string (optional)",
  "event_type": "staff_meeting",
  "start_at": "2026-05-07T09:00:00Z",
  "end_at": "2026-05-07T10:00:00Z",
  "is_all_day": false,
  "recurrence_rule": null,
  "location": null
}
```

**PUT:** same body as POST, partial update not supported.

**DELETE:** returns 403 if `source_domain != null` (auto-generated event — read-only).

**PUT:** returns 403 if `source_domain != null`.

### Handler File Structure

```
internal/domain/calendar/calendar.go
internal/query/list_calendar_events/handler.go
internal/query/list_calendar_events/errors.go
internal/query/get_calendar_event/handler.go
internal/query/get_calendar_event/errors.go
internal/command/create_calendar_event/handler.go
internal/command/create_calendar_event/command.go
internal/command/create_calendar_event/errors.go
internal/command/update_calendar_event/handler.go
internal/command/update_calendar_event/command.go
internal/command/update_calendar_event/errors.go
internal/command/delete_calendar_event/handler.go
internal/command/delete_calendar_event/command.go
internal/command/delete_calendar_event/errors.go
internal/delivery/http/calendar_handler.go
infrastructure/database/calendar_repository.go
infrastructure/database/migrations/XXXX_create_calendar_events.sql
```

---

## Section 2: Database Migration

**File:** `infrastructure/database/migrations/XXXX_create_calendar_events.sql`

```sql
CREATE TABLE calendar_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    event_type      VARCHAR(50) NOT NULL,
    start_at        TIMESTAMPTZ NOT NULL,
    end_at          TIMESTAMPTZ NOT NULL,
    is_all_day      BOOLEAN NOT NULL DEFAULT false,
    recurrence_rule VARCHAR(255),
    location        VARCHAR(500),
    source_domain   VARCHAR(50),
    source_id       UUID,
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_calendar_events_start_at ON calendar_events (start_at);
CREATE INDEX idx_calendar_events_source ON calendar_events (source_domain, source_id);
```

---

## Section 3: Frontend (React)

### File Structure

```
web-dashboard/src/
├── services/calendar.service.ts
├── types/calendar.types.ts
└── pages/Calendar/
    ├── CalendarPage.tsx               ← refactor existing (full-width)
    ├── CalendarPage.module.css        ← refactor existing
    ├── CalendarGrid.tsx               ← 7-col grid, receives events[]
    ├── CalendarCell.tsx               ← day number + colored dots
    ├── CalendarSidebar.tsx            ← slide-in: event list for selected day
    ├── EventDot.tsx                   ← colored dot component per event_type
    ├── EventFormModal.tsx             ← create/edit manual event (modal)
    └── __tests__/CalendarPage.test.tsx
```

### Types (`calendar.types.ts`)

```ts
export type EventType =
  | 'class_session'
  | 'staff_meeting'
  | 'admin_deadline'
  | 'payment_due'
  | 'facilitator_schedule'
  | 'partner_meeting'

export interface CalendarEvent {
  id: string
  title: string
  description: string | null
  event_type: EventType
  start_at: string  // ISO datetime
  end_at: string
  is_all_day: boolean
  recurrence_rule: string | null
  location: string | null
  source_domain: string | null
  source_id: string | null
  created_by: string
  created_at: string
}
```

### Event Type Color Map

```ts
export const EVENT_TYPE_COLORS: Record<EventType, string> = {
  class_session:        '#3b82f6',  // blue
  staff_meeting:        '#22c55e',  // green
  admin_deadline:       '#f97316',  // orange
  payment_due:          '#ef4444',  // red
  facilitator_schedule: '#a855f7',  // purple
  partner_meeting:      '#14b8a6',  // teal
}
```

### Data Flow

```
CalendarPage
  → useState(selectedDate: Date | null)
  → useQuery: calendarService.listByMonth(month, year)
  → CalendarGrid(events[], onCellClick)
    → groups events by day (Map<number, CalendarEvent[]>)
    → CalendarCell(day, events[], isToday, isSelected, onClick)
      → EventDot per event (colored dot, title as tooltip)
  → CalendarSidebar(selectedDate, events for that day)
    → list of events with title, time, type badge
    → Edit button → EventFormModal(event) [only if source_domain === null]
    → Delete button [only if source_domain === null]
  → "+ Event" button → EventFormModal(null) [create mode]
```

### Layout

Full-width grid (no max-width cap). Sidebar fixed-width (320px) slides in from right when a day is selected. Calendar grid shrinks to fill remaining space (flex layout).

```
┌─ CalendarPage (flex row) ──────────────────────────────────┐
│ ┌─ CalendarGrid (flex: 1) ──────────┐ ┌─ Sidebar (320px) ─┐│
│ │  ← Mei 2026 →       [+ Event]    │ │ Rabu, 7 Mei        ││
│ │  Min Sen Sel Rab Kam Jum Sab      │ │                    ││
│ │   .   .   .   1   2   3   4      │ │ ● Kelas Python     ││
│ │   .   .   .   ●   .  ●●   .      │ │   09:00 – 11:00    ││
│ │   5   6   7   8   9  10  11      │ │                    ││
│ └───────────────────────────────────┘ └────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

## Section 4: Authorization

- All endpoints under `/api/v1/calendar/` require `RequireInternalStaff` middleware (existing middleware — blocks student/partner roles).
- No role-based scoping beyond that.
- Edit/delete of auto-generated events (source_domain != null) returns HTTP 403 with `{"error": "auto-generated events are read-only"}`.

---

## Section 5: FX Wiring (Go DI)

Follow existing pattern:
1. Add `calendar_repository.go` → provide `calendar.ReadRepository` + `calendar.WriteRepository`
2. Add query/command handlers to respective FX modules
3. Add `CalendarHandler` to `delivery/http` FX module
4. Wire route in router: `r.Route("/calendar", calendarHandler.Routes)`

---

## Out of Scope (Phase 2)

- CalendarAttendee (join table event ↔ user, RSVP)
- Auto-generation from `course.batch.created`, `payment.term.due`, `partner_meeting.scheduled` events
- Google Calendar sync (CalendarSync entity + OAuth)
- iCal export
- Recurring event expansion (RRULE rendering on frontend)
- `class.reminder` notification (1 hour before class_session)

---

## File Count

| Layer | Files |
|---|---|
| Go API (domain + handlers + repo) | 17 |
| SQL migration | 1 |
| React frontend | 8 |
| **Total** | **26** |
