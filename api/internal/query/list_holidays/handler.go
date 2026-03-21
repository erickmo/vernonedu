package list_holidays

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
)

// HolidayReadModel is the response shape for a holiday.
type HolidayReadModel struct {
	ID        uuid.UUID `json:"id"`
	Date      string    `json:"date"` // "YYYY-MM-DD"
	Name      string    `json:"name"`
	CreatedAt int64     `json:"created_at"`
}

type Handler struct {
	readRepo settings.HolidayReadRepository
}

func NewHandler(readRepo settings.HolidayReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListHolidaysQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	holidays, err := h.readRepo.ListByYear(ctx, q.Year)
	if err != nil {
		log.Error().Err(err).Int("year", q.Year).Msg("failed to list holidays")
		return nil, err
	}

	readModels := make([]*HolidayReadModel, len(holidays))
	for i, hol := range holidays {
		readModels[i] = &HolidayReadModel{
			ID:        hol.ID,
			Date:      hol.Date.Format("2006-01-02"),
			Name:      hol.Name,
			CreatedAt: hol.CreatedAt.Unix(),
		}
	}

	return readModels, nil
}
