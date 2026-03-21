package delete_holiday

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo settings.HolidayWriteRepository
}

func NewHandler(writeRepo settings.HolidayWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteHolidayCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.writeRepo.Delete(ctx, c.ID); err != nil {
		log.Error().Err(err).Str("id", c.ID.String()).Msg("failed to delete holiday")
		return err
	}

	log.Info().Str("id", c.ID.String()).Msg("holiday deleted")
	return nil
}
