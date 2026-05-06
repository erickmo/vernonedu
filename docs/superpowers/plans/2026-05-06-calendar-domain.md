# Calendar Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a full CRUD calendar domain — Go REST API + React frontend — so internal staff can create and view scheduled events on a monthly calendar grid.

**Architecture:** Clean Architecture + CQRS. New `calendar` domain package with entity, repo interfaces, query/command handlers, HTTP handler, and PostgreSQL repository. Frontend is a full-width monthly grid with color-coded event dots and a slide-in sidebar.

**Tech Stack:** Go (Chi v5, sqlx, Uber FX, zerolog), PostgreSQL, React 18 + TypeScript + CSS Modules + TanStack Query

---

## File Map

### API (Go)
| File | Action | Responsibility |
|---|---|---|
| `api/migrations/077_create_calendar_events.sql` | Create | DB table + indexes |
| `api/internal/domain/calendar/calendar.go` | Create | Entity, EventType consts, repo interfaces |
| `api/infrastructure/database/calendar_repository.go` | Create | PostgreSQL impl of both repo interfaces |
| `api/internal/query/list_calendar_events/handler.go` | Create | List events by month/year |
| `api/internal/query/list_calendar_events/errors.go` | Create | Query error var |
| `api/internal/query/get_calendar_event/handler.go` | Create | Get single event by ID |
| `api/internal/query/get_calendar_event/errors.go` | Create | Query error var |
| `api/internal/command/create_calendar_event/command.go` | Create | CreateCalendarEventCommand struct |
| `api/internal/command/create_calendar_event/handler.go` | Create | Command handler |
| `api/internal/command/create_calendar_event/errors.go` | Create | Error var |
| `api/internal/command/update_calendar_event/command.go` | Create | UpdateCalendarEventCommand struct |
| `api/internal/command/update_calendar_event/handler.go` | Create | Command handler |
| `api/internal/command/update_calendar_event/errors.go` | Create | Error var |
| `api/internal/command/delete_calendar_event/command.go` | Create | DeleteCalendarEventCommand struct |
| `api/internal/command/delete_calendar_event/handler.go` | Create | Command handler |
| `api/internal/command/delete_calendar_event/errors.go` | Create | Error var |
| `api/internal/delivery/http/calendar_handler.go` | Create | HTTP handler + route registration |
| `api/cmd/api/main.go` | Modify | FX wiring: provide repo, handler, register cmds/queries, register routes |

### Frontend (React)
| File | Action | Responsibility |
|---|---|---|
| `web-dashboard/src/types/calendar.types.ts` | Create | CalendarEvent interface, EventType, color map |
| `web-dashboard/src/services/calendar.service.ts` | Create | API calls: listByMonth, getById, create, update, delete |
| `web-dashboard/src/pages/Calendar/CalendarPage.tsx` | Modify | Refactor to full-width layout, wire data + state |
| `web-dashboard/src/pages/Calendar/CalendarPage.module.css` | Modify | Full-width layout, sidebar, flex |
| `web-dashboard/src/pages/Calendar/CalendarGrid.tsx` | Create | 7-col grid, groups events by day |
| `web-dashboard/src/pages/Calendar/CalendarCell.tsx` | Create | Day cell with dots |
| `web-dashboard/src/pages/Calendar/EventDot.tsx` | Create | Colored dot per event_type |
| `web-dashboard/src/pages/Calendar/CalendarSidebar.tsx` | Create | Slide-in event list for selected day |
| `web-dashboard/src/pages/Calendar/EventFormModal.tsx` | Create | Create/edit form modal |
| `web-dashboard/src/pages/Calendar/__tests__/CalendarPage.test.tsx` | Create | Unit tests for CalendarGrid, CalendarCell, EventDot |

---

## Task 1: DB Migration

**Files:**
- Create: `api/migrations/077_create_calendar_events.sql`

- [ ] **Step 1: Create migration file**

```sql
CREATE TABLE IF NOT EXISTS calendar_events (
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
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_start_at ON calendar_events (start_at);
CREATE INDEX IF NOT EXISTS idx_calendar_events_source ON calendar_events (source_domain, source_id);
```

- [ ] **Step 2: Run migration**

```bash
cd api && make migrate-up
```

Expected: `OK    077_create_calendar_events.sql` in output. No errors.

- [ ] **Step 3: Verify table exists**

```bash
cd api && make infra-up  # if not already running
psql $DATABASE_URL -c "\d calendar_events"
```

Expected: table with columns id, title, description, event_type, start_at, end_at, is_all_day, recurrence_rule, location, source_domain, source_id, created_by, created_at.

- [ ] **Step 4: Commit**

```bash
git add api/migrations/077_create_calendar_events.sql
git commit -m "feat(calendar): add calendar_events table migration"
```

---

## Task 2: Domain Entity

**Files:**
- Create: `api/internal/domain/calendar/calendar.go`

- [ ] **Step 1: Create domain entity file**

```go
package calendar

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrCalendarEventNotFound      = errors.New("calendar event not found")
	ErrAutoGeneratedEventReadOnly = errors.New("auto-generated events are read-only")
)

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
	RecurrenceRule *string
	Location       *string
	SourceDomain   *string
	SourceID       *uuid.UUID
	CreatedBy      uuid.UUID
	CreatedAt      time.Time
}

func (e *CalendarEvent) IsManual() bool {
	return e.SourceDomain == nil
}

type WriteRepository interface {
	Save(ctx context.Context, e *CalendarEvent) error
	Update(ctx context.Context, e *CalendarEvent) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	ListByMonth(ctx context.Context, year, month int) ([]*CalendarEvent, error)
	GetByID(ctx context.Context, id uuid.UUID) (*CalendarEvent, error)
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd api && go build ./internal/domain/calendar/...
```

Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git add api/internal/domain/calendar/calendar.go
git commit -m "feat(calendar): add CalendarEvent domain entity and repo interfaces"
```

---

## Task 3: Repository

**Files:**
- Create: `api/infrastructure/database/calendar_repository.go`

- [ ] **Step 1: Create repository**

```go
package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/calendar"
)

type CalendarRepository struct {
	db *sqlx.DB
}

func NewCalendarRepository(db *sqlx.DB) *CalendarRepository {
	return &CalendarRepository{db: db}
}

type calendarEventRecord struct {
	ID             uuid.UUID  `db:"id"`
	Title          string     `db:"title"`
	Description    *string    `db:"description"`
	EventType      string     `db:"event_type"`
	StartAt        time.Time  `db:"start_at"`
	EndAt          time.Time  `db:"end_at"`
	IsAllDay       bool       `db:"is_all_day"`
	RecurrenceRule *string    `db:"recurrence_rule"`
	Location       *string    `db:"location"`
	SourceDomain   *string    `db:"source_domain"`
	SourceID       *uuid.UUID `db:"source_id"`
	CreatedBy      uuid.UUID  `db:"created_by"`
	CreatedAt      time.Time  `db:"created_at"`
}

func (rec *calendarEventRecord) toDomain() *calendar.CalendarEvent {
	return &calendar.CalendarEvent{
		ID:             rec.ID,
		Title:          rec.Title,
		Description:    rec.Description,
		EventType:      calendar.EventType(rec.EventType),
		StartAt:        rec.StartAt,
		EndAt:          rec.EndAt,
		IsAllDay:       rec.IsAllDay,
		RecurrenceRule: rec.RecurrenceRule,
		Location:       rec.Location,
		SourceDomain:   rec.SourceDomain,
		SourceID:       rec.SourceID,
		CreatedBy:      rec.CreatedBy,
		CreatedAt:      rec.CreatedAt,
	}
}

const calendarCols = `id, title, description, event_type, start_at, end_at, is_all_day, recurrence_rule, location, source_domain, source_id, created_by, created_at`

