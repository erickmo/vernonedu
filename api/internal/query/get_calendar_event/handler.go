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
