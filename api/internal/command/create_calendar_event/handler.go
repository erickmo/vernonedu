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