func (r *CalendarRepository) Save(ctx context.Context, e *calendar.CalendarEvent) error {
	query := `
		INSERT INTO calendar_events (id, title, description, event_type, start_at, end_at,
		    is_all_day, recurrence_rule, location, source_domain, source_id, created_by, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
	`
	_, err := r.db.ExecContext(ctx, query,
		e.ID, e.Title, e.Description, string(e.EventType), e.StartAt, e.EndAt,
		e.IsAllDay, e.RecurrenceRule, e.Location, e.SourceDomain, e.SourceID,
		e.CreatedBy, e.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save calendar event: %w", err)
	}
	return nil
}

func (r *CalendarRepository) Update(ctx context.Context, e *calendar.CalendarEvent) error {
	query := `
		UPDATE calendar_events
		SET title=$1, description=$2, event_type=$3, start_at=$4, end_at=$5,
		    is_all_day=$6, recurrence_rule=$7, location=$8
		WHERE id=$9
	`
	_, err := r.db.ExecContext(ctx, query,
		e.Title, e.Description, string(e.EventType), e.StartAt, e.EndAt,
		e.IsAllDay, e.RecurrenceRule, e.Location, e.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update calendar event: %w", err)
	}
	return nil
}

func (r *CalendarRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM calendar_events WHERE id=$1`, id)
	if err != nil {
		return fmt.Errorf("failed to delete calendar event: %w", err)
	}
	return nil
}

func (r *CalendarRepository) ListByMonth(ctx context.Context, year, month int) ([]*calendar.CalendarEvent, error) {
	firstDay := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.UTC)
	lastDay := firstDay.AddDate(0, 1, 0).Add(-time.Nanosecond)

	var recs []calendarEventRecord
	query := `SELECT ` + calendarCols + ` FROM calendar_events WHERE start_at BETWEEN $1 AND $2 ORDER BY start_at ASC`
	if err := r.db.SelectContext(ctx, &recs, query, firstDay, lastDay); err != nil {
		return nil, fmt.Errorf("failed to list calendar events: %w", err)
	}

	events := make([]*calendar.CalendarEvent, len(recs))
	for i, rec := range recs {
		events[i] = rec.toDomain()
	}
	return events, nil
}

func (r *CalendarRepository) GetByID(ctx context.Context, id uuid.UUID) (*calendar.CalendarEvent, error) {
	var rec calendarEventRecord
	query := `SELECT ` + calendarCols + ` FROM calendar_events WHERE id=$1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get calendar event: %w", err)
	}
	return rec.toDomain(), nil
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd api && go build ./infrastructure/database/...
```

Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git add api/infrastructure/database/calendar_repository.go
git commit -m "feat(calendar): add CalendarRepository with PostgreSQL implementation"
```

---

## Task 4: Query — List Calendar Events

**Files:**
- Create: `api/internal/query/list_calendar_events/handler.go`
- Create: `api/internal/query/list_calendar_events/errors.go`

- [ ] **Step 1: Create errors.go**

```go
package list_calendar_events

import "errors"

var ErrInvalidQuery = errors.New("invalid list calendar events query")
```

- [ ] **Step 2: Create handler.go**

```go
package list_calendar_events

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/calendar"
)

type ListCalendarEventsQuery struct {
	Year  int
	Month int
}

type CalendarEventReadModel struct {
	ID             string  `json:"id"`
	Title          string  `json:"title"`
	Description    *string `json:"description"`
	EventType      string  `json:"event_type"`
	StartAt        string  `json:"start_at"`
	EndAt          string  `json:"end_at"`
	IsAllDay       bool    `json:"is_all_day"`
	RecurrenceRule *string `json:"recurrence_rule"`
	Location       *string `json:"location"`
	SourceDomain   *string `json:"source_domain"`
	SourceID       *string `json:"source_id"`
	CreatedBy      string  `json:"created_by"`
	CreatedAt      string  `json:"created_at"`
}

type ListCalendarEventsResult struct {
	Data []* CalendarEventReadModel `json:"data"`
}

type Handler struct {
	readRepo calendar.ReadRepository
}

func NewHandler(readRepo calendar.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func toReadModel(e *calendar.CalendarEvent) *CalendarEventReadModel {
	rm := &CalendarEventReadModel{
		ID:             e.ID.String(),
		Title:          e.Title,
		Description:    e.Description,
		EventType:      string(e.EventType),
		StartAt:        e.StartAt.Format(time.RFC3339),
		EndAt:          e.EndAt.Format(time.RFC3339),
		IsAllDay:       e.IsAllDay,
		RecurrenceRule: e.RecurrenceRule,
		Location:       e.Location,
		SourceDomain:   e.SourceDomain,
		CreatedBy:      e.CreatedBy.String(),
		CreatedAt:      e.CreatedAt.Format(time.RFC3339),
	}
	if e.SourceID != nil {
		s := e.SourceID.String()
		rm.SourceID = &s
	}
	return rm
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCalendarEventsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	year, month := q.Year, q.Month
	if year == 0 {
		year = time.Now().Year()
	}
	if month == 0 {
		month = int(time.Now().Month())
	}

	events, err := h.readRepo.ListByMonth(ctx, year, month)
	if err != nil {
		log.Error().Err(err).Int("year", year).Int("month", month).Msg("failed to list calendar events")
		return nil, err
	}

	models := make([]*CalendarEventReadModel, len(events))
	for i, e := range events {
		models[i] = toReadModel(e)
	}
	return &ListCalendarEventsResult{Data: models}, nil
}

// shared helper used by get_calendar_event
func ToReadModel(e *calendar.CalendarEvent) *CalendarEventReadModel {
	return toReadModel(e)
}

// re-export uuid for use in get handler
var _ = uuid.Nil
```

- [ ] **Step 3: Verify it compiles**

```bash
cd api && go build ./internal/query/list_calendar_events/...
```

Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add api/internal/query/list_calendar_events/
git commit -m "feat(calendar): add list_calendar_events query handler"
```

---

## Task 5: Query — Get Calendar Event

**Files:**
- Create: `api/internal/query/get_calendar_event/handler.go`
- Create: `api/internal/query/get_calendar_event/errors.go`

- [ ] **Step 1: Create errors.go**

```go
package get_calendar_event

import "errors"

var ErrInvalidQuery = errors.New("invalid get calendar event query")
```

- [ ] **Step 2: Create handler.go**

```go
package get_calendar_event

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/calendar"
)

type GetCalendarEventQuery struct {
	ID uuid.UUID
}

type CalendarEventReadModel struct {
	ID             string  `json:"id"`
	Title          string  `json:"title"`
	Description    *string `json:"description"`
	EventType      string  `json:"event_type"`
	StartAt        string  `json:"start_at"`
	EndAt          string  `json:"end_at"`
	IsAllDay       bool    `json:"is_all_day"`
	RecurrenceRule *string `json:"recurrence_rule"`
	Location       *string `json:"location"`
	SourceDomain   *string `json:"source_domain"`
	SourceID       *string `json:"source_id"`
	CreatedBy      string  `json:"created_by"`
	CreatedAt      string  `json:"created_at"`
}

type Handler struct {
	readRepo calendar.ReadRepository
}

func NewHandler(readRepo calendar.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCalendarEventQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	e, err := h.readRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("id", q.ID.String()).Msg("failed to get calendar event")
		return nil, err
	}

	rm := &CalendarEventReadModel{
		ID:             e.ID.String(),
		Title:          e.Title,
		Description:    e.Description,
		EventType:      string(e.EventType),
		StartAt:        e.StartAt.Format(time.RFC3339),
		EndAt:          e.EndAt.Format(time.RFC3339),
		IsAllDay:       e.IsAllDay,
		RecurrenceRule: e.RecurrenceRule,
		Location:       e.Location,
		SourceDomain:   e.SourceDomain,
		CreatedBy:      e.CreatedBy.String(),
		CreatedAt:      e.CreatedAt.Format(time.RFC3339),
	}
	if e.SourceID != nil {
		s := e.SourceID.String()
		rm.SourceID = &s
	}
	return rm, nil
}
```

- [ ] **Step 3: Verify it compiles**

```bash
cd api && go build ./internal/query/get_calendar_event/...
```

Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add api/internal/query/get_calendar_event/
git commit -m "feat(calendar): add get_calendar_event query handler"
```

---

## Task 6: Command — Create Calendar Event

