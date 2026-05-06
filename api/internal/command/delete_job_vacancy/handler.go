package delete_job_vacancy

import (
	"context"

	"github.com/rs/zerolog/log"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/job_vacancy"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	repo     job_vacancy.WriteRepository
	eventBus eventbus.EventBus
}

func NewHandler(repo job_vacancy.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{repo: repo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteJobVacancyCommand)
	if !ok {
		return ErrInvalidCommand
	}
	if err := h.repo.Delete(ctx, c.ID); err != nil {
		log.Error().Err(err).Msg("failed to delete job vacancy")
		return err
	}
	log.Info().Str("vacancy_id", c.ID.String()).Msg("job vacancy deleted")
	return nil
}
