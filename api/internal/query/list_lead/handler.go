package list_lead

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadReadModel struct {
	ID        uuid.UUID  `json:"id"`
	Name      string     `json:"name"`
	Email     string     `json:"email"`
	Phone     string     `json:"phone"`
	Interest  string     `json:"interest"`
	Source    string     `json:"source"`
	Notes     string     `json:"notes"`
	Status    string     `json:"status"`
	PicID     *uuid.UUID `json:"pic_id"`
	CreatedAt int64      `json:"created_at"`
	UpdatedAt int64      `json:"updated_at"`
}

type ListResult struct {
	Data   []*LeadReadModel `json:"data"`
	Total  int              `json:"total"`
	Offset int              `json:"offset"`
	Limit  int              `json:"limit"`
}

type Handler struct {
	leadReadRepo lead.ReadRepository
}

func NewHandler(leadReadRepo lead.ReadRepository) *Handler {
	return &Handler{
		leadReadRepo: leadReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListLeadQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	leads, total, err := h.leadReadRepo.List(ctx, q.Offset, q.Limit, q.Status, q.Source, q.Interest)
	if err != nil {
		log.Error().Err(err).Msg("failed to list leads")
		return nil, err
	}

	readModels := make([]*LeadReadModel, len(leads))
	for i, l := range leads {
		readModels[i] = &LeadReadModel{
			ID:        l.ID,
			Name:      l.Name,
			Email:     l.Email,
			Phone:     l.Phone,
			Interest:  l.Interest,
			Source:    l.Source,
			Notes:     l.Notes,
			Status:    l.Status,
			PicID:     l.PicID,
			CreatedAt: l.CreatedAt.Unix(),
			UpdatedAt: l.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