**Files:**
- Create: `api/internal/command/create_calendar_event/command.go`
- Create: `api/internal/command/create_calendar_event/handler.go`
- Create: `api/internal/command/create_calendar_event/errors.go`

- [ ] **Step 1: Create errors.go**

```go
package create_calendar_event

import "errors"

var ErrInvalidCommand = errors.New("invalid create calendar event command")
```

- [ ] **Step 2: Create command.go**

```go
package create_calendar_event

type CreateCalendarEventCommand struct {
	Title          string `validate:"required,min=1,max=255"`
	Description    string
	EventType      string `validate:"required,oneof=class_session staff_meeting admin_deadline payment_due facilitator_schedule partner_meeting"`
	StartAt        string `validate:"required"`
	EndAt          string `validate:"required"`
	IsAllDay       bool
	RecurrenceRule string
	Location       string
	CreatedBy      string `validate:"required"`
}
```

- [ ] **Step 3: Create handler.go**

```go
package create_calendar_event

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/calendar"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo calendar.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo calendar.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateCalendarEventCommand)
	if !ok {
		return ErrInvalidCommand
	}

	startAt, err := time.Parse(time.RFC3339, c.StartAt)
	if err != nil {
		return err
	}
	endAt, err := time.Parse(time.RFC3339, c.EndAt)
	if err != nil {
		return err
	}
	createdBy, err := uuid.Parse(c.CreatedBy)
	if err != nil {
		return err
	}

	e := &calendar.CalendarEvent{
		ID:        uuid.New(),
		Title:     c.Title,
		EventType: calendar.EventType(c.EventType),
		StartAt:   startAt,
		EndAt:     endAt,
		IsAllDay:  c.IsAllDay,
		CreatedBy: createdBy,
		CreatedAt: time.Now(),
	}
	if c.Description != "" {
		e.Description = &c.Description
	}
	if c.RecurrenceRule != "" {
		e.RecurrenceRule = &c.RecurrenceRule
	}
	if c.Location != "" {
		e.Location = &c.Location
	}

	if err := h.writeRepo.Save(ctx, e); err != nil {
		log.Error().Err(err).Msg("failed to create calendar event")
		return err
	}
	return nil
}
```

- [ ] **Step 4: Verify it compiles**

```bash
cd api && go build ./internal/command/create_calendar_event/...
```

Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add api/internal/command/create_calendar_event/
git commit -m "feat(calendar): add create_calendar_event command handler"
```

---

## Task 7: Command — Update Calendar Event

**Files:**
- Create: `api/internal/command/update_calendar_event/command.go`
- Create: `api/internal/command/update_calendar_event/handler.go`
- Create: `api/internal/command/update_calendar_event/errors.go`

- [ ] **Step 1: Create errors.go**

```go
package update_calendar_event

import "errors"

var ErrInvalidCommand = errors.New("invalid update calendar event command")
```

- [ ] **Step 2: Create command.go**

```go
package update_calendar_event

type UpdateCalendarEventCommand struct {
	ID             string `validate:"required"`
	Title          string `validate:"required,min=1,max=255"`
	Description    string
	EventType      string `validate:"required,oneof=class_session staff_meeting admin_deadline payment_due facilitator_schedule partner_meeting"`
	StartAt        string `validate:"required"`
	EndAt          string `validate:"required"`
	IsAllDay       bool
	RecurrenceRule string
	Location       string
}
```

- [ ] **Step 3: Create handler.go**

```go
package update_calendar_event

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/calendar"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	readRepo  calendar.ReadRepository
	writeRepo calendar.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(readRepo calendar.ReadRepository, writeRepo calendar.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{readRepo: readRepo, writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateCalendarEventCommand)
	if !ok {
		return ErrInvalidCommand
	}

	id, err := uuid.Parse(c.ID)
	if err != nil {
		return err
	}

	e, err := h.readRepo.GetByID(ctx, id)
	if err != nil {
		return calendar.ErrCalendarEventNotFound
	}

	if !e.IsManual() {
		return calendar.ErrAutoGeneratedEventReadOnly
	}

	startAt, err := time.Parse(time.RFC3339, c.StartAt)
	if err != nil {
		return err
	}
	endAt, err := time.Parse(time.RFC3339, c.EndAt)
	if err != nil {
		return err
	}

	e.Title = c.Title
	e.EventType = calendar.EventType(c.EventType)
	e.StartAt = startAt
	e.EndAt = endAt
	e.IsAllDay = c.IsAllDay

	if c.Description != "" {
		e.Description = &c.Description
	} else {
		e.Description = nil
	}
	if c.RecurrenceRule != "" {
		e.RecurrenceRule = &c.RecurrenceRule
	} else {
		e.RecurrenceRule = nil
	}
	if c.Location != "" {
		e.Location = &c.Location
	} else {
		e.Location = nil
	}

	if err := h.writeRepo.Update(ctx, e); err != nil {
		log.Error().Err(err).Str("id", c.ID).Msg("failed to update calendar event")
		return err
	}
	return nil
}
```

- [ ] **Step 4: Verify it compiles**

```bash
cd api && go build ./internal/command/update_calendar_event/...
```

Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add api/internal/command/update_calendar_event/
git commit -m "feat(calendar): add update_calendar_event command handler"
```

---

## Task 8: Command — Delete Calendar Event

**Files:**
- Create: `api/internal/command/delete_calendar_event/command.go`
- Create: `api/internal/command/delete_calendar_event/handler.go`
- Create: `api/internal/command/delete_calendar_event/errors.go`

- [ ] **Step 1: Create errors.go**

```go
package delete_calendar_event

import "errors"

var ErrInvalidCommand = errors.New("invalid delete calendar event command")
```

- [ ] **Step 2: Create command.go**

```go
package delete_calendar_event

import "github.com/google/uuid"

type DeleteCalendarEventCommand struct {
	ID uuid.UUID `validate:"required"`
}
```

- [ ] **Step 3: Create handler.go**

```go
package delete_calendar_event

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/calendar"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	readRepo  calendar.ReadRepository
	writeRepo calendar.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(readRepo calendar.ReadRepository, writeRepo calendar.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{readRepo: readRepo, writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteCalendarEventCommand)
	if !ok {
		return ErrInvalidCommand
	}

	e, err := h.readRepo.GetByID(ctx, c.ID)
	if err != nil {
		return calendar.ErrCalendarEventNotFound
	}

	if !e.IsManual() {
		return calendar.ErrAutoGeneratedEventReadOnly
	}

	if err := h.writeRepo.Delete(ctx, c.ID); err != nil {
		log.Error().Err(err).Str("id", c.ID.String()).Msg("failed to delete calendar event")
		return err
	}
	return nil
}
```

- [ ] **Step 4: Verify it compiles**

```bash
cd api && go build ./internal/command/delete_calendar_event/...
```

Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add api/internal/command/delete_calendar_event/
git commit -m "feat(calendar): add delete_calendar_event command handler"
```

---

## Task 9: HTTP Handler

**Files:**
- Create: `api/internal/delivery/http/calendar_handler.go`

- [ ] **Step 1: Create handler**

```go
package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	createcalendarevent "github.com/vernonedu/entrepreneurship-api/internal/command/create_calendar_event"
	deletecalendarevent "github.com/vernonedu/entrepreneurship-api/internal/command/delete_calendar_event"
	updatecalendarevent "github.com/vernonedu/entrepreneurship-api/internal/command/update_calendar_event"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/calendar"
	getcalendarevent "github.com/vernonedu/entrepreneurship-api/internal/query/get_calendar_event"
	listcalendarevents "github.com/vernonedu/entrepreneurship-api/internal/query/list_calendar_events"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/jwtutil"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type CalendarHandler struct {
	cmdBus  commandbus.CommandBus
	qryBus  querybus.QueryBus
	jwtUtil *jwtutil.JWTUtil
}

func NewCalendarHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus, jwtUtil *jwtutil.JWTUtil) *CalendarHandler {
	return &CalendarHandler{cmdBus: cmdBus, qryBus: qryBus, jwtUtil: jwtUtil}
}

