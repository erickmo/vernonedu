package create_holiday

import (
	"context"
	"time"

	"github.com/google/uuid"
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
	c, ok := cmd.(*CreateHolidayCommand)
	if !ok {
		return ErrInvalidCommand
	}

	date, err := time.Parse("2006-01-02", c.Date)
	if err != nil {
		return ErrInvalidDate
	}

	holiday := &settings.Holiday{
		ID:        uuid.New(),
		Date:      date,
		Name:      c.Name,
		CreatedAt: time.Now(),
	}

	if err := h.writeRepo.Save(ctx, holiday); err != nil {
		log.Error().Err(err).Msg("failed to create holiday")
		return err
	}

	log.Info().Str("date", c.Date).Str("name", c.Name).Msg("holiday created")
	return nil
}
