package list_pr

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
)

type ListPrQuery struct {
	Offset int
	Limit  int
	Status string
	Type   string
}

type PrReadModel struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Type        string `json:"type"`
	ScheduledAt int64  `json:"scheduled_at"`
	MediaVenue  string `json:"media_venue"`
	PicName     string `json:"pic_name"`
	Status      string `json:"status"`
	Notes       string `json:"notes"`
}

type ListPrResult struct {
	Data   []*PrReadModel `json:"data"`
	Total  int            `json:"total"`
	Offset int            `json:"offset"`
	Limit  int            `json:"limit"`
}

type Handler struct {
	readRepo marketing.ReadRepository
}

func NewHandler(readRepo marketing.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListPrQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	prs, total, err := h.readRepo.ListPr(ctx, q.Offset, q.Limit, q.Status, q.Type)
	if err != nil {
		log.Error().Err(err).Msg("failed to list pr schedules")
		return nil, err
	}

	readModels := make([]*PrReadModel, len(prs))
	for i, p := range prs {
		readModels[i] = &PrReadModel{
			ID:          p.ID.String(),
			Title:       p.Title,
			Type:        p.Type,
			ScheduledAt: p.ScheduledAt.Unix(),
			MediaVenue:  p.MediaVenue,
			PicName:     p.PicName,
			Status:      p.Status,
			Notes:       p.Notes,
		}
	}

	return &ListPrResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