func RegisterCalendarRoutes(h *CalendarHandler, r chi.Router) {
	r.Get("/api/v1/calendar/events", h.ListEvents)
	r.Post("/api/v1/calendar/events", h.CreateEvent)
	r.Get("/api/v1/calendar/events/{id}", h.GetEvent)
	r.Put("/api/v1/calendar/events/{id}", h.UpdateEvent)
	r.Delete("/api/v1/calendar/events/{id}", h.DeleteEvent)
}

// ListEvents godoc
// @Summary      List calendar events
// @Description  Returns all calendar events in the given month/year.
// @Tags         calendar
// @Produce      json
// @Param        month  query  int  false  "Month (1-12, defaults to current)"
// @Param        year   query  int  false  "Year (defaults to current)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /calendar/events [get]
func (h *CalendarHandler) ListEvents(w http.ResponseWriter, r *http.Request) {
	month, _ := strconv.Atoi(r.URL.Query().Get("month"))
	year, _ := strconv.Atoi(r.URL.Query().Get("year"))
	if year == 0 {
		year = time.Now().Year()
	}
	if month == 0 {
		month = int(time.Now().Month())
	}

	result, err := h.qryBus.Execute(r.Context(), &listcalendarevents.ListCalendarEventsQuery{
		Year: year, Month: month,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list calendar events")
		writeError(w, http.StatusInternalServerError, "failed to list calendar events")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// GetEvent godoc
// @Summary      Get calendar event
// @Description  Returns a single calendar event by ID.
// @Tags         calendar
// @Produce      json
// @Param        id  path  string  true  "Event ID"
// @Success      200  {object}  map[string]interface{}
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /calendar/events/{id} [get]
func (h *CalendarHandler) GetEvent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid event id")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &getcalendarevent.GetCalendarEventQuery{ID: id})
	if err != nil {
		if errors.Is(err, calendar.ErrCalendarEventNotFound) {
			writeError(w, http.StatusNotFound, "event not found")
			return
		}
		log.Error().Err(err).Msg("failed to get calendar event")
		writeError(w, http.StatusInternalServerError, "failed to get calendar event")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// CreateEvent godoc
// @Summary      Create calendar event
// @Description  Creates a new manual calendar event.
// @Tags         calendar
// @Accept       json
// @Produce      json
// @Param        body  body  object  true  "Event data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Security     BearerAuth
// @Router       /calendar/events [post]
func (h *CalendarHandler) CreateEvent(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Title          string `json:"title"`
		Description    string `json:"description"`
		EventType      string `json:"event_type"`
		StartAt        string `json:"start_at"`
		EndAt          string `json:"end_at"`
		IsAllDay       bool   `json:"is_all_day"`
		RecurrenceRule string `json:"recurrence_rule"`
		Location       string `json:"location"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	claims, err := h.jwtUtil.ExtractClaims(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	cmd := &createcalendarevent.CreateCalendarEventCommand{
		Title:          body.Title,
		Description:    body.Description,
		EventType:      body.EventType,
		StartAt:        body.StartAt,
		EndAt:          body.EndAt,
		IsAllDay:       body.IsAllDay,
		RecurrenceRule: body.RecurrenceRule,
		Location:       body.Location,
		CreatedBy:      claims.UserID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create calendar event")
		writeError(w, http.StatusInternalServerError, "failed to create calendar event")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "calendar event created"})
}

// UpdateEvent godoc
// @Summary      Update calendar event
// @Description  Updates a manual calendar event. Returns 403 for auto-generated events.
// @Tags         calendar
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Event ID"
// @Param        body  body  object  true  "Event data"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /calendar/events/{id} [put]
func (h *CalendarHandler) UpdateEvent(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")

	var body struct {
		Title          string `json:"title"`
		Description    string `json:"description"`
		EventType      string `json:"event_type"`
		StartAt        string `json:"start_at"`
		EndAt          string `json:"end_at"`
		IsAllDay       bool   `json:"is_all_day"`
		RecurrenceRule string `json:"recurrence_rule"`
		Location       string `json:"location"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatecalendarevent.UpdateCalendarEventCommand{
		ID:             idStr,
		Title:          body.Title,
		Description:    body.Description,
		EventType:      body.EventType,
		StartAt:        body.StartAt,
		EndAt:          body.EndAt,
		IsAllDay:       body.IsAllDay,
		RecurrenceRule: body.RecurrenceRule,
		Location:       body.Location,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, calendar.ErrCalendarEventNotFound) {
			writeError(w, http.StatusNotFound, "event not found")
			return
		}
		if errors.Is(err, calendar.ErrAutoGeneratedEventReadOnly) {
			writeError(w, http.StatusForbidden, "auto-generated events are read-only")
			return
		}
		log.Error().Err(err).Msg("failed to update calendar event")
		writeError(w, http.StatusInternalServerError, "failed to update calendar event")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "calendar event updated"})
}

// DeleteEvent godoc
// @Summary      Delete calendar event
// @Description  Deletes a manual calendar event. Returns 403 for auto-generated events.
// @Tags         calendar
// @Produce      json
// @Param        id  path  string  true  "Event ID"
// @Success      200  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /calendar/events/{id} [delete]
func (h *CalendarHandler) DeleteEvent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid event id")
		return
	}

	cmd := &deletecalendarevent.DeleteCalendarEventCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, calendar.ErrCalendarEventNotFound) {
			writeError(w, http.StatusNotFound, "event not found")
			return
		}
		if errors.Is(err, calendar.ErrAutoGeneratedEventReadOnly) {
			writeError(w, http.StatusForbidden, "auto-generated events are read-only")
			return
		}
		log.Error().Err(err).Msg("failed to delete calendar event")
		writeError(w, http.StatusInternalServerError, "failed to delete calendar event")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "calendar event deleted"})
}
```

- [ ] **Step 2: Check how jwtUtil.ExtractClaims is used in existing handlers**

```bash
grep -n "ExtractClaims\|claims\." /Users/erickmo/Desktop/Project/vernonedu2/api/internal/delivery/http/enrollment_handler.go | head -10
```

If `ExtractClaims` signature differs, adapt the `CreateEvent` method to match. Common pattern: `claims := r.Context().Value(pkgmiddleware.ClaimsKey).(*jwtutil.Claims)`.

- [ ] **Step 3: Verify it compiles**

```bash
cd api && go build ./internal/delivery/http/...
```

Expected: exit 0. Fix any import/method errors before proceeding.

- [ ] **Step 4: Commit**

```bash
git add api/internal/delivery/http/calendar_handler.go
git commit -m "feat(calendar): add CalendarHandler with CRUD endpoints"
```

---

## Task 10: FX Wiring in main.go

**Files:**
- Modify: `api/cmd/api/main.go`

- [ ] **Step 1: Add imports** (in the imports block, alongside other command/query imports)

```go
// Calendar imports
createcalendarevent "github.com/vernonedu/entrepreneurship-api/internal/command/create_calendar_event"
deletecalendarevent "github.com/vernonedu/entrepreneurship-api/internal/command/delete_calendar_event"
updatecalendarevent "github.com/vernonedu/entrepreneurship-api/internal/command/update_calendar_event"
getcalendarevent    "github.com/vernonedu/entrepreneurship-api/internal/query/get_calendar_event"
listcalendarevents  "github.com/vernonedu/entrepreneurship-api/internal/query/list_calendar_events"
```

- [ ] **Step 2: Add CalendarRepository to fx.Provide block** (after HrmRepo, around line 535)

```go
// Calendar repository
func(db *sqlx.DB) *database.CalendarRepository {
    return database.NewCalendarRepository(db)
},
```

- [ ] **Step 3: Add newCalendarHTTPHandler function** (after the other `new*HTTPHandler` functions, around line 815)

```go
func newCalendarHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus, jwtUtil *jwtutil.JWTUtil) *httphandler.CalendarHandler {
	return httphandler.NewCalendarHandler(cmdBus, qryBus, jwtUtil)
}
```

Also add `newCalendarHTTPHandler` to the `fx.Provide(...)` call.

- [ ] **Step 4: Add CalendarRepo to registerParams struct** (after HrmRepo)

```go
CalendarRepo *database.CalendarRepository
```

- [ ] **Step 5: Add CalendarHandler to newRouter params and route registration**

In `newRouter` function signature, add:
```go
calendarHandler *httphandler.CalendarHandler,
```

In `newRouter` body, inside the protected `r.Group` block, add:
```go
// Calendar routes
httphandler.RegisterCalendarRoutes(calendarHandler, r)
```

- [ ] **Step 6: Register commands and queries in registerHandlers**

Add after the HRM section:

```go
// Calendar
if err := p.CmdBus.Register(&createcalendarevent.CreateCalendarEventCommand{},
    createcalendarevent.NewHandler(p.CalendarRepo, p.EventBus)); err != nil {
    return err
}
if err := p.CmdBus.Register(&updatecalendarevent.UpdateCalendarEventCommand{},
    updatecalendarevent.NewHandler(p.CalendarRepo, p.CalendarRepo, p.EventBus)); err != nil {
    return err
}
if err := p.CmdBus.Register(&deletecalendarevent.DeleteCalendarEventCommand{},
    deletecalendarevent.NewHandler(p.CalendarRepo, p.CalendarRepo, p.EventBus)); err != nil {
    return err
}
listCalendarEventsH := listcalendarevents.NewHandler(p.CalendarRepo)
if err := p.QryBus.Register(&listcalendarevents.ListCalendarEventsQuery{},
    adaptQueryHandler(listCalendarEventsH.Handle)); err != nil {
    return err
}
getCalendarEventH := getcalendarevent.NewHandler(p.CalendarRepo)
if err := p.QryBus.Register(&getcalendarevent.GetCalendarEventQuery{},
    adaptQueryHandler(getCalendarEventH.Handle)); err != nil {
    return err
}
```

- [ ] **Step 7: Build and verify**

```bash
cd api && go build ./...
```

Expected: exit 0.

- [ ] **Step 8: Start API and test endpoint**

```bash
cd api && make dev &
sleep 3
curl -s http://localhost:8081/health
```

Expected: `{"status":"ok"}`

- [ ] **Step 9: Commit**

```bash
git add api/cmd/api/main.go
git commit -m "feat(calendar): wire CalendarHandler, repository, commands, and queries in FX"
```

---

## Task 11: Frontend — Types and Service

**Files:**
- Create: `web-dashboard/src/types/calendar.types.ts`
- Create: `web-dashboard/src/services/calendar.service.ts`

- [ ] **Step 1: Create calendar.types.ts**

```typescript
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
  start_at: string
  end_at: string
  is_all_day: boolean
  recurrence_rule: string | null
  location: string | null
  source_domain: string | null
  source_id: string | null
  created_by: string
  created_at: string
}

