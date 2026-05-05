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
	Data []*CalendarEventReadModel `json:"data"`
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

func (h *Handler) Handle(ctx context.Context, query any) (any, error) {
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

// suppress unused import
var _ = uuid.Nil
