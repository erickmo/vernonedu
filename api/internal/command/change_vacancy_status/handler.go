package change_vacancy_status

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/job_vacancy"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo job_vacancy.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo job_vacancy.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*ChangeVacancyStatusCommand)
	if !ok {
		return ErrInvalidCommand
	}
	v, err := h.writeRepo.GetByIDForWrite(ctx, c.ID)
	if err != nil {
		return err
	}
	if !v.CanTransitionTo(c.NewStatus) {
		return ErrInvalidStatusTransition
	}
	oldStatus := v.Status
	v.Status = c.NewStatus
	v.UpdatedAt = time.Now()
	if err := h.writeRepo.Update(ctx, v); err != nil {
		log.Error().Err(err).Msg("failed to change job vacancy status")
		return err
	}
	event := &job_vacancy.JobVacancyStatusChangedEvent{
		EventType: "JobVacancyStatusChanged",
		VacancyID: v.ID,
		OldStatus: oldStatus,
		NewStatus: c.NewStatus,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish JobVacancyStatusChanged event")
	}
	log.Info().Str("vacancy_id", v.ID.String()).Str("status", c.NewStatus).Msg("job vacancy status changed")
	return nil
}