export const EVENT_TYPE_COLORS: Record<EventType, string> = {
  class_session:        '#3b82f6',
  staff_meeting:        '#22c55e',
  admin_deadline:       '#f97316',
  payment_due:          '#ef4444',
  facilitator_schedule: '#a855f7',
  partner_meeting:      '#14b8a6',
}

export const EVENT_TYPE_LABELS: Record<EventType, string> = {
  class_session:        'Sesi Kelas',
  staff_meeting:        'Rapat Staff',
  admin_deadline:       'Deadline Admin',
  payment_due:          'Jatuh Tempo',
  facilitator_schedule: 'Jadwal Fasilitator',
  partner_meeting:      'Rapat Partner',
}

export interface CreateCalendarEventPayload {
  title: string
  description?: string
  event_type: EventType
  start_at: string
  end_at: string
  is_all_day: boolean
  recurrence_rule?: string
  location?: string
}
```

- [ ] **Step 2: Create calendar.service.ts**

```typescript
import { apiClient } from './api.client'
import type { CalendarEvent, CreateCalendarEventPayload } from '@/types/calendar.types'

interface ListCalendarEventsResult {
  data: CalendarEvent[]
}

export const calendarService = {
  listByMonth: (year: number, month: number): Promise<CalendarEvent[]> =>
    apiClient
      .get<ListCalendarEventsResult>(`/calendar/events?year=${year}&month=${month}`)
      .then(res => (res as ListCalendarEventsResult).data ?? []),

  getById: (id: string): Promise<CalendarEvent> =>
    apiClient.get<CalendarEvent>(`/calendar/events/${id}`),

  create: (data: CreateCalendarEventPayload): Promise<void> =>
    apiClient.post<void>('/calendar/events', data),

  update: (id: string, data: CreateCalendarEventPayload): Promise<void> =>
    apiClient.put<void>(`/calendar/events/${id}`, data),

  delete: (id: string): Promise<void> =>
    apiClient.delete(`/calendar/events/${id}`),
}
```

- [ ] **Step 3: Verify TypeScript**

```bash
cd web-dashboard && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add web-dashboard/src/types/calendar.types.ts web-dashboard/src/services/calendar.service.ts
git commit -m "feat(calendar): add CalendarEvent types and calendar service"
```

---

## Task 12: Frontend — EventDot, CalendarCell, CalendarGrid

**Files:**
- Create: `web-dashboard/src/pages/Calendar/EventDot.tsx`
- Create: `web-dashboard/src/pages/Calendar/CalendarCell.tsx`
- Create: `web-dashboard/src/pages/Calendar/CalendarGrid.tsx`

- [ ] **Step 1: Create EventDot.tsx**

```tsx
import type { CalendarEvent } from '@/types/calendar.types'
import { EVENT_TYPE_COLORS } from '@/types/calendar.types'

interface Props {
  event: CalendarEvent
}

export function EventDot({ event }: Props) {
  const color = EVENT_TYPE_COLORS[event.event_type] ?? '#999'
  return (
    <span
      title={event.title}
      style={{
        display: 'inline-block',
        width: 7,
        height: 7,
        borderRadius: '50%',
        backgroundColor: color,
        marginRight: 2,
        flexShrink: 0,
      }}
    />
  )
}
```

- [ ] **Step 2: Create CalendarCell.tsx**

```tsx
import type { CalendarEvent } from '@/types/calendar.types'
import { EventDot } from './EventDot'
import styles from './CalendarPage.module.css'

interface Props {
  day: number
  events: CalendarEvent[]
  isToday: boolean
  isSelected: boolean
  onClick: () => void
}

export function CalendarCell({ day, events, isToday, isSelected, onClick }: Props) {
  const className = isToday
    ? styles.cellToday
    : isSelected
    ? styles.cellSelected
    : styles.cell

  return (
    <div className={className} onClick={onClick}>
      <span className={styles.cellDay}>{day}</span>
      {events.length > 0 && (
        <div className={styles.cellDots}>
          {events.slice(0, 5).map(e => (
            <EventDot key={e.id} event={e} />
          ))}
          {events.length > 5 && (
            <span className={styles.cellMore}>+{events.length - 5}</span>
          )}
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 3: Create CalendarGrid.tsx**

```tsx
import type { CalendarEvent } from '@/types/calendar.types'
import { CalendarCell } from './CalendarCell'
import styles from './CalendarPage.module.css'

const DAYS = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']

interface Props {
  year: number
  month: number
  events: CalendarEvent[]
  selectedDate: Date | null
  onDayClick: (date: Date) => void
}

function getDaysInMonth(year: number, month: number) {
  return new Date(year, month + 1, 0).getDate()
}

function getFirstDayOfMonth(year: number, month: number) {
  return new Date(year, month, 1).getDay()
}

function groupEventsByDay(events: CalendarEvent[], year: number, month: number): Map<number, CalendarEvent[]> {
  const map = new Map<number, CalendarEvent[]>()
  for (const e of events) {
    const d = new Date(e.start_at)
    if (d.getFullYear() === year && d.getMonth() === month) {
      const day = d.getDate()
      if (!map.has(day)) map.set(day, [])
      map.get(day)!.push(e)
    }
  }
  return map
}

export function CalendarGrid({ year, month, events, selectedDate, onDayClick }: Props) {
  const today = new Date()
  const daysInMonth = getDaysInMonth(year, month)
  const firstDay = getFirstDayOfMonth(year, month)
  const eventsByDay = groupEventsByDay(events, year, month)

  const cells: (number | null)[] = [
    ...Array(firstDay).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => i + 1),
  ]

  return (
    <div className={styles.grid}>
      {DAYS.map(d => (
        <div key={d} className={styles.dayLabel}>{d}</div>
      ))}
      {cells.map((day, i) => {
        if (!day) return <div key={i} className={styles.cellEmpty} />
        const isToday = day === today.getDate() && month === today.getMonth() && year === today.getFullYear()
        const isSelected = selectedDate != null && day === selectedDate.getDate() && month === selectedDate.getMonth() && year === selectedDate.getFullYear()
        return (
          <CalendarCell
            key={i}
            day={day}
            events={eventsByDay.get(day) ?? []}
            isToday={isToday}
            isSelected={isSelected}
            onClick={() => onDayClick(new Date(year, month, day))}
          />
        )
      })}
    </div>
  )
}
```

- [ ] **Step 4: Verify TypeScript**

```bash
cd web-dashboard && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/pages/Calendar/EventDot.tsx web-dashboard/src/pages/Calendar/CalendarCell.tsx web-dashboard/src/pages/Calendar/CalendarGrid.tsx
git commit -m "feat(calendar): add EventDot, CalendarCell, CalendarGrid components"
```

---

## Task 13: Frontend — CalendarSidebar and EventFormModal

**Files:**
- Create: `web-dashboard/src/pages/Calendar/CalendarSidebar.tsx`
- Create: `web-dashboard/src/pages/Calendar/EventFormModal.tsx`

- [ ] **Step 1: Create CalendarSidebar.tsx**

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query'
import type { CalendarEvent } from '@/types/calendar.types'
import { EVENT_TYPE_COLORS, EVENT_TYPE_LABELS } from '@/types/calendar.types'
import { calendarService } from '@/services/calendar.service'
import styles from './CalendarPage.module.css'

const MONTHS = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember']
const DAYS_FULL = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu']

interface Props {
  selectedDate: Date
  events: CalendarEvent[]
  onEdit: (event: CalendarEvent) => void
  onClose: () => void
}

function formatTime(iso: string) {
  const d = new Date(iso)
  return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
}

export function CalendarSidebar({ selectedDate, events, onEdit, onClose }: Props) {
  const queryClient = useQueryClient()
  const deleteMutation = useMutation({
    mutationFn: calendarService.delete,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['calendar-events'] }),
  })

  const label = `${DAYS_FULL[selectedDate.getDay()]}, ${selectedDate.getDate()} ${MONTHS[selectedDate.getMonth()]}`

  return (
    <aside className={styles.sidebar}>
      <div className={styles.sidebarHeader}>
        <h3 className={styles.sidebarTitle}>{label}</h3>
        <button className={styles.closeBtn} onClick={onClose} aria-label="Tutup">×</button>
      </div>

      {events.length === 0 ? (
        <p className={styles.sidebarEmpty}>Tidak ada event</p>
      ) : (
        <ul className={styles.eventList}>
          {events.map(e => (
            <li key={e.id} className={styles.eventItem}>
              <span
                className={styles.eventTypeBar}
                style={{ backgroundColor: EVENT_TYPE_COLORS[e.event_type] }}
              />
              <div className={styles.eventBody}>
                <span className={styles.eventTitle}>{e.title}</span>
                <span className={styles.eventTime}>
                  {e.is_all_day ? 'Sepanjang hari' : `${formatTime(e.start_at)} – ${formatTime(e.end_at)}`}
                </span>
                <span className={styles.eventTypeLabel}>{EVENT_TYPE_LABELS[e.event_type]}</span>
              </div>
              {e.source_domain === null && (
                <div className={styles.eventActions}>
                  <button className={styles.actionBtn} onClick={() => onEdit(e)}>Edit</button>
                  <button
                    className={`${styles.actionBtn} ${styles.actionBtnDanger}`}
                    onClick={() => deleteMutation.mutate(e.id)}
                  >
                    Hapus
                  </button>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </aside>
  )
}
```

- [ ] **Step 2: Create EventFormModal.tsx**

```tsx
import { useState, useEffect } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import type { CalendarEvent, EventType, CreateCalendarEventPayload } from '@/types/calendar.types'
import { calendarService } from '@/services/calendar.service'
import styles from './CalendarPage.module.css'

const EVENT_TYPES: { value: EventType; label: string }[] = [
  { value: 'class_session',        label: 'Sesi Kelas' },
  { value: 'staff_meeting',        label: 'Rapat Staff' },
  { value: 'admin_deadline',       label: 'Deadline Admin' },
  { value: 'payment_due',          label: 'Jatuh Tempo' },
  { value: 'facilitator_schedule', label: 'Jadwal Fasilitator' },
  { value: 'partner_meeting',      label: 'Rapat Partner' },
]

interface Props {
  event: CalendarEvent | null
  defaultDate?: Date
  onClose: () => void
}

function toDatetimeLocal(iso: string) {
  return iso.slice(0, 16)
}

function toISO(local: string) {
  return new Date(local).toISOString()
}

export function EventFormModal({ event, defaultDate, onClose }: Props) {
  const queryClient = useQueryClient()
  const isEdit = event !== null

  const defaultStart = defaultDate
    ? new Date(defaultDate.getFullYear(), defaultDate.getMonth(), defaultDate.getDate(), 9, 0).toISOString()
    : new Date().toISOString()
  const defaultEnd = defaultDate
    ? new Date(defaultDate.getFullYear(), defaultDate.getMonth(), defaultDate.getDate(), 10, 0).toISOString()
    : new Date().toISOString()

  const [title, setTitle] = useState(event?.title ?? '')
  const [description, setDescription] = useState(event?.description ?? '')
  const [eventType, setEventType] = useState<EventType>(event?.event_type ?? 'staff_meeting')
  const [startAt, setStartAt] = useState(toDatetimeLocal(event?.start_at ?? defaultStart))
  const [endAt, setEndAt] = useState(toDatetimeLocal(event?.end_at ?? defaultEnd))
  const [isAllDay, setIsAllDay] = useState(event?.is_all_day ?? false)
  const [location, setLocation] = useState(event?.location ?? '')
  const [error, setError] = useState('')

  useEffect(() => {
    if (event) {
      setTitle(event.title)
      setDescription(event.description ?? '')
      setEventType(event.event_type)
      setStartAt(toDatetimeLocal(event.start_at))
      setEndAt(toDatetimeLocal(event.end_at))
      setIsAllDay(event.is_all_day)
      setLocation(event.location ?? '')
    }
  }, [event])

  const mutation = useMutation({
    mutationFn: (payload: CreateCalendarEventPayload) =>
      isEdit ? calendarService.update(event!.id, payload) : calendarService.create(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['calendar-events'] })
      onClose()
    },
    onError: () => setError('Gagal menyimpan event. Coba lagi.'),
  })

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!title.trim()) { setError('Judul wajib diisi'); return }
    mutation.mutate({
      title: title.trim(),
      description: description || undefined,
      event_type: eventType,
      start_at: toISO(startAt),
      end_at: toISO(endAt),
      is_all_day: isAllDay,
      location: location || undefined,
    })
  }

  return (
    <div className={styles.modalOverlay} onClick={onClose}>
      <div className={styles.modal} onClick={e => e.stopPropagation()}>
        <div className={styles.modalHeader}>
          <h3>{isEdit ? 'Edit Event' : 'Event Baru'}</h3>
          <button className={styles.closeBtn} onClick={onClose}>×</button>
        </div>
        <form className={styles.modalForm} onSubmit={handleSubmit}>
          <label>
            Judul *
            <input value={title} onChange={e => setTitle(e.target.value)} required />
          </label>
          <label>
            Tipe Event *
            <select value={eventType} onChange={e => setEventType(e.target.value as EventType)}>
              {EVENT_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
            </select>
          </label>
          <label>
            <input type="checkbox" checked={isAllDay} onChange={e => setIsAllDay(e.target.checked)} />
            &nbsp;Sepanjang hari
          </label>
          {!isAllDay && (
            <>
              <label>
                Mulai *
                <input type="datetime-local" value={startAt} onChange={e => setStartAt(e.target.value)} required />
              </label>
              <label>
                Selesai *
                <input type="datetime-local" value={endAt} onChange={e => setEndAt(e.target.value)} required />
              </label>
            </>
          )}
          <label>
            Lokasi
            <input value={location} onChange={e => setLocation(e.target.value)} placeholder="Ruangan / link meeting" />
          </label>
          <label>
            Deskripsi
            <textarea value={description} onChange={e => setDescription(e.target.value)} rows={3} />
          </label>
          {error && <p className={styles.formError}>{error}</p>}
          <div className={styles.modalActions}>
            <button type="button" className={styles.btnSecondary} onClick={onClose}>Batal</button>
            <button type="submit" className={styles.btnPrimary} disabled={mutation.isPending}>
              {mutation.isPending ? 'Menyimpan...' : 'Simpan'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Verify TypeScript**

```bash
cd web-dashboard && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add web-dashboard/src/pages/Calendar/CalendarSidebar.tsx web-dashboard/src/pages/Calendar/EventFormModal.tsx
git commit -m "feat(calendar): add CalendarSidebar and EventFormModal components"
```

---

## Task 14: Frontend — Refactor CalendarPage + CSS

**Files:**
- Modify: `web-dashboard/src/pages/Calendar/CalendarPage.tsx`
- Modify: `web-dashboard/src/pages/Calendar/CalendarPage.module.css`

- [ ] **Step 1: Rewrite CalendarPage.tsx**

```tsx
import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { ChevronLeft, ChevronRight, Plus } from 'lucide-react'
import type { CalendarEvent } from '@/types/calendar.types'
import { calendarService } from '@/services/calendar.service'
import { CalendarGrid } from './CalendarGrid'
import { CalendarSidebar } from './CalendarSidebar'
import { EventFormModal } from './EventFormModal'
import styles from './CalendarPage.module.css'

const MONTHS = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember']

export default function CalendarPage() {
  const today = new Date()
  const [viewYear, setViewYear] = useState(today.getFullYear())
  const [viewMonth, setViewMonth] = useState(today.getMonth())
  const [selectedDate, setSelectedDate] = useState<Date | null>(null)
  const [modalEvent, setModalEvent] = useState<CalendarEvent | null | undefined>(undefined)

  const { data: events = [] } = useQuery({
    queryKey: ['calendar-events', viewYear, viewMonth + 1],
    queryFn: () => calendarService.listByMonth(viewYear, viewMonth + 1),
  })

  const prevMonth = () => {
    if (viewMonth === 0) { setViewMonth(11); setViewYear(y => y - 1) }
    else setViewMonth(m => m - 1)
    setSelectedDate(null)
  }

  const nextMonth = () => {
    if (viewMonth === 11) { setViewMonth(0); setViewYear(y => y + 1) }
    else setViewMonth(m => m + 1)
    setSelectedDate(null)
  }

  const selectedDayEvents: CalendarEvent[] = selectedDate
    ? events.filter(e => {
        const d = new Date(e.start_at)
        return d.getDate() === selectedDate.getDate() &&
               d.getMonth() === selectedDate.getMonth() &&
               d.getFullYear() === selectedDate.getFullYear()
      })
    : []

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <div className={styles.nav}>
          <button className={styles.navBtn} onClick={prevMonth}><ChevronLeft size={18} /></button>
          <h2 className={styles.title}>{MONTHS[viewMonth]} {viewYear}</h2>
          <button className={styles.navBtn} onClick={nextMonth}><ChevronRight size={18} /></button>
        </div>
        <button className={styles.btnAdd} onClick={() => setModalEvent(null)}>
          <Plus size={16} /> Event
        </button>
      </div>

      <div className={styles.body}>
        <div className={styles.gridWrap}>
          <CalendarGrid
            year={viewYear}
            month={viewMonth}
            events={events}
            selectedDate={selectedDate}
            onDayClick={setSelectedDate}
          />
        </div>

        {selectedDate && (
          <CalendarSidebar
            selectedDate={selectedDate}
            events={selectedDayEvents}
            onEdit={e => setModalEvent(e)}
            onClose={() => setSelectedDate(null)}
          />
        )}
      </div>

      {modalEvent !== undefined && (
        <EventFormModal
          event={modalEvent}
          defaultDate={selectedDate ?? undefined}
          onClose={() => setModalEvent(undefined)}
        />
      )}
    </div>
  )
}
```

- [ ] **Step 2: Rewrite CalendarPage.module.css**

```css
.page {
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  height: 100%;
}

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.nav {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.title {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0;
  min-width: 160px;
  text-align: center;
}

.navBtn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  background: transparent;
  color: var(--color-text-secondary);
  cursor: pointer;
  transition: background 0.15s;
}

.navBtn:hover {
  background: var(--color-bg-hover, #f5f5f5);
}

.btnAdd {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.4rem 0.875rem;
  background: var(--color-primary, #3b82f6);
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: opacity 0.15s;
}

.btnAdd:hover {
  opacity: 0.88;
}

.body {
  display: flex;
  gap: 1.25rem;
  flex: 1;
  min-height: 0;
}

.gridWrap {
  flex: 1;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 10px;
  padding: 1rem;
  overflow: auto;
}

/* Grid */
.grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 3px;
}

.dayLabel {
  text-align: center;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--color-text-secondary);
  padding: 0.4rem 0;
}

.cell,
.cellEmpty,
.cellToday,
.cellSelected {
  min-height: 72px;
  padding: 0.375rem 0.375rem 0.25rem;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.cell {
  color: var(--color-text-primary);
  transition: background 0.1s;
}

.cell:hover {
  background: var(--color-bg-hover, #f0f0f0);
}

.cellEmpty {
  color: transparent;
  cursor: default;
}

.cellToday {
  background: var(--color-primary, #3b82f6);
  color: #fff;
}

.cellSelected {
  background: var(--color-bg-selected, #eff6ff);
  color: var(--color-text-primary);
  border: 1.5px solid var(--color-primary, #3b82f6);
}

.cellDay {
  font-size: 0.8rem;
  font-weight: 500;
  line-height: 1;
}

.cellDots {
  display: flex;
  flex-wrap: wrap;
  gap: 2px;
  align-items: center;
}

.cellMore {
  font-size: 0.65rem;
  color: var(--color-text-secondary);
}

/* Sidebar */
.sidebar {
  width: 300px;
  flex-shrink: 0;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: 10px;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  overflow-y: auto;
}

.sidebarHeader {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.sidebarTitle {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0;
}

.closeBtn {
  background: transparent;
  border: none;
  font-size: 1.25rem;
  cursor: pointer;
  color: var(--color-text-secondary);
  line-height: 1;
  padding: 0 4px;
}

.sidebarEmpty {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
}

.eventList {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.eventItem {
  display: flex;
  gap: 0.5rem;
  align-items: flex-start;
}

.eventTypeBar {
  width: 3px;
  border-radius: 2px;
  flex-shrink: 0;
  align-self: stretch;
}

.eventBody {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.eventTitle {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-primary);
}

.eventTime {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.eventTypeLabel {
  font-size: 0.7rem;
  color: var(--color-text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.eventActions {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.actionBtn {
  font-size: 0.75rem;
  padding: 2px 6px;
  border: 1px solid var(--color-border);
  background: transparent;
  border-radius: 4px;
  cursor: pointer;
  color: var(--color-text-primary);
}

.actionBtnDanger {
  color: #ef4444;
  border-color: #ef4444;
}

/* Modal */
.modalOverlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.modal {
  background: var(--color-surface);
  border-radius: 10px;
  padding: 1.5rem;
  width: 440px;
  max-width: 95vw;
  max-height: 90vh;
  overflow-y: auto;
}

.modalHeader {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.25rem;
}

.modalHeader h3 {
  font-size: 1rem;
  font-weight: 600;
  margin: 0;
}

.modalForm {
  display: flex;
  flex-direction: column;
  gap: 0.875rem;
}

.modalForm label {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  font-size: 0.875rem;
  color: var(--color-text-secondary);
}

.modalForm input,
.modalForm select,
.modalForm textarea {
  padding: 0.45rem 0.625rem;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  font-size: 0.875rem;
  background: var(--color-bg);
  color: var(--color-text-primary);
}

.formError {
  color: #ef4444;
  font-size: 0.8rem;
  margin: 0;
}

.modalActions {
  display: flex;
  justify-content: flex-end;
  gap: 0.625rem;
  margin-top: 0.5rem;
}

.btnPrimary {
  padding: 0.45rem 1rem;
  background: var(--color-primary, #3b82f6);
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
}

.btnPrimary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btnSecondary {
  padding: 0.45rem 1rem;
  background: transparent;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  font-size: 0.875rem;
  cursor: pointer;
  color: var(--color-text-primary);
}
```

- [ ] **Step 3: Verify TypeScript**

```bash
cd web-dashboard && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add web-dashboard/src/pages/Calendar/CalendarPage.tsx web-dashboard/src/pages/Calendar/CalendarPage.module.css
git commit -m "feat(calendar): refactor CalendarPage to full-width grid with sidebar and event CRUD"
```

---

## Task 15: Frontend — Unit Tests

**Files:**
- Create: `web-dashboard/src/pages/Calendar/__tests__/CalendarPage.test.tsx`

- [ ] **Step 1: Write failing tests**

```tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import type { CalendarEvent } from '@/types/calendar.types'
import { EventDot } from '../EventDot'
import { CalendarCell } from '../CalendarCell'
import { CalendarGrid } from '../CalendarGrid'

const makeEvent = (overrides: Partial<CalendarEvent> = {}): CalendarEvent => ({
  id: '1',
  title: 'Test Event',
  description: null,
  event_type: 'staff_meeting',
  start_at: '2026-05-07T09:00:00Z',
  end_at: '2026-05-07T10:00:00Z',
  is_all_day: false,
  recurrence_rule: null,
  location: null,
  source_domain: null,
  source_id: null,
  created_by: 'user-1',
  created_at: '2026-05-01T00:00:00Z',
  ...overrides,
})

describe('EventDot', () => {
  it('renders a span with title as tooltip', () => {
    const event = makeEvent({ title: 'Rapat Mingguan' })
    render(<EventDot event={event} />)
    const dot = screen.getByTitle('Rapat Mingguan')
    expect(dot).toBeTruthy()
  })

  it('uses correct color for class_session', () => {
    const event = makeEvent({ event_type: 'class_session' })
    render(<EventDot event={event} />)
    const dot = screen.getByTitle('Test Event')
    expect(dot.getAttribute('style')).toContain('#3b82f6')
  })

  it('uses correct color for payment_due', () => {
    const event = makeEvent({ event_type: 'payment_due' })
    render(<EventDot event={event} />)
    expect(screen.getByTitle('Test Event').getAttribute('style')).toContain('#ef4444')
  })
})

describe('CalendarCell', () => {
  it('renders day number', () => {
    render(<CalendarCell day={7} events={[]} isToday={false} isSelected={false} onClick={() => {}} />)
    expect(screen.getByText('7')).toBeTruthy()
  })

  it('renders dots for events', () => {
    const events = [makeEvent({ title: 'E1' }), makeEvent({ id: '2', title: 'E2' })]
    render(<CalendarCell day={7} events={events} isToday={false} isSelected={false} onClick={() => {}} />)
    expect(screen.getByTitle('E1')).toBeTruthy()
    expect(screen.getByTitle('E2')).toBeTruthy()
  })

  it('shows +N more when events exceed 5', () => {
    const events = Array.from({ length: 7 }, (_, i) =>
      makeEvent({ id: String(i), title: `E${i}` })
    )
    render(<CalendarCell day={1} events={events} isToday={false} isSelected={false} onClick={() => {}} />)
    expect(screen.getByText('+2')).toBeTruthy()
  })

  it('calls onClick when clicked', () => {
    let clicked = false
    render(<CalendarCell day={5} events={[]} isToday={false} isSelected={false} onClick={() => { clicked = true }} />)
    fireEvent.click(screen.getByText('5'))
    expect(clicked).toBe(true)
  })
})

describe('CalendarGrid', () => {
  it('renders 7 day labels', () => {
    render(
      <CalendarGrid
        year={2026} month={4}
        events={[]}
        selectedDate={null}
        onDayClick={() => {}}
      />
    )
    expect(screen.getByText('Min')).toBeTruthy()
    expect(screen.getByText('Sab')).toBeTruthy()
  })

  it('renders correct number of day cells for May 2026 (31 days)', () => {
    render(
      <CalendarGrid
        year={2026} month={4}
        events={[]}
        selectedDate={null}
        onDayClick={() => {}}
      />
    )
    expect(screen.getByText('31')).toBeTruthy()
    expect(screen.queryByText('32')).toBeNull()
  })

  it('passes events to the correct day cell', () => {
    const event = makeEvent({ title: 'Kelas Python', start_at: '2026-05-07T09:00:00Z', end_at: '2026-05-07T10:00:00Z' })
    render(
      <CalendarGrid
        year={2026} month={4}
        events={[event]}
        selectedDate={null}
        onDayClick={() => {}}
      />
    )
    expect(screen.getByTitle('Kelas Python')).toBeTruthy()
  })

  it('calls onDayClick with correct date', () => {
    let clicked: Date | null = null
    render(
      <CalendarGrid
        year={2026} month={4}
        events={[]}
        selectedDate={null}
        onDayClick={d => { clicked = d }}
      />
    )
    fireEvent.click(screen.getByText('15'))
    expect(clicked).not.toBeNull()
    expect((clicked as unknown as Date).getDate()).toBe(15)
  })
})
```

- [ ] **Step 2: Run tests to verify they fail (components not wired)**

```bash
cd web-dashboard && npx vitest run src/pages/Calendar/__tests__/CalendarPage.test.tsx
```

Expected: some tests pass, some may fail if CSS modules or imports need adjustment.

- [ ] **Step 3: Fix any import issues and run again**

```bash
cd web-dashboard && npx vitest run src/pages/Calendar/__tests__/CalendarPage.test.tsx
```

Expected: all tests pass.

- [ ] **Step 4: Run full test suite to verify no regressions**

```bash
cd web-dashboard && npx vitest run
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/pages/Calendar/__tests__/CalendarPage.test.tsx
git commit -m "test(calendar): add unit tests for EventDot, CalendarCell, CalendarGrid"
```

---

## Task 16: End-to-End Smoke Test

- [ ] **Step 1: Start API**

```bash
cd api && make dev
```

Expected: API starts on port 8081.

- [ ] **Step 2: Start frontend**

```bash
cd web-dashboard && npm run dev
```

Expected: Frontend starts on port 3001.

- [ ] **Step 3: Login and navigate to /calendar**

Open http://localhost:3001, login as any internal staff user, navigate to Calendar page.

Expected:
- Full-width monthly grid renders
- Current month shown
- Navigation arrows work (prev/next month)
- "+ Event" button visible

- [ ] **Step 4: Create a manual event**

Click "+ Event", fill form (title="Test Meeting", type=Staff Meeting, start/end time), click Simpan.

Expected:
- Modal closes
- Event dot appears on the correct day in the grid
- Click the day → sidebar shows the event

- [ ] **Step 5: Edit the event**

In sidebar, click Edit on the event.

Expected:
- Modal opens pre-filled with existing data
- Change title, click Simpan
- Updated title appears in sidebar

- [ ] **Step 6: Delete the event**

In sidebar, click Hapus.

Expected: event removed from grid and sidebar.

- [ ] **Step 7: Verify API endpoints directly**

```bash
TOKEN="<paste JWT from browser localStorage: vernonedu_token>"
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8081/api/v1/calendar/events?month=5&year=2026"
```

Expected: `{"data":[...]}` JSON response.

- [ ] **Step 8: Final commit**

```bash
git add .
git commit -m "chore(calendar): complete calendar domain implementation smoke test"
```
